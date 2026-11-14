import 'package:flutter/material.dart';

import '../models/game.dart';
import '../services/igdb_service.dart';
import '../screens/detail_screen.dart';
import 'game_image.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.service,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final Game game;
  final IgdbService service;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final game = this.game;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => DetailScreen(
                game: game,
                service: service,
                isFavorite: isFavorite,
                onFavoriteToggle: onFavoriteToggle,
              ),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (game.coverImage.isNotEmpty || game.backgroundImage.isNotEmpty)
                GameImage(
                  imageUrl: game.coverImage.isNotEmpty
                      ? game.coverImage
                      : game.backgroundImage,
                  fit: BoxFit.cover,
                  placeholder: const ColoredBox(color: Color(0xFF1A1A2E)),
                  errorWidget: const _ImageFallback(),
                )
              else
                const _ImageFallback(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.2, 1],
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: IconButton(
                  key: ValueKey('favorite-${game.id}'),
                  tooltip: isFavorite
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                  onPressed: onFavoriteToggle,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.62),
                    foregroundColor: isFavorite
                        ? Colors.redAccent
                        : Colors.white,
                  ),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 19,
                  ),
                ),
              ),
              Positioned(
                left: 11,
                right: 11,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (game.genres.isNotEmpty)
                      Text(
                        game.genres.take(2).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB7B2FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      game.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          game.rating.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white54,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            game.formattedReleaseDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFF1A1A2E),
    child: Center(
      child: Icon(
        Icons.videogame_asset_rounded,
        color: Colors.white24,
        size: 38,
      ),
    ),
  );
}
