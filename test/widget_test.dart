import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:respawn/main.dart';
import 'package:respawn/models/game.dart';
import 'package:respawn/services/igdb_service.dart';

void main() {
  test('Game.fromJson tolera campos ausentes e tipos inesperados', () {
    final game = Game.fromJson({
      'id': 7.8,
      'name': null,
      'rating': 'indisponível',
      'genres': [
        null,
        {'name': 'RPG'},
      ],
      'platforms': [
        {'platform': null},
        {
          'platform': {'name': 'PC'},
        },
      ],
    });

    expect(game.id, 7);
    expect(game.name, 'Sem título');
    expect(game.rating, 0);
    expect(game.summary, '');
    expect(game.released, 'Sem data');
    expect(game.aggregatedRating, 0);
    expect(game.genres, ['RPG']);
    expect(game.platforms, ['PC']);
  });

  testWidgets('Home apresenta jogos, pesquisa e favoritos sem acessar a rede', (
    tester,
  ) async {
    final service = _FakeIgdbService();
    await tester.pumpWidget(RespawnApp(service: service));
    await tester.pumpAndSettle();

    expect(find.text('Jogos Populares'), findsOneWidget);
    expect(find.text('Hades'), findsWidgets);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -480));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar aos favoritos').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();

    expect(find.text('Meus Favoritos'), findsOneWidget);
    expect(find.text('Hades'), findsOneWidget);
  });

  testWidgets('Detalhes mostram a descrição e permitem favoritar o jogo', (
    tester,
  ) async {
    final service = _FakeIgdbService();
    await tester.pumpWidget(RespawnApp(service: service));
    await tester.pumpAndSettle();

    final gameCard = find.byKey(const ValueKey(1));
    await tester.ensureVisible(gameCard);
    await tester.tap(gameCard);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('SOBRE O JOGO'));
    await tester.pumpAndSettle();
    expect(find.text('SOBRE O JOGO'), findsOneWidget);
    expect(find.text('A mythic adventure.'), findsOneWidget);

    await tester.tap(find.byTooltip('Adicionar aos favoritos'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();

    expect(find.text('Meus Favoritos'), findsOneWidget);
    expect(find.text('Hades'), findsOneWidget);
  });
}

class _FakeIgdbService extends IgdbService {
  _FakeIgdbService() : super(proxyUrl: 'https://proxy.example/api/games');

  final Game _game = const Game(
    id: 1,
    name: 'Hades',
    backgroundImage: '',
    summary: 'A mythic adventure.',
    rating: 85,
    released: '2020-09-17',
    genres: ['Roguelike'],
    aggregatedRating: 90,
    platforms: ['PC'],
  );

  @override
  Future<IgdbPage> getPopularGames({
    String ordering = 'rating',
    String genre = '',
    int page = 1,
  }) async => IgdbPage(games: [_game], hasNextPage: false);

  @override
  Future<IgdbPage> searchGames(
    String query, {
    String ordering = 'rating',
    String genre = '',
    int page = 1,
  }) async => IgdbPage(games: [_game], hasNextPage: false);

  @override
  Future<IgdbPage> getMoreGames({
    String ordering = 'rating',
    String genre = '',
    String query = '',
    required int page,
  }) async => const IgdbPage(games: [], hasNextPage: false);
}
