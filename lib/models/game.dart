class Game {
  const Game({
    required this.id,
    required this.name,
    required this.backgroundImage,
    required this.coverImage,
    required this.summary,
    required this.rating,
    required this.released,
    required this.genres,
    required this.aggregatedRating,
    required this.platforms,
  });

  final int id;
  final String name;
  final String backgroundImage;
  final String coverImage;
  final String summary;
  final double rating;
  final String released;
  final List<String> genres;
  final double aggregatedRating;
  final List<String> platforms;

  factory Game.fromJson(Map<String, dynamic> json) {
    final rawGenres = json['genres'];
    final genres = rawGenres is List
        ? rawGenres
              .whereType<Map>()
              .map((genre) => genre['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    final rawPlatforms = json['platforms'];
    final platforms = rawPlatforms is List
        ? rawPlatforms
              .whereType<Map>()
              .map((entry) => entry['platform'])
              .whereType<Map>()
              .map((platform) => platform['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    final rawRating = json['rating'];
    final rawAggregatedRating = json['aggregated_rating'];
    final rawId = json['id'];

    return Game(
      id: rawId is num ? rawId.toInt() : 0,
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString()
          : 'Sem título',
      backgroundImage: json['background_image']?.toString() ?? '',
      coverImage:
          json['cover_image']?.toString() ??
          json['background_image']?.toString() ??
          '',
      summary: json['summary']?.toString() ?? '',
      rating: rawRating is num ? rawRating.toDouble() : 0,
      released: json['released']?.toString().trim().isNotEmpty == true
          ? json['released'].toString()
          : 'Sem data',
      genres: genres,
      aggregatedRating: rawAggregatedRating is num
          ? rawAggregatedRating.toDouble()
          : 0,
      platforms: platforms,
    );
  }
}
