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
      expect(request.url.queryParameters['today'], isNull);
      expect(request.url.queryParameters['genres'], '12');
      expect(request.url.queryParameters['page'], '3');
      expect(request.url.queryParameters['ordering'], 'aggregated_rating');
      return http.Response(
        jsonEncode({
          'games': [
            {
              'id': 42,
              'name': 'Baldur’s Gate 3',
              'summary': 'A fantasy role-playing game.',
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
    expect(result.games.single.summary, 'A fantasy role-playing game.');
    expect(result.games.single.rating, 95.2);
    expect(result.games.single.aggregatedRating, 91.4);
    expect(result.hasNextPage, isTrue);
    client.close();
  });

  test('envia a data local para filtrar lançamentos do dia', () async {
    final client = MockClient((request) async {
      final now = DateTime.now();
      final expectedToday =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      expect(request.url.queryParameters['ordering'], 'released');
      expect(request.url.queryParameters['today'], expectedToday);
      return http.Response(
        jsonEncode({'games': [], 'hasNextPage': false}),
        200,
      );
    });
    final service = IgdbService(
      client: client,
      proxyUrl: 'https://proxy.example/api/games',
    );

    await service.getPopularGames();
    client.close();
  });

  test('envia a sinopse ao proxy e retorna a tradução', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/translate');
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body), {'text': 'A mythic adventure.'});
      return http.Response(
        jsonEncode({'translatedText': 'Uma aventura mitológica.'}),
        200,
      );
    });
    final service = IgdbService(
      client: client,
      proxyUrl: 'https://proxy.example/api/games',
    );

    expect(
      await service.translateSummary(' A mythic adventure. '),
      'Uma aventura mitológica.',
    );
    client.close();
  });

  test('usa a mensagem do proxy quando a tradução falha', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'error': 'Não foi possível conectar ao LibreTranslate.'}),
        502,
      ),
    );
    final service = IgdbService(
      client: client,
      proxyUrl: 'https://proxy.example/api/games',
    );

    await expectLater(
      service.translateSummary('A mythic adventure.'),
      throwsA(
        isA<IgdbServiceException>().having(
          (error) => error.message,
          'message',
          'Não foi possível conectar ao LibreTranslate.',
        ),
      ),
    );
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
