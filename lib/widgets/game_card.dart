import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/game.dart';
import '../screens/detail_screen.dart';

class GameCard extends StatefulWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final Game game;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.28),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => DetailScreen(game: game),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (game.backgroundImage.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: game.backgroundImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const ColoredBox(color: Color(0xFF1A1A2E)),
                    errorWidget: (context, url, error) =>
                        const _ImageFallback(),
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
                if (game.metacritic > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _MetacriticBadge(score: game.metacritic),
                  ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: IconButton(
                    key: ValueKey('favorite-${game.id}'),
                    tooltip: widget.isFavorite
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                    onPressed: widget.onFavoriteToggle,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.62),
                      foregroundColor:
                          widget.isFavorite ? Colors.redAccent : Colors.white,
                    ),
                    icon: Icon(
                      widget.isFavorite ? Icons.favorite : Icons.favorite_border,
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
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            game.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.amber, fontSize: 11),
                          ),
                          const SizedBox(width: 9),
                          const Icon(Icons.calendar_today,
                              color: Colors.white54, size: 11),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              game.released,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 10),
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
          child: Icon(Icons.videogame_asset_rounded,
              color: Colors.white24, size: 38),
        ),
      );
}

class _MetacriticBadge extends StatelessWidget {
  const _MetacriticBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? Colors.green
        : score >= 50
            ? Colors.orange
            : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$score',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
