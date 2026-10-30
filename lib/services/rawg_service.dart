import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/game.dart';

@immutable
class RawgPage {
  const RawgPage({required this.games, required this.hasNextPage});

  final List<Game> games;
  final bool hasNextPage;
}

class RawgServiceException implements Exception {
  const RawgServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RawgService {
  RawgService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _apiKey = apiKey ?? const String.fromEnvironment('RAWG_API_KEY');

  static const int pageSize = 20;
  static const Duration requestTimeout = Duration(seconds: 20);

  final http.Client _client;
  final bool _ownsClient;
  final String _apiKey;

  void close() {
    if (_ownsClient) _client.close();
  }

  Future<RawgPage> searchGames(
    String query, {
    String ordering = '-rating',
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

  Future<RawgPage> getPopularGames({
    String ordering = '-rating',
    String genre = '',
    int page = 1,
  }) {
    return _requestGames(ordering: ordering, genre: genre, page: page);
  }

  Future<RawgPage> getMoreGames({
    String ordering = '-rating',
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

  Future<RawgPage> _requestGames({
    String query = '',
    required String ordering,
    required String genre,
    required int page,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw const RawgServiceException(
        'A chave da API RAWG não foi configurada. Inicie o app com '
        '--dart-define=RAWG_API_KEY=SUA_CHAVE.',
      );
    }

    final parameters = <String, String>{
      'key': _apiKey,
      'ordering': ordering,
      'page_size': '$pageSize',
      'page': '$page',
    };
    if (query.trim().isNotEmpty) parameters['search'] = query.trim();
    if (genre.isNotEmpty) parameters['genres'] = genre;

    final uri = Uri.https('api.rawg.io', '/api/games', parameters);

    try {
      final response = await _client.get(uri).timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw RawgServiceException(
          'A RAWG respondeu com o código ${response.statusCode}. '
          'Verifique a chave e tente novamente.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['results'] is! List) {
        throw const RawgServiceException(
          'A resposta da RAWG veio em um formato inesperado.',
        );
      }

      final games = (decoded['results'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Game.fromJson)
          .toList(growable: false);
      final next = decoded['next'];
      return RawgPage(
        games: games,
        hasNextPage: next != null && next.toString().isNotEmpty,
      );
    } on RawgServiceException {
      rethrow;
    } on http.ClientException {
      throw const RawgServiceException(
        'Não foi possível conectar à RAWG. Verifique sua conexão e tente de novo.',
      );
    } on FormatException {
      throw const RawgServiceException(
        'A RAWG retornou dados inválidos. Tente novamente mais tarde.',
      );
    } catch (error) {
      if (error is RawgServiceException) rethrow;
      throw const RawgServiceException(
        'Ocorreu um erro ao consultar a RAWG. Tente novamente.',
      );
    }
  }
}
