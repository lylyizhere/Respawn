import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';

class DetailScreen extends StatelessWidget {
  final Game game;

  const DetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          // Banner topo
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0F),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagem
                  CachedNetworkImage(
                    imageUrl: game.backgroundImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const ColoredBox(color: Color(0xFF1A1A2E)),
                    errorWidget: (context, url, error) =>
                        const ColoredBox(color: Color(0xFF1A1A2E)),
                  ),
                  // Gradiente
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          const Color(0xFF0A0A0F),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Info sobre a imagem
                  Positioned(
                    left: 32,
                    right: 32,
                    bottom: 32,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (game.genres.isNotEmpty)
                                Text(
                                  game.genres.take(2).join(' • ').toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                game.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Metacritic badge grande
                        if (game.metacritic > 0)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: game.metacritic >= 75
                                  ? Colors.green
                                  : game.metacritic >= 50
                                      ? Colors.orange
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${game.metacritic}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'MC',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
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

          // Conteúdo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges de info
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _infoBadge(Icons.star_rounded, game.rating.toStringAsFixed(1), Colors.amber),
                      _infoBadge(Icons.calendar_today, game.released, Colors.white54),
                      ...game.genres.take(3).map(
                            (g) => _infoBadge(Icons.category_rounded, g, const Color(0xFF6C63FF)),
                          ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Plataformas
                  if (game.platforms.isNotEmpty) ...[
                    const Text(
                      'PLATAFORMAS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: game.platforms
                          .take(6)
                          .map((p) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A2E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white12),
                                ),
                                child: Text(
                                  p,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Sobre
                  const Text(
                    'SOBRE O JOGO',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${game.name} é um jogo lançado em ${game.released}, '
                    'com avaliação de ${game.rating.toStringAsFixed(1)} na plataforma RAWG'
                    '${game.metacritic > 0 ? ' e nota ${game.metacritic} no Metacritic' : ''}. '
                    '${game.genres.isNotEmpty ? 'Pertence ao gênero ${game.genres.join(', ')}.' : ''}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Estatísticas
                  const Text(
                    'ESTATÍSTICAS',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statCard('Nota RAWG', game.rating.toStringAsFixed(1), Icons.star_rounded, Colors.amber),
                      const SizedBox(width: 16),
                      _statCard('Metacritic', game.metacritic > 0 ? '${game.metacritic}' : 'N/A', Icons.analytics_rounded, Colors.green),
                      const SizedBox(width: 16),
                      _statCard('Gêneros', '${game.genres.length}', Icons.category_rounded, const Color(0xFF6C63FF)),
                      const SizedBox(width: 16),
                      _statCard('Plataformas', '${game.platforms.length}', Icons.devices_rounded, Colors.blueAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}