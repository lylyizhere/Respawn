'use strict';

const http = require('node:http');
const { createHash } = require('node:crypto');

const PAGE_SIZE = 20;
const MAX_PAGE = 250;
const GENRES = new Set(['4', '5', '10', '12', '14', '15', '31', '32']);
const ORDERINGS = Object.freeze({
  rating: 'rating desc',
  released: 'first_release_date desc',
  aggregated_rating: 'aggregated_rating desc',
  name: 'name asc',
});

class ProxyError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function buildIgdbQuery({ search = '', genre = '', ordering = 'rating', page = '1' }) {
  const parsedPage = Number(page);
  if (!Number.isInteger(parsedPage) || parsedPage < 1 || parsedPage > MAX_PAGE) {
    throw new ProxyError(400, `A página deve estar entre 1 e ${MAX_PAGE}.`);
  }
  if (genre && !GENRES.has(genre)) {
    throw new ProxyError(400, 'O gênero informado não é válido.');
  }
  if (!Object.hasOwn(ORDERINGS, ordering)) {
    throw new ProxyError(400, 'A ordenação informada não é válida.');
  }

  const normalizedSearch = search.trim();
  if (normalizedSearch.length > 100 || /[\u0000-\u001f\u007f]/.test(normalizedSearch)) {
    throw new ProxyError(400, 'A busca deve ter até 100 caracteres válidos.');
  }

  const conditions = ['version_parent = null'];
  if (genre) conditions.push(`genres = ${genre}`);

