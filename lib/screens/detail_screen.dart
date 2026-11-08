import 'package:flutter/material.dart';

import '../models/game.dart';
import '../widgets/game_image.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.game,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Game game;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  static const _accent = Color(0xFF8A80FF);
  static const _background = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF151520);

  late bool _isFavorite = widget.isFavorite;
  Game get game => widget.game;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final heroHeight = (width * 0.34).clamp(300.0, 410.0);

    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: heroHeight,
            pinned: true,
            backgroundColor: _background,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: _roundAction(
                tooltip: 'Voltar',
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            actions: [
              if (widget.onFavoriteToggle != null)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _roundAction(
                    tooltip: _isFavorite
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                    icon: _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavorite ? Colors.redAccent : Colors.white,
                    onPressed: () {
                      widget.onFavoriteToggle?.call();
                      setState(() => _isFavorite = !_isFavorite);
                    },
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (game.backgroundImage.isNotEmpty)
                    GameImage(
                      imageUrl: game.backgroundImage,
                      fit: BoxFit.cover,
                      placeholder: const ColoredBox(color: _surface),
                      errorWidget: const ColoredBox(color: _surface),
                    )
                  else
                    const ColoredBox(color: _surface),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x55000000),
                          Color(0x18000000),
                          _background,
                        ],
                        stops: [0, 0.38, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 28,
                    right: 28,
                    bottom: 30,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1050),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (game.genres.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: game.genres
                                    .take(3)
                                    .map((genre) {
                                      return _heroTag(genre.toUpperCase());
                                    })
                                    .toList(growable: false),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              game.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: width < 600 ? 32 : 42,
                                height: 1.08,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 18),
                                ],
                              ),
                            ),
                            const SizedBox(height: 13),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _heroMeta(
                                  Icons.star_rounded,
                                  game.rating > 0
                                      ? '${game.rating.toStringAsFixed(0)}/100'
                                      : 'Sem nota',
                                  color: Colors.amber,
                                ),
                                _heroMeta(
                                  Icons.calendar_month_rounded,
                                  _formatReleaseDate(game.released),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 22, 26, 48),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 760;
                      final overview = _buildOverview();
                      final ratings = _buildRatings();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: overview),
                                const SizedBox(width: 24),
                                Expanded(flex: 2, child: ratings),
                              ],
                            )
                          else ...[
                            overview,
                            const SizedBox(height: 22),
                            ratings,
                          ],
                          if (game.genres.isNotEmpty) ...[
                            const SizedBox(height: 30),
                            _buildTags(
                              title: 'GÊNEROS',
                              values: game.genres,
                              icon: Icons.category_rounded,
                            ),
                          ],
                          if (game.platforms.isNotEmpty) ...[
                            const SizedBox(height: 26),
                            _buildTags(
                              title: 'PLATAFORMAS',
                              values: game.platforms,
                              icon: Icons.devices_rounded,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final summary = game.summary.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('SOBRE O JOGO'),
        const SizedBox(height: 10),
        Text(
          summary.isNotEmpty
              ? summary
              : 'Ainda não há uma descrição disponível para este jogo.',
          style: TextStyle(
            color: summary.isNotEmpty ? Colors.white70 : Colors.white38,
            fontSize: 15,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildRatings() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('AVALIAÇÕES'),
          const SizedBox(height: 18),
          _ratingRow(
            icon: Icons.star_rounded,
            label: 'Nota IGDB',
            value: game.rating > 0
                ? '${game.rating.toStringAsFixed(0)}/100'
                : 'N/A',
            color: Colors.amber,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.white.withValues(alpha: 0.08)),
          ),
          _ratingRow(
            icon: Icons.groups_rounded,
            label: 'Comunidade',
            value: game.aggregatedRating > 0
                ? '${game.aggregatedRating.toStringAsFixed(0)}/100'
                : 'N/A',
            color: Colors.lightGreenAccent,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.white.withValues(alpha: 0.08)),
          ),
          _ratingRow(
            icon: Icons.calendar_month_rounded,
            label: 'Lançamento',
            value: _formatReleaseDate(game.released),
            color: Colors.lightBlueAccent,
          ),
        ],
      ),
    );
  }

  Widget _ratingRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTags({
    required String title,
    required List<String> values,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(title),
        const SizedBox(height: 12),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: values.map((value) => _pill(value, icon)).toList(),
        ),
      ],
    );
  }

  Widget _roundAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.55),
        foregroundColor: color,
      ),
      icon: Icon(icon, size: 20),
    );
  }

  Widget _heroTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          letterSpacing: 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _heroMeta(IconData icon, String text, {Color color = Colors.white70}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
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

  Widget _sectionHeading(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        letterSpacing: 1.7,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _pill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accent, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatReleaseDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
