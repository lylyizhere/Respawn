import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/game.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.game});

  final Game game;
  static const _accent = Color(0xFF6C63FF);
  static const _background = Color(0xFF0A0A0F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: _background,
            leading: IconButton(
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (game.backgroundImage.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: game.backgroundImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ColoredBox(color: Color(0xFF1A1A2E)),
                      errorWidget: (context, url, error) =>
                          const ColoredBox(color: Color(0xFF1A1A2E)),
                    )
                  else
                    const ColoredBox(color: Color(0xFF1A1A2E)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, _background],
                        stops: [0.25, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (game.genres.isNotEmpty)
                                Text(
                                  game.genres.take(2).join(' • ').toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(
                                game.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  height: 1.12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      _infoBadge(
                        Icons.star_rounded,
                        '${game.rating.toStringAsFixed(0)}/100',
                        Colors.amber,
                      ),
                      _infoBadge(
                        Icons.calendar_today_rounded,
                        game.released,
                        Colors.white70,
                      ),
                      ...game.genres
                          .take(3)
                          .map(
                            (genre) => _infoBadge(
                              Icons.category_rounded,
                              genre,
                              _accent,
                            ),
                          ),
                    ],
                  ),
                  if (game.platforms.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _sectionHeading('PLATAFORMAS'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: game.platforms
                          .take(8)
                          .map((platform) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                platform,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _sectionHeading('SOBRE O JOGO'),
                  const SizedBox(height: 10),
                  Text(
                    '${game.name} foi lançado em ${game.released} e tem '
                    'nota ${game.rating.toStringAsFixed(0)}/100 na IGDB'
                    '${game.aggregatedRating > 0 ? ' (nota agregada ${game.aggregatedRating.toStringAsFixed(0)}/100)' : ''}.'
                    '${game.genres.isNotEmpty ? ' Gêneros: ${game.genres.join(', ')}.' : ''}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionHeading('ESTATÍSTICAS'),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final count = constraints.maxWidth >= 700 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: count,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: count == 4 ? 1.45 : 1.35,
                        children: [
                          _statCard(
                            'Nota IGDB',
                            game.rating > 0
                                ? game.rating.toStringAsFixed(0)
                                : 'N/A',
                            Icons.star_rounded,
                            Colors.amber,
                          ),
                          _statCard(
                            'Nota agregada',
                            game.aggregatedRating > 0
                                ? game.aggregatedRating.toStringAsFixed(0)
                                : 'N/A',
                            Icons.analytics_rounded,
                            Colors.greenAccent,
                          ),
                          _statCard(
                            'Gêneros',
                            '${game.genres.length}',
                            Icons.category_rounded,
                            _accent,
                          ),
                          _statCard(
                            'Plataformas',
                            '${game.platforms.length}',
                            Icons.devices_rounded,
                            Colors.lightBlueAccent,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String text) => Text(
    text,
    style: const TextStyle(
      color: Colors.white38,
      fontSize: 11,
      letterSpacing: 1.8,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _infoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