  const statements = [
    'fields id,name,summary,cover.url,artworks.url,screenshots.url,rating,aggregated_rating,first_release_date,genres.name,platforms.name;',
  ];
  if (normalizedSearch) {
    const escapedSearch = normalizedSearch
      .replace(/\\/g, '\\\\')
      .replace(/"/g, '\\"');
    statements.push(`search "${escapedSearch}";`);
  }
  statements.push(
    `where ${conditions.join(' & ')};`,
    `sort ${ORDERINGS[ordering]};`,
    `limit ${PAGE_SIZE + 1};`,
    `offset ${(parsedPage - 1) * PAGE_SIZE};`,
  );
  return statements.join('\n');
}

function normalizeGame(game) {
  const coverUrl = typeof game.cover?.url === 'string' ? game.cover.url : '';
  const coverImage = toIgdbImageUrl(coverUrl, 't_cover_big');
  const artworkUrl = game.artworks?.find((image) => typeof image?.url === 'string')
    ?.url;
  const screenshotUrl = game.screenshots?.find(
    (image) => typeof image?.url === 'string',
  )?.url;
  const backgroundImage = toIgdbImageUrl(
    artworkUrl || screenshotUrl || coverUrl,
    't_1080p',
  );
  const releaseDate = Number.isFinite(game.first_release_date)
    ? new Date(game.first_release_date * 1000).toISOString().slice(0, 10)
    : 'Sem data';

  return {
    id: Number.isInteger(game.id) ? game.id : 0,
    name: typeof game.name === 'string' && game.name.trim()
      ? game.name
      : 'Sem título',
    background_image: backgroundImage,
    cover_image: coverImage,
    summary: typeof game.summary === 'string' ? game.summary : '',
    rating: typeof game.rating === 'number' ? game.rating : 0,
    aggregated_rating: typeof game.aggregated_rating === 'number'
      ? game.aggregated_rating
      : 0,
    released: releaseDate,
    genres: Array.isArray(game.genres)
      ? game.genres
          .filter((genre) => typeof genre?.name === 'string')
          .map(({ name }) => ({ name }))
      : [],
    platforms: Array.isArray(game.platforms)
      ? game.platforms
          .filter((platform) => typeof platform?.name === 'string')
          .map(({ name }) => ({ platform: { name } }))
      : [],
  };
}

function toIgdbImageUrl(url, size) {
  if (typeof url !== 'string' || !url) return '';
  const secureUrl = url.startsWith('//') ? `https:${url}` : url;
  return secureUrl.replace(/\/t_[^/]+\//, `/${size}/`);
}

class TwitchTokenProvider {
  constructor({ clientId, clientSecret, fetchImpl = fetch, now = Date.now }) {
    this.clientId = clientId;
    this.clientSecret = clientSecret;
    this.fetchImpl = fetchImpl;
    this.now = now;
    this.accessToken = '';
    this.expiresAt = 0;
    this.pendingRequest = null;
  }

  async getToken({ forceRefresh = false } = {}) {
    if (!forceRefresh && this.accessToken && this.now() < this.expiresAt - 60_000) {
      return this.accessToken;
    }
    if (this.pendingRequest) return this.pendingRequest;

    this.pendingRequest = this.fetchToken();
    try {
      return await this.pendingRequest;
    } finally {
      this.pendingRequest = null;
    }
  }

  async fetchToken() {
    if (!this.clientId || !this.clientSecret) {
      throw new ProxyError(
        503,
        'Credenciais do servidor ausentes. Configure TWITCH_CLIENT_ID e TWITCH_CLIENT_SECRET.',
      );
    }

    const tokenUrl = new URL('https://id.twitch.tv/oauth2/token');
    tokenUrl.search = new URLSearchParams({
      client_id: this.clientId,
      client_secret: this.clientSecret,
      grant_type: 'client_credentials',
    });
    const response = await this.fetchImpl(tokenUrl, {
      method: 'POST',
      signal: AbortSignal.timeout(20_000),
    });
    if (!response.ok) {
      throw new ProxyError(502, 'Não foi possível autenticar o servidor na Twitch.');
    }

    let tokenData;
    try {
      tokenData = await response.json();
    } catch {
      throw new ProxyError(502, 'A Twitch retornou uma resposta de autenticação inválida.');
    }
    if (
      typeof tokenData.access_token !== 'string' ||
      !Number.isFinite(tokenData.expires_in)
    ) {
      throw new ProxyError(502, 'A Twitch retornou uma resposta de autenticação inválida.');
    }

    this.accessToken = tokenData.access_token;
    this.expiresAt = this.now() + tokenData.expires_in * 1000;
    return this.accessToken;
  }
}

function createIgdbProxy({
  clientId = process.env.TWITCH_CLIENT_ID,
  clientSecret = process.env.TWITCH_CLIENT_SECRET,
  fetchImpl = fetch,
  now = Date.now,
} = {}) {
  const tokenProvider = new TwitchTokenProvider({
    clientId,
    clientSecret,
    fetchImpl,
    now,
  });

  return async (params) => {
    const query = buildIgdbQuery(params);
    const sendQuery = (token) => fetchImpl('https://api.igdb.com/v4/games', {
      method: 'POST',
      headers: {
        'Client-ID': clientId,
        Authorization: `Bearer ${token}`,
        'Content-Type': 'text/plain',
      },
      body: query,
      signal: AbortSignal.timeout(20_000),
    });

    let response = await sendQuery(await tokenProvider.getToken());
    if (response.status === 401) {
      response = await sendQuery(await tokenProvider.getToken({ forceRefresh: true }));
    }
    if (!response.ok) {
      throw new ProxyError(
        response.status === 429 ? 503 : 502,
        response.status === 429
          ? 'A IGDB atingiu o limite de consultas. Tente novamente em instantes.'
          : `A IGDB respondeu com o código ${response.status}.`,
      );
    }

    let games;
    try {
      games = await response.json();
    } catch {
      throw new ProxyError(502, 'A IGDB retornou uma resposta inválida.');
    }
    if (!Array.isArray(games)) {
      throw new ProxyError(502, 'A IGDB retornou uma resposta inválida.');
    }

    return {
      games: games.slice(0, PAGE_SIZE).map(normalizeGame),
      hasNextPage: games.length > PAGE_SIZE,
    };
  };
}

function createSummaryTranslator({
  url = process.env.LIBRETRANSLATE_URL || 'http://localhost:5000',
  apiKey = process.env.LIBRETRANSLATE_API_KEY,
  fetchImpl = fetch,
} = {}) {
  return async (text) => {
    let endpoint;
    try {
      endpoint = new URL(url);
    } catch {
      throw new ProxyError(503, 'O endereço do LibreTranslate não é válido.');
    }
    if (!['http:', 'https:'].includes(endpoint.protocol)) {
      throw new ProxyError(
        503,
        'O endereço do LibreTranslate deve usar HTTP ou HTTPS.',
      );
    }
    endpoint.pathname = `${endpoint.pathname.replace(/\/+$/, '')}/translate`;

    let response;
    try {
      response = await fetchImpl(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          q: text,
          source: 'auto',
          target: 'pt-BR',
          format: 'text',
          ...(apiKey ? { api_key: apiKey } : {}),
        }),
        signal: AbortSignal.timeout(25_000),
      });
    } catch (error) {
      if (error?.name === 'TimeoutError' || error?.name === 'AbortError') {
        throw new ProxyError(504, 'A tradução demorou demais. Tente novamente.');
      }
      throw new ProxyError(502, 'Não foi possível conectar ao LibreTranslate.');
    }
    if (!response.ok) {
      throw new ProxyError(
        response.status === 429 ? 503 : 502,
        response.status === 429
          ? 'O limite do LibreTranslate foi atingido. Tente novamente em instantes.'
          : `O LibreTranslate respondeu com o código ${response.status}.`,
      );
    }

