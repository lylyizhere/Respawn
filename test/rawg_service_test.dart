import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:respawn/services/rawg_service.dart';

void main() {
  test('codifica busca e encaminha gênero e página à RAWG', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'api.rawg.io');
      expect(request.url.queryParameters['search'], 'Baldur & Gates #3');
      expect(request.url.queryParameters['genres'], 'action');
      expect(request.url.queryParameters['page'], '3');
      expect(request.url.queryParameters['key'], 'unit-test-key');
      return http.Response(
        jsonEncode({
          'results': [
            {
              'id': 42,
              'name': 'Baldur’s Gate 3',
              'rating': 4.7,
              'genres': [],
              'platforms': [],
            },
          ],
          'next': 'https://api.rawg.io/api/games/?page=4',
        }),
        200,
      );
    });
    final service = RawgService(client: client, apiKey: 'unit-test-key');

    final result = await service.searchGames(
      'Baldur & Gates #3',
      genre: 'action',
      page: 3,
    );

    expect(result.games.single.name, 'Baldur’s Gate 3');
    expect(result.hasNextPage, isTrue);
    client.close();
  });

  test('retorna mensagem clara quando a chave não foi configurada', () async {
    final client = MockClient((_) async => http.Response('{}', 200));
    final service = RawgService(client: client, apiKey: '');

    await expectLater(
      service.getPopularGames(),
      throwsA(isA<RawgServiceException>()),
    );
    client.close();
  });
}
