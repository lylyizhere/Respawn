import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/rawg_service.dart';
import '../widgets/game_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RawgService _service = RawgService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Game> _games = [];
  Set<int> _favorites = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _titulo = 'Jogos Populares';
  String _selectedGenre = '';
  String _selectedOrdering = '-rating';
  int _currentPage = 1;
  String _currentQuery = '';
  int _selectedNavIndex = 0;

  final List<Map<String, dynamic>> _genres = [
    {'label': 'Todos', 'value': ''},
    {'label': 'Ação', 'value': 'action'},
    {'label': 'RPG', 'value': 'role-playing-games-rpg'},
    {'label': 'Aventura', 'value': 'adventure'},
    {'label': 'Esporte', 'value': 'sports'},
    {'label': 'Corrida', 'value': 'racing'},
    {'label': 'Indie', 'value': 'indie'},
    {'label': 'Shooter', 'value': 'shooter'},
    {'label': 'Estratégia', 'value': 'strategy'},
  ];

  final List<Map<String, dynamic>> _orderings = [
    {'label': 'Melhor Nota', 'value': '-rating'},
    {'label': 'Mais Recentes', 'value': '-released'},
    {'label': 'Metacritic', 'value': '-metacritic'},
    {'label': 'Nome A-Z', 'value': 'name'},
  ];

  @override
  void initState() {
    super.initState();
    _loadGames();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _currentQuery = '';
    });
    final games = await _service.getPopularGames(
      ordering: _selectedOrdering,
      genre: _selectedGenre,
    );
    setState(() {
      _games = games;
      _isLoading = false;
      _titulo = 'Jogos Populares';
    });
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _currentPage++;
    final more = await _service.getMoreGames(
      ordering: _selectedOrdering,
      genre: _selectedGenre,
      page: _currentPage,
    );
    setState(() {
      _games.addAll(more);
      _isLoadingMore = false;
    });
  }

  Future<void> _searchGames(String query) async {
    if (query.isEmpty) {
      _loadGames();
      return;
    }
    setState(() {
      _isLoading = true;
      _currentQuery = query;
    });
    final games = await _service.searchGames(query, ordering: _selectedOrdering);
    setState(() {
      _games = games;
      _isLoading = false;
      _titulo = 'Resultados para "$query"';
    });
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  List<Game> get _displayedGames {
    if (_selectedNavIndex == 1) {
      return _games.where((g) => _favorites.contains(g.id)).toList();
    }
    return _games;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: const Color(0xFF0F0F1A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.videogame_asset,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Respawn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Nav items
                _navItem(Icons.home_rounded, 'Início', 0),
                _navItem(Icons.favorite_rounded, 'Favoritos', 1),
                const SizedBox(height: 32),
                // Ordenação
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ORDENAR POR',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      ..._orderings.map((o) => _filterChip(
                            o['label'],
                            _selectedOrdering == o['value'],
                            () {
                              setState(() => _selectedOrdering = o['value']);
                              _loadGames();
                            },
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Gêneros
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GÊNEROS',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      ..._genres.map((g) => _filterChip(
                            g['label'],
                            _selectedGenre == g['value'],
                            () {
                              setState(() => _selectedGenre = g['value']);
                              _loadGames();
                            },
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo principal
          Expanded(
            child: Column(
              children: [
                // Topbar
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  color: const Color(0xFF0A0A0F),
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _searchGames,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar jogo...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF6C63FF)),
                      suffixIcon: IconButton(
                        icon:
                            const Icon(Icons.close, color: Colors.white38),
                        onPressed: () {
                          _controller.clear();
                          _loadGames();
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF6C63FF), width: 1.5),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6C63FF)))
                      : CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            // Banner destaque
                            if (_selectedNavIndex == 0 &&
                                _games.isNotEmpty &&
                                _currentQuery.isEmpty)
                              SliverToBoxAdapter(
                                child: _buildBanner(_games.first),
                              ),

                            // Título
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                                child: Text(
                                  _selectedNavIndex == 1
                                      ? 'Meus Favoritos'
                                      : _titulo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // Grid
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              sliver: _displayedGames.isEmpty
                                  ? const SliverToBoxAdapter(
                                      child: Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 60),
                                          child: Text(
                                            'Nenhum jogo encontrado.',
                                            style: TextStyle(
                                                color: Colors.white38,
                                                fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    )
                                  : SliverGrid(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final game = _displayedGames[index];
                                          return GameCard(
                                            game: game,
                                            isFavorite:
                                                _favorites.contains(game.id),
                                            onFavoriteToggle: () =>
                                                _toggleFavorite(game.id),
                                          );
                                        },
                                        childCount: _displayedGames.length,
                                      ),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        childAspectRatio: 0.8,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                    ),
                            ),

                            // Loading more
                            if (_isLoadingMore)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF6C63FF)),
                                  ),
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
    );
  }

  Widget _buildBanner(Game game) {
    return Container(
      height: 320,
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1A1A2E),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: game.backgroundImage,
            fit: BoxFit.cover,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
              ),
            ),
          ),
          Positioned(
            left: 32,
            bottom: 32,
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
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      game.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    if (game.metacritic > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'MC ${game.metacritic}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Ver Detalhes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? const Color(0xFF6C63FF) : Colors.white38,
                size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF6C63FF) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFF6C63FF) : Colors.white24,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}