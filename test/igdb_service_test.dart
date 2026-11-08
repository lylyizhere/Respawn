import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:respawn/services/igdb_service.dart';

void main() {
  test('codifica parâmetros e interpreta a resposta do proxy IGDB', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'proxy.example');
      expect(request.url.path, '/api/games');
      expect(request.url.queryParameters['search'], 'Baldur & Gates #3');
      expect(request.url.queryParameters['genres'], '12');
      expect(request.url.queryParameters['page'], '3');
      expect(request.url.queryParameters['ordering'], 'aggregated_rating');
      return http.Response(
        jsonEncode({
          'games': [
            {
              'id': 42,
              'name': 'Baldur’s Gate 3',
              'rating': 95.2,
              'aggregated_rating': 91.4,
              'released': '2023-08-03',
              'genres': [],
              'platforms': [],
            },
          ],
          'hasNextPage': true,
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = IgdbService(
      client: client,
      proxyUrl: 'https://proxy.example/api/games',
    );

    final result = await service.searchGames(
      'Baldur & Gates #3',
      genre: '12',
      ordering: 'aggregated_rating',
      page: 3,
    );

    expect(result.games.single.name, 'Baldur’s Gate 3');
    expect(result.games.single.rating, 95.2);
    expect(result.games.single.aggregatedRating, 91.4);
    expect(result.hasNextPage, isTrue);
    client.close();
  });

  test(
    'retorna mensagem clara quando o endereço do proxy não foi configurado',
    () async {
      final client = MockClient((_) async => http.Response('{}', 200));
      final service = IgdbService(client: client, proxyUrl: '');

      await expectLater(
        service.getPopularGames(),
        throwsA(isA<IgdbServiceException>()),
      );
      client.close();
    },
  );

  test('propaga a mensagem de erro enviada pelo proxy', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'error': 'Credenciais do servidor ausentes.'}),
        500,
      ),
    );
    final service = IgdbService(
      client: client,
      proxyUrl: 'https://proxy.example/api/games',
    );

    await expectLater(
      service.getPopularGames(),
      throwsA(
        isA<IgdbServiceException>().having(
          (error) => error.message,
          'message',
          'Credenciais do servidor ausentes.',
        ),
      ),
    );
    client.close();
  });
}
