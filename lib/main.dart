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

  String get formattedReleaseDate => _formatReleaseDate(released);

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

String _formatReleaseDate(String value) {
  final exactDate = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);
  if (exactDate != null) {
    return _formatDate(
          int.parse(exactDate[1]!),
          int.parse(exactDate[2]!),
          int.parse(exactDate[3]!),
        ) ??
        value;
  }

  final monthAndYear = RegExp(r'^(\d{2})/(\d{4})$').firstMatch(value);
  if (monthAndYear != null) {
    return _formatDate(
          1,
          int.parse(monthAndYear[1]!),
          int.parse(monthAndYear[2]!),
        ) ??
        value;
  }

  final yearOnly = RegExp(r'^(\d{4})$').firstMatch(value);
  if (yearOnly != null) {
    return '01/01/${yearOnly[1]}';
  }

  final isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (isoDate != null) {
    return _formatDate(
          int.parse(isoDate[3]!),
          int.parse(isoDate[2]!),
          int.parse(isoDate[1]!),
        ) ??
        value;
  }

  return value;
}

String? _formatDate(int day, int month, int year) {
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;

  return '${day.toString().padLeft(2, '0')}/'
      '${month.toString().padLeft(2, '0')}/$year';
}
