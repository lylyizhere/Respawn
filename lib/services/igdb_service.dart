import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/game.dart';

@immutable
class IgdbPage {
  const IgdbPage({required this.games, required this.hasNextPage});

  final List<Game> games;
  final bool hasNextPage;
}

class IgdbServiceException implements Exception {
  const IgdbServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class IgdbService {
  IgdbService({http.Client? client, String? proxyUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _proxyUrl = proxyUrl ?? const String.fromEnvironment('IGDB_PROXY_URL');

  static const Duration requestTimeout = Duration(seconds: 20);

  final http.Client _client;
  final bool _ownsClient;
  final String _proxyUrl;

  void close() {
    if (_ownsClient) _client.close();
  }

  Future<IgdbPage> searchGames(
    String query, {
    String ordering = 'released',
    String genre = '',
    int page = 1,
  }) {
    return _requestGames(
      query: query,
      ordering: ordering,
      genre: genre,
      page: page,
    );
  }

  Future<IgdbPage> getPopularGames({
    String ordering = 'released',
    String genre = '',
    int page = 1,
  }) {
    return _requestGames(ordering: ordering, genre: genre, page: page);
  }

  Future<IgdbPage> getMoreGames({
    String ordering = 'released',
    String genre = '',
    String query = '',
    required int page,
  }) {
    return _requestGames(
      query: query,
      ordering: ordering,
      genre: genre,
      page: page,
    );
  }

  Future<String> translateSummary(String text) async {
    final summary = text.trim();
    if (summary.isEmpty) return summary;

    final endpoint = _translationEndpoint();
    http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'text': summary}),
          )
          .timeout(requestTimeout);
    } on http.ClientException {
      throw const IgdbServiceException(
        'Não foi possível conectar ao serviço de tradução. Verifique sua conexão e tente novamente.',
      );
    } on TimeoutException {
      throw const IgdbServiceException(
        'A tradução demorou demais. Verifique sua conexão e tente novamente.',
      );
    }

    if (response.statusCode != 200) {
      final message = _readProxyError(response.body);
      throw IgdbServiceException(
        message ??
            'O serviço de tradução respondeu com o código ${response.statusCode}.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const IgdbServiceException(
        'O serviço de tradução retornou uma resposta inválida.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const IgdbServiceException(
        'O serviço de tradução retornou uma resposta inesperada.',
      );
    }
    final translatedText = decoded['translatedText']?.toString().trim();
    if (translatedText == null || translatedText.isEmpty) {
      throw const IgdbServiceException(
        'O serviço de tradução não retornou o texto traduzido.',
      );
    }
    return translatedText;
  }

  Future<IgdbPage> _requestGames({
    String query = '',
    required String ordering,
    required String genre,
    required int page,
  }) async {
    final proxyUrl = Uri.tryParse(_proxyUrl.trim());
    if (proxyUrl == null ||
        !proxyUrl.hasAuthority ||
        !{'http', 'https'}.contains(proxyUrl.scheme)) {
      throw const IgdbServiceException(
        'O endereço do proxy IGDB não foi configurado. Inicie o app com '
        '--dart-define=IGDB_PROXY_URL=https://seu-servidor/api/games.',
      );
    }

    final parameters = <String, String>{'ordering': ordering, 'page': '$page'};
    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty) {
      parameters['search'] = normalizedQuery;
    } else if (ordering == 'released') {
      parameters['today'] = _formatLocalDate(DateTime.now());
    }
    if (genre.isNotEmpty) parameters['genres'] = genre;

    final uri = proxyUrl.replace(queryParameters: parameters);

    try {
      final response = await _client.get(uri).timeout(requestTimeout);
      if (response.statusCode != 200) {
        final decodedError = jsonDecode(response.body);
        final message = decodedError is Map<String, dynamic>
            ? decodedError['error']?.toString()
            : null;
        throw IgdbServiceException(
          message?.isNotEmpty == true
              ? message!
              : 'O proxy IGDB respondeu com o código ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['games'] is! List) {
        throw const IgdbServiceException(
          'A resposta do proxy IGDB veio em um formato inesperado.',
        );
      }

      final games = (decoded['games'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Game.fromJson)
          .toList(growable: false);
      return IgdbPage(
        games: games,
        hasNextPage: decoded['hasNextPage'] == true,
      );
    } on IgdbServiceException {
      rethrow;
    } on http.ClientException {
      throw const IgdbServiceException(
        'Não foi possível conectar ao proxy IGDB. Verifique sua conexão e tente de novo.',
      );
    } on TimeoutException {
      throw const IgdbServiceException(
        'A consulta ao proxy IGDB demorou demais. Verifique sua conexão e tente de novo.',
      );
    } on FormatException {
      throw const IgdbServiceException(
        'O proxy IGDB retornou dados inválidos. Tente novamente mais tarde.',
      );
    }
  }

  Uri _translationEndpoint() {
    final proxyUrl = Uri.tryParse(_proxyUrl.trim());
    if (proxyUrl == null ||
        !proxyUrl.hasAuthority ||
        !{'http', 'https'}.contains(proxyUrl.scheme)) {
      throw const IgdbServiceException(
        'O endereço do proxy de tradução não foi configurado. Inicie o app com '
        '--dart-define=IGDB_PROXY_URL=https://seu-servidor/api/games.',
      );
    }

    final pathSegments = proxyUrl.pathSegments.toList();
    if (pathSegments.isEmpty || pathSegments.last != 'games') {
      throw const IgdbServiceException(
        'O endereço do proxy deve terminar com /api/games para usar a tradução.',
      );
    }
    pathSegments[pathSegments.length - 1] = 'translate';
    return proxyUrl.replace(
      pathSegments: pathSegments,
      queryParameters: const {},
      fragment: '',
    );
  }

  String? _readProxyError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['error']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  String _formatLocalDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
