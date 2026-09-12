class Game {
  final int id;
  final String name;
  final String backgroundImage;
  final double rating;
  final String released;
  final List<String> genres;
  final int metacritic;
  final List<String> platforms;

  Game({
    required this.id,
    required this.name,
    required this.backgroundImage,
    required this.rating,
    required this.released,
    required this.genres,
    required this.metacritic,
    required this.platforms,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    final genres = (json['genres'] as List<dynamic>? ?? [])
        .map((g) => g['name'].toString())
        .toList();

    final platforms = (json['platforms'] as List<dynamic>? ?? [])
        .map((p) => p['platform']['name'].toString())
        .toList();

    return Game(
      id: json['id'],
      name: json['name'] ?? 'Sem título',
      backgroundImage: json['background_image'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      released: json['released'] ?? 'Sem data',
      genres: genres,
      metacritic: json['metacritic'] ?? 0,
      platforms: platforms,
    );
  }
}