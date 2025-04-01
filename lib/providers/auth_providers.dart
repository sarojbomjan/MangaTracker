import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/constants/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProviders with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');

    if (savedToken != null) {
      _token = savedToken;
      await _getUserProfile();
    }

    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Make HTTP POST request to login endpoint
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      _isLoading = false;

      // Check for successful response
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Ensure that token is in the response
        if (data['token'] != null) {
          _token = data['token'];

          // Save token to shared preferences
          final prefs = await SharedPreferences.getInstance();
          bool tokenSaved = await prefs.setString('token', _token!);

          if (tokenSaved) {
            await _getUserProfile();
            notifyListeners();
            return true;
          } else {
            // Failed to save the token
            print("Failed to save token.");
            return false;
          }
        } else {
          // Handle case where token is not returned in response
          print("Token not found in the response.");
          return false;
        }
      } else {
        // Handle non-200 status codes
        print("Login failed with status code: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      // Handle error in the try block (network errors, etc.)
      print("Login failed: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> register(
      String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      _isLoading = false;
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _token = data['token'];

        // Save token to shared preferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', _token!);

        notifyListeners();
        return null; // Success, no error message
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['error'] ?? "Registration failed! Please try again.";
        print("Registration Response: ${response.body}");

        return errorMessage;
      }
    } catch (e) {
      print("Registration Exception: $e");
      _isLoading = false;
      notifyListeners();
      return "An unexpected error occurred. Please try again.";
    }
  }

  Future<void> _getUserProfile() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/auth/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data);
        notifyListeners(); // Fix: Update UI when user data is loaded
      } else {
        print("Profile Fetch Error: ${response.body}");
      }
    } catch (e) {
      print("Profile Fetch Exception: $e");
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    prefs.remove('token');

    notifyListeners();
  }
}
