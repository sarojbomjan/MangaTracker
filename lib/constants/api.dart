class ApiConstants {
  static const String baseUrl =
      'http://192.168.1.68:8000'; // For Android emulator

  // Jikan API
  static const String jikanBaseUrl = 'https://api.jikan.moe/v4';
  static const int jikanRateLimit = 4; // Requests per second allowed
  static const int jikanCooldown =
      1000; // Milliseconds to wait between requests
}

class TrackingStatus {
  static const String watching = 'watching';
  static const String completed = 'completed';
  static const String planToWatch = 'plan_to_watch';
  static const String dropped = 'dropped';

  static List<String> getAll() {
    return [watching, completed, planToWatch, dropped];
  }

  static String getDisplayName(String status) {
    switch (status) {
      case watching:
        return 'Watching';
      case completed:
        return 'Completed';
      case planToWatch:
        return 'Plan to Watch';
      case dropped:
        return 'Dropped';
      default:
        return status;
    }
  }
}
