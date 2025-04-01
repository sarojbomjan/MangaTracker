class Anime {
  final int id;
  final String title;
  final String? description;
  final Map<String, dynamic>? images;
  final String type; // TV, Movie, OVA, etc.
  final int episodes;
  final String status; // Airing, Completed, etc.
  final double rating;
  final List<String> genres;
  final String? airedFrom;
  final String? airedTo;
  final int? malId; // MyAnimeList ID

  Anime({
    required this.id,
    required this.title,
    this.description,
    this.images,
    required this.type,
    required this.episodes,
    required this.status,
    required this.rating,
    required this.genres,
    this.airedFrom,
    this.airedTo,
    this.malId,
  });

  String? get coverImage {
    if (images == null) return null;

    // Try to get large image first
    if (images!['jpg'] != null && images!['jpg']['large_image_url'] != null) {
      return images!['jpg']['large_image_url'];
    }

    // Fall back to image_url if large is not available
    if (images!['jpg'] != null && images!['jpg']['image_url'] != null) {
      return images!['jpg']['image_url'];
    }

    return null;
  }

  factory Anime.fromJson(Map<String, dynamic> json) {
    // Handle Jikan API response
    if (json['mal_id'] != null) {
      return Anime(
        id: json['mal_id'],
        malId: json['mal_id'],
        title: json['title'] ?? json['title_english'] ?? 'Unknown Title',
        description: json['synopsis'],
        images: json['images'],
        type: json['type'] ?? 'Unknown',
        episodes: json['episodes'] ?? 0,
        status: json['status'] ?? 'Unknown',
        rating: json['score'] != null ? json['score'].toDouble() : 0.0,
        genres: json['genres'] != null
            ? List<String>.from(json['genres'].map((genre) => genre['name']))
            : [],
        airedFrom: json['aired'] != null ? json['aired']['from'] : null,
        airedTo: json['aired'] != null ? json['aired']['to'] : null,
      );
    }

    // Handle our backend response (for backward compatibility)
    return Anime(
      id: json['id'],
      malId: json['mal_id'],
      title: json['title'],
      description: json['description'],
      images: {
        'jpg': {'large_image_url': json['cover_image']}
      },
      type: json['type'],
      episodes: json['episodes'],
      status: json['status'],
      rating: json['rating'] != null ? json['rating'].toDouble() : 0.0,
      genres: List<String>.from(json['genres']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mal_id': malId,
      'title': title,
      'description': description,
      'cover_image': coverImage,
      'type': type,
      'episodes': episodes,
      'status': status,
      'rating': rating,
      'genres': genres,
    };
  }
}
