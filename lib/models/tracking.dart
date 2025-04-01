class Tracking {
  final int id;
  final int animeId;
  final String status; // watching, completed, plan_to_watch, dropped
  final int progress;
  final double? rating;
  final String? notes;

  Tracking({
    required this.id,
    required this.animeId,
    required this.status,
    required this.progress,
    this.rating,
    this.notes,
  });

  factory Tracking.fromJson(Map<String, dynamic> json) {
    return Tracking(
      id: json['id'],
      animeId: json['anime'],
      status: json['status'],
      progress: json['progress'],
      rating: json['rating']?.toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anime': animeId,
      'status': status,
      'progress': progress,
      'rating': rating,
      'notes': notes,
    };
  }
}