    let result;
    try {
      result = await response.json();
    } catch {
      throw new ProxyError(502, 'O LibreTranslate retornou uma resposta inválida.');
    }
    if (typeof result.translatedText !== 'string' || !result.translatedText.trim()) {
      throw new ProxyError(502, 'O LibreTranslate não retornou o texto traduzido.');
    }
    return result.translatedText.trim();
  };
}

function createServer(options = {}) {
  const proxyGames = createIgdbProxy(options);
  const translateSummary = createSummaryTranslator(options);
  const translations = new Map();
  const allowedOrigins = (options.allowedOrigin ?? process.env.ALLOWED_ORIGIN ?? '*')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  const trustProxy = options.trustProxy ?? process.env.TRUST_PROXY === 'true';
  const requestsByIp = new Map();
  const rateLimit = 120;
  const rateWindowMs = 60_000;
  let lastRateLimitCleanup = 0;

  return http.createServer(async (request, response) => {
    const origin = request.headers.origin;
    const originAllowed = allowedOrigins.includes('*') ||
      (origin && allowedOrigins.includes(origin));
    if (origin && !originAllowed) {
      response.writeHead(403);
      response.end();
      return;
    }
    if (origin) {
      response.setHeader(
        'Access-Control-Allow-Origin',
        allowedOrigins.includes('*') ? '*' : origin,
      );
      response.setHeader('Vary', 'Origin');
    }
    response.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method === 'OPTIONS') {
      response.writeHead(204);
      response.end();
      return;
    }
    const url = new URL(request.url, 'http://localhost');
    if (request.method === 'GET' && url.pathname === '/health') {
      sendJson(response, 200, { status: 'ok' });
      return;
    }
    if (
      (request.method === 'POST' && url.pathname !== '/api/translate') ||
      (request.method === 'GET' && url.pathname !== '/api/games') ||
      !['GET', 'POST'].includes(request.method)
    ) {
      sendJson(
        response,
        request.method === 'GET' || request.method === 'POST' ? 404 : 405,
        { error: request.method === 'GET' || request.method === 'POST'
          ? 'Rota não encontrada.'
          : 'Método não permitido.' },
      );
      return;
    }

    const forwardedIp = request.headers['x-forwarded-for']?.split(',')[0].trim();
    const clientIp = trustProxy && forwardedIp
      ? forwardedIp
      : request.socket.remoteAddress || 'unknown';
    const now = Date.now();
    if (now - lastRateLimitCleanup >= rateWindowMs) {
      for (const [ip, entry] of requestsByIp) {
        if (now - entry.startedAt >= rateWindowMs) requestsByIp.delete(ip);
      }
      lastRateLimitCleanup = now;
    }
    let rateEntry = requestsByIp.get(clientIp);
    if (!rateEntry || now - rateEntry.startedAt >= rateWindowMs) {
      rateEntry = { startedAt: now, count: 0 };
      requestsByIp.set(clientIp, rateEntry);
    }
    if (rateEntry.count >= rateLimit) {
      sendJson(response, 429, { error: 'Muitas consultas. Tente novamente em instantes.' });
      return;
    }
    rateEntry.count++;

    if (request.method === 'POST') {
      let body = '';
      request.setEncoding('utf8');
      request.on('data', (chunk) => {
        body += chunk;
        if (body.length > 24_000) {
          if (!response.writableEnded) {
            sendJson(response, 413, {
              error: 'A requisição de tradução é muito grande.',
            });
          }
          request.resume();
        }
      });
      request.on('end', async () => {
        if (response.writableEnded) return;
        try {
          const payload = JSON.parse(body);
          const text = typeof payload.text === 'string' ? payload.text.trim() : '';
          if (!text || text.length > 5000) {
            sendJson(response, 400, {
              error: 'A sinopse deve conter de 1 a 5.000 caracteres.',
            });
            return;
          }

          const cacheKey = createHash('sha256').update(text).digest('hex');
          const cachedTranslation = translations.get(cacheKey);
          if (cachedTranslation) {
            sendJson(response, 200, { translatedText: cachedTranslation });
            return;
          }

          const translatedText = await translateSummary(text);
          if (translations.size >= 500) {
            translations.delete(translations.keys().next().value);
          }
          translations.set(cacheKey, translatedText);
          sendJson(response, 200, { translatedText });
        } catch (error) {
          if (error instanceof SyntaxError) {
            sendJson(response, 400, { error: 'O corpo da requisição não é um JSON válido.' });
            return;
          }
          if (error instanceof ProxyError) {
            sendJson(response, error.status, { error: error.message });
            return;
          }
          console.error(
            '[LibreTranslate] A tradução falhou:',
            error instanceof Error ? error.name : typeof error,
          );
          sendJson(response, 502, { error: 'Não foi possível traduzir a sinopse agora.' });
        }
      });
      request.on('error', () => {
        if (!response.headersSent) {
          sendJson(response, 400, { error: 'Não foi possível ler a requisição.' });
        }
      });
      return;
    }

    try {
      const result = await proxyGames({
        search: url.searchParams.get('search') ?? '',
        genre: url.searchParams.get('genres') ?? '',
        ordering: url.searchParams.get('ordering') ?? 'rating',
        page: url.searchParams.get('page') ?? '1',
      });
      sendJson(response, 200, result);
    } catch (error) {
      if (error instanceof ProxyError) {
        sendJson(response, error.status, { error: error.message });
        return;
      }
      console.error(
        '[IGDB proxy] A consulta falhou:',
        error instanceof Error ? error.name : typeof error,
      );
      sendJson(response, 502, { error: 'Não foi possível consultar a IGDB agora.' });
    }
  });
}

function sendJson(response, status, value) {
  response.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
  });
  response.end(JSON.stringify(value));
}

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  const server = createServer();
  server.listen(port, '0.0.0.0', () => {
    console.log(`IGDB proxy ouvindo na porta ${port}.`);
  });
}

module.exports = {
  buildIgdbQuery,
  createIgdbProxy,
  createServer,
  createSummaryTranslator,
  normalizeGame,
};
