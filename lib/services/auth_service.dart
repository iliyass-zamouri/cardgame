import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Use 10.0.2.2 for Android emulator to connect to localhost
  // Use your computer's IP if running on real device
  static const String baseUrl = 'http://10.0.2.2:3000';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Save token and user data to local storage
  static Future<void> _saveUserData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Clear stored data (logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Validate stored token
  static Future<bool> validateToken() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // Token is invalid, clear it
        await clearUserData();
        return false;
      }
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];
        
        if (token == null) {
          throw Exception('Server did not return authentication token');
        }
        
        // Save token and user data
        await _saveUserData(token, responseData);
        
        return responseData;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Register error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserStats(int userId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/stats'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load stats');
      }
    } catch (e) {
      print('Stats error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<List<dynamic>> getMatchHistory(int userId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/matches'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Match history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load match history');
      }
    } catch (e) {
      print('Match history error: $e');
      throw Exception('Network error: $e');
    }
  }
}
