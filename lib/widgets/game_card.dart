import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';
import '../screens/detail_screen.dart';

class GameCard extends StatefulWidget {
  final Game game;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const GameCard({
    super.key,
    required this.game,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(game: widget.game),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1A1A2E),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          transform: _hovered
              ? (Matrix4.identity()..scale(1.03))
              : Matrix4.identity(),
          child: Stack(
            children: [
              // Imagem
              Positioned.fill(
                child: widget.game.backgroundImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.game.backgroundImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ColoredBox(
                          color: Color(0xFF1A1A2E),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => const ColoredBox(
                          color: Color(0xFF1A1A2E),
                          child: Icon(Icons.videogame_asset,
                              color: Colors.white24, size: 40),
                        ),
                      )
                    : const ColoredBox(color: Color(0xFF1A1A2E)),
              ),
              // Gradiente
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
              ),
              // Botão favorito
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: widget.onFavoriteToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.isFavorite
                          ? Colors.redAccent
                          : Colors.white60,
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Metacritic badge
              if (widget.game.metacritic > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.game.metacritic >= 75
                          ? Colors.green
                          : widget.game.metacritic >= 50
                              ? Colors.orange
                              : Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.game.metacritic}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.game.genres.isNotEmpty)
                        Text(
                          widget.game.genres.take(2).join(' • '),
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        widget.game.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            widget.game.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.amber, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today,
                              color: Colors.white38, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            widget.game.released,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}