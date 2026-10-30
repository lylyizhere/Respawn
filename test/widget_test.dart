import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:respawn/main.dart';
import 'package:respawn/models/game.dart';
import 'package:respawn/services/rawg_service.dart';

void main() {
  test('Game.fromJson tolera campos ausentes e tipos inesperados', () {
    final game = Game.fromJson({
      'id': 7.8,
      'name': null,
      'rating': 'indisponível',
      'genres': [null, {'name': 'RPG'}],
      'platforms': [
        {'platform': null},
        {'platform': {'name': 'PC'}},
      ],
    });

    expect(game.id, 7);
    expect(game.name, 'Sem título');
    expect(game.rating, 0);
    expect(game.released, 'Sem data');
    expect(game.genres, ['RPG']);
    expect(game.platforms, ['PC']);
  });

  testWidgets('Home apresenta jogos, pesquisa e favoritos sem acessar a rede',
      (tester) async {
    final service = _FakeRawgService();
    await tester.pumpWidget(RespawnApp(service: service));
    await tester.pumpAndSettle();

    expect(find.text('Jogos Populares'), findsOneWidget);
    expect(find.text('Hades'), findsWidgets);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -480));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar aos favoritos').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoritos').first);
    await tester.pumpAndSettle();

    expect(find.text('Meus Favoritos'), findsOneWidget);
    expect(find.text('Hades'), findsOneWidget);
  });
}

class _FakeRawgService extends RawgService {
  _FakeRawgService() : super(apiKey: 'test-key');

  final Game _game = const Game(
    id: 1,
    name: 'Hades',
    backgroundImage: '',
    rating: 4.5,
    released: '2020-09-17',
    genres: ['Roguelike'],
    metacritic: 93,
    platforms: ['PC'],
  );

  @override
  Future<RawgPage> getPopularGames({
    String ordering = '-rating',
    String genre = '',
    int page = 1,
  }) async => RawgPage(games: [_game], hasNextPage: false);

  @override
  Future<RawgPage> searchGames(
    String query, {
    String ordering = '-rating',
    String genre = '',
    int page = 1,
  }) async => RawgPage(games: [_game], hasNextPage: false);

  @override
  Future<RawgPage> getMoreGames({
    String ordering = '-rating',
    String genre = '',
    String query = '',
    required int page,
  }) async => const RawgPage(games: [], hasNextPage: false);
}
