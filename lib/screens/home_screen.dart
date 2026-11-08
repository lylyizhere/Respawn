import 'package:flutter/material.dart';

import '../models/game.dart';
import '../services/igdb_service.dart';
import '../widgets/game_card.dart';
import '../widgets/game_image.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.service});

  final IgdbService? service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final IgdbService _service;
  late final bool _ownsService;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Game> _games = [];
  final Map<int, Game> _favorites = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasNextPage = false;
  String? _error;
  String? _loadMoreError;
  String _query = '';
  String _selectedGenre = '';
  String _selectedOrdering = 'rating';
  String _title = 'Jogos Populares';
  int _currentPage = 1;
  int _requestGeneration = 0;
  int _selectedNavIndex = 0;

  static const _accent = Color(0xFF6C63FF);
  static const _background = Color(0xFF0A0A0F);
  static const _panel = Color(0xFF12121D);

  final List<Map<String, String>> _genres = const [
    {'label': 'Todos os gêneros', 'value': ''},
    {'label': 'Luta', 'value': '4'},
    {'label': 'Tiro', 'value': '5'},
    {'label': 'Corrida', 'value': '10'},
    {'label': 'RPG', 'value': '12'},
    {'label': 'Esporte', 'value': '14'},
    {'label': 'Estratégia', 'value': '15'},
    {'label': 'Aventura', 'value': '31'},
    {'label': 'Indie', 'value': '32'},
  ];

  final List<Map<String, String>> _orderings = const [
    {'label': 'Melhor nota', 'value': 'rating'},
    {'label': 'Mais recentes', 'value': 'released'},
    {'label': 'Nota agregada', 'value': 'aggregated_rating'},
    {'label': 'Nome A–Z', 'value': 'name'},
  ];

  List<Game> get _visibleGames => _selectedNavIndex == 1
      ? _favorites.values.toList(growable: false)
      : _games;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? IgdbService();
    _ownsService = widget.service == null;
    _scrollController.addListener(_onScroll);
    _loadGames(query: '');
  }

  @override
  void dispose() {
    _requestGeneration++;
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    if (_ownsService) _service.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _selectedNavIndex != 0) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  Future<void> _loadGames({String? query}) async {
    final requestId = ++_requestGeneration;
    final requestedQuery = (query ?? _query).trim();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);

    setState(() {
      _query = requestedQuery;
      _currentPage = 1;
      _hasNextPage = false;
      _isLoading = true;
      _isLoadingMore = false;
      _error = null;
      _loadMoreError = null;
    });

    try {
      final result = requestedQuery.isEmpty
          ? await _service.getPopularGames(
              ordering: _selectedOrdering,
              genre: _selectedGenre,
            )
          : await _service.searchGames(
              requestedQuery,
              ordering: _selectedOrdering,
              genre: _selectedGenre,
            );

      if (!mounted || requestId != _requestGeneration) return;
      setState(() {
        _games
          ..clear()
          ..addAll(result.games);
        _hasNextPage = result.hasNextPage;
        _isLoading = false;
        _title = requestedQuery.isEmpty
            ? 'Jogos Populares'
            : 'Resultados para “$requestedQuery”';
      });
    } catch (error) {
      if (!mounted || requestId != _requestGeneration) return;
      setState(() {
        _isLoading = false;
        _error = _readableError(error);
        _title = requestedQuery.isEmpty
            ? 'Jogos Populares'
            : 'Resultados para “$requestedQuery”';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading ||
        _isLoadingMore ||
        !_hasNextPage ||
        _selectedNavIndex != 0) {
      return;
    }

    final requestId = _requestGeneration;
    final nextPage = _currentPage + 1;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final result = await _service.getMoreGames(
        ordering: _selectedOrdering,
        genre: _selectedGenre,
        query: _query,
        page: nextPage,
      );
      if (!mounted || requestId != _requestGeneration) return;

      setState(() {
        final existingIds = _games.map((game) => game.id).toSet();
        _games.addAll(
          result.games.where((game) => !existingIds.contains(game.id)),
        );
        _currentPage = nextPage;
        _hasNextPage = result.hasNextPage;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestGeneration) return;
      setState(() {
        _isLoadingMore = false;
        _loadMoreError = _readableError(error);
      });
    }
  }

  String _readableError(Object error) => error is IgdbServiceException
      ? error.message
      : 'Não foi possível carregar os jogos. Verifique a conexão e tente novamente.';

  void _toggleFavorite(Game game) {
    setState(() {
      if (_favorites.containsKey(game.id)) {
        _favorites.remove(game.id);
      } else {
        _favorites[game.id] = game;
      }
    });
  }

  void _selectGenre(String? value) {
    if (value != null && value != _selectedGenre) {
      setState(() => _selectedGenre = value);
      _loadGames();
    }
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _selectOrdering(String? value) {
    if (value != null && value != _selectedOrdering) {
      setState(() => _selectedOrdering = value);
      _loadGames();
    }
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _background,
      drawer: Drawer(
        width: 280,
        backgroundColor: const Color(0xFF10101A),
        child: SafeArea(child: _buildSidebar()),
      ),
      body: SafeArea(child: _buildMainContent()),
    );
  }

  Widget _buildSidebar() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.videogame_asset_rounded,
                color: Colors.white,
                size: 21,
              ),
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
        const SizedBox(height: 30),
        _navItem(Icons.home_rounded, 'Início', 0),
        _navItem(Icons.favorite_rounded, 'Favoritos', 1),
        const SizedBox(height: 26),
        _sectionLabel('ORDENAR POR'),
        const SizedBox(height: 8),
        ..._orderings.map(
          (item) => _filterItem(
            item['label']!,
            _selectedOrdering == item['value'],
            () => _selectOrdering(item['value']),
          ),
        ),
        const SizedBox(height: 22),
        _sectionLabel('GÊNEROS'),
        const SizedBox(height: 8),
        ..._genres.map(
          (item) => _filterItem(
            item['label']!,
            _selectedGenre == item['value'],
            () => _selectGenre(item['value']),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Abrir menu',
            icon: const Icon(Icons.menu_rounded, color: Colors.white70),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _loadGames(query: value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar jogos…',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: _accent),
                suffixIcon: IconButton(
                  tooltip: 'Limpar busca',
                  icon: const Icon(Icons.close, color: Colors.white38),
                  onPressed: () {
                    _searchController.clear();
                    _loadGames(query: '');
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
                  borderSide: const BorderSide(color: _accent, width: 1.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final visibleGames = _visibleGames;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_selectedNavIndex == 0 && _games.isNotEmpty && _query.isEmpty)
          SliverToBoxAdapter(child: _buildBanner(_games.first)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
            child: Text(
              _selectedNavIndex == 1 ? 'Meus Favoritos' : _title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (_isLoading && _games.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator(color: _accent)),
          )
        else if (_error != null && _games.isEmpty && _selectedNavIndex == 0)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _messageState(
              icon: Icons.cloud_off_rounded,
              message: _error!,
              actionLabel: 'Tentar novamente',
              onAction: () => _loadGames(),
            ),
          )
        else if (visibleGames.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _messageState(
              icon: _selectedNavIndex == 1
                  ? Icons.favorite_border_rounded
                  : Icons.search_off_rounded,
              message: _selectedNavIndex == 1
                  ? 'Você ainda não favoritou nenhum jogo.'
                  : 'Nenhum jogo encontrado.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final game = visibleGames[index];
                    return GameCard(
                      key: ValueKey(game.id),
                      game: game,
                      isFavorite: _favorites.containsKey(game.id),
                      onFavoriteToggle: () => _toggleFavorite(game),
                    );
                  }, childCount: visibleGames.length),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                );
              },
            ),
          ),
        if (_loadMoreError != null && _selectedNavIndex == 0)
          SliverToBoxAdapter(
            child: _messageState(
              icon: Icons.cloud_off_rounded,
              message: _loadMoreError!,
              actionLabel: 'Tentar carregar mais',
              onAction: _loadMore,
            ),
          )
        else if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: _accent)),
            ),
          ),
        if (_error != null && _games.isNotEmpty && _selectedNavIndex == 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ),
      ],
    );
  }

  Widget _messageState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white30, size: 38),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 15),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(Game game) {
    return Container(
      height: 300,
      margin: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1A1A2E),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (game.backgroundImage.isNotEmpty)
            GameImage(
              imageUrl: game.backgroundImage,
              fit: BoxFit.cover,
              errorWidget: const ColoredBox(color: _panel),
              placeholder: const ColoredBox(color: _panel),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Positioned(
            left: 26,
            right: 20,
            bottom: 22,
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
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      game.rating.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.amber),
                    ),
                    const SizedBox(width: 14),
                    FilledButton.tonalIcon(
                      onPressed: () => _openDetails(game),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: const Text('Ver detalhes'),
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _accent,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDetails(Game game) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(
          game: game,
          isFavorite: _favorites.containsKey(game.id),
          onFavoriteToggle: () => _toggleFavorite(game),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = _selectedNavIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? _accent.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          leading: Icon(
            icon,
            color: selected ? _accent : Colors.white38,
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(color: selected ? Colors.white : Colors.white60),
          ),
          onTap: () {
            setState(() => _selectedNavIndex = index);
            _scaffoldKey.currentState?.closeDrawer();
          },
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 12),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _filterItem(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 15,
              color: selected ? _accent : Colors.white24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
