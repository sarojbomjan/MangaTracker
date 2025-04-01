import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/models/anime.dart';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/tracking.dart';

class AnimeProvider with ChangeNotifier {
  List<Anime> _animeList = [];
  List<Tracking> _userTracking = [];
  bool _isLoading = false;
  String? _error;
  DateTime _lastJikanRequest =
      DateTime.now().subtract(const Duration(seconds: 2));

  List<Anime> get animeList => _animeList;
  List<Tracking> get userTracking => _userTracking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Helper method to respect Jikan API rate limits
  Future<void> _respectRateLimit() async {
    final now = DateTime.now();
    final difference = now.difference(_lastJikanRequest).inMilliseconds;

    if (difference < ApiConstants.jikanCooldown) {
      await Future.delayed(
          Duration(milliseconds: ApiConstants.jikanCooldown - difference));
    }

    _lastJikanRequest = DateTime.now();
  }

  // Fetch top anime from Jikan API
  // Add debug logging to help troubleshoot image loading issues
  Future<void> fetchAnimeList(String? token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _respectRateLimit();

      final response = await http.get(
        Uri.parse('${ApiConstants.jikanBaseUrl}/top/anime?limit=25'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          _animeList = List<Anime>.from(
              data['data'].map((item) => Anime.fromJson(item)));

          // Debug: Print the first anime's image URL
          if (_animeList.isNotEmpty) {
            print('First anime: ${_animeList[0].title}');
            print('Image URL: ${_animeList[0].coverImage}');
            print('Raw images data: ${_animeList[0].images}');
          }

          _error = null;
        } else {
          _error = 'Invalid response format';
        }
      } else {
        _error = 'Failed to load anime list: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      print('Error fetching anime list: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch anime by ID from Jikan API
  Future<Anime?> fetchAnimeById(int malId) async {
    try {
      await _respectRateLimit();

      final response = await http.get(
        Uri.parse('${ApiConstants.jikanBaseUrl}/anime/$malId/full'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return Anime.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchUserTracking(String? token) async {
    if (token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/tracking/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _userTracking = data.map((item) => Tracking.fromJson(item)).toList();

        // Fetch anime details for each tracking item
        for (var tracking in _userTracking) {
          // Check if we already have this anime in our list
          final existingAnime =
              _animeList.where((a) => a.id == tracking.animeId).toList();

          if (existingAnime.isEmpty) {
            // If not in our list, fetch it from Jikan API
            final anime = await fetchAnimeById(tracking.animeId);
            if (anime != null && !_animeList.any((a) => a.id == anime.id)) {
              _animeList.add(anime);
            }
          }
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTracking(String? token, Tracking tracking) async {
    if (token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/tracking/${tracking.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(tracking.toJson()),
      );

      _isLoading = false;

      if (response.statusCode == 200) {
        await fetchUserTracking(token);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addTracking(
      String? token, int animeId, String status, int progress) async {
    if (token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/tracking/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'anime': animeId,
          'status': status,
          'progress': progress,
        }),
      );

      _isLoading = false;

      if (response.statusCode == 201) {
        await fetchUserTracking(token);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Anime>> searchAnime(String? token, String query) async {
    if (query.isEmpty) return [];

    try {
      await _respectRateLimit();

      final response = await http.get(
        Uri.parse('${ApiConstants.jikanBaseUrl}/anime?q=$query&limit=20'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return List<Anime>.from(
              data['data'].map((item) => Anime.fromJson(item)));
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch anime by season
  Future<List<Anime>> fetchAnimeBySeason(int year, String season) async {
    try {
      await _respectRateLimit();

      final response = await http.get(
        Uri.parse('${ApiConstants.jikanBaseUrl}/seasons/$year/$season'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return List<Anime>.from(
              data['data'].map((item) => Anime.fromJson(item)));
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Fetch currently airing anime
  Future<List<Anime>> fetchCurrentlyAiring() async {
    try {
      await _respectRateLimit();

      final response = await http.get(
        Uri.parse('${ApiConstants.jikanBaseUrl}/seasons/now'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return List<Anime>.from(
              data['data'].map((item) => Anime.fromJson(item)));
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
