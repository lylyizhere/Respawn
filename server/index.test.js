'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const { buildIgdbQuery, createServer } = require('./index');

async function startServer(t, options) {
  const server = createServer(options);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise((resolve, reject) => {
    server.close((error) => error ? reject(error) : resolve());
  }));
  const { port } = server.address();
  return `http://127.0.0.1:${port}`;
}

test('builds a bounded IGDB query with allowlisted genre and ordering', () => {
  const query = buildIgdbQuery({
    search: 'Baldur "Gates"',
    genre: '12',
    ordering: 'aggregated_rating',
    page: '3',
  });

  assert.match(query, /search "Baldur \\"Gates\\"";/);
  assert.match(query, /where version_parent = null & genres = 12;/);
  assert.match(query, /sort aggregated_rating desc;/);
  assert.match(query, /limit 21;/);
  assert.match(query, /offset 40;/);
  assert.throws(
    () => buildIgdbQuery({ genre: '12; delete *;' }),
    /gênero informado não é válido/,
  );
  assert.throws(
    () => buildIgdbQuery({ page: '251' }),
    /página deve estar entre/,
  );
});

test('authenticates server-side, normalizes IGDB fields, and caches the token', async (t) => {
  const upstreamRequests = [];
  let tokenRequests = 0;
  const fetchImpl = async (url, options) => {
    if (url.toString().startsWith('https://id.twitch.tv/oauth2/token?')) {
      tokenRequests++;
      assert.equal(options.method, 'POST');
      assert.equal(
        new URL(url).searchParams.get('client_secret'),
        'server-secret',
      );
      return new Response(JSON.stringify({
        access_token: 'test-access-token',
        expires_in: 3600,
      }), { status: 200 });
    }

    upstreamRequests.push({ url, options });
    const games = Array.from({ length: 21 }, (_, index) => ({
      id: index + 1,
      name: index === 0 ? 'Hades' : `Game ${index + 1}`,
      cover: { url: '//images.igdb.com/igdb/image/upload/t_thumb/cover.jpg' },
      rating: 85.25,
      aggregated_rating: 90.5,
      first_release_date: 1600300800,
      genres: [{ name: 'Roguelike' }, {}],
      platforms: [{ name: 'PC' }],
    }));
    return new Response(JSON.stringify(games), { status: 200 });
  };

  const baseUrl = await startServer(t, {
    clientId: 'server-client-id',
    clientSecret: 'server-secret',
    fetchImpl,
  });

  const firstResponse = await fetch(
    `${baseUrl}/api/games?search=Hades&genres=12&ordering=rating&page=2`,
  );
  assert.equal(firstResponse.status, 200);
  const firstResult = await firstResponse.json();
  assert.equal(firstResult.games.length, 20);
  assert.equal(firstResult.hasNextPage, true);
  assert.deepEqual(firstResult.games[0], {
    id: 1,
    name: 'Hades',
    background_image: 'https://images.igdb.com/igdb/image/upload/t_cover_big/cover.jpg',
    rating: 85.25,
    aggregated_rating: 90.5,
    released: '2020-09-17',
    genres: [{ name: 'Roguelike' }],
    platforms: [{ platform: { name: 'PC' } }],
  });

  const igdbRequest = upstreamRequests[0];
  assert.equal(igdbRequest.url, 'https://api.igdb.com/v4/games');
  assert.equal(igdbRequest.options.headers['Client-ID'], 'server-client-id');
  assert.equal(igdbRequest.options.headers.Authorization, 'Bearer test-access-token');
  assert.match(igdbRequest.options.body, /offset 20;/);

  await fetch(`${baseUrl}/api/games`);
  assert.equal(tokenRequests, 1);
});

test('returns explicit setup errors without exposing credentials', async (t) => {
  const baseUrl = await startServer(t, { fetchImpl: async () => {
    throw new Error('fetch should not be called');
  } });
  const response = await fetch(`${baseUrl}/api/games`);

  assert.equal(response.status, 503);
  assert.deepEqual(await response.json(), {
    error: 'Credenciais do servidor ausentes. Configure TWITCH_CLIENT_ID e TWITCH_CLIENT_SECRET.',
  });
});
