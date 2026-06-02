import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Sesi habis. Silakan login ulang.']);
}

class ApiClient {
  static const String _baseUrl = 'http://192.168.1.22:5050/api';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<dynamic> get(String path) => _request('GET', path);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _request('POST', path, body);

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _request('PUT', path, body);

  Future<dynamic> delete(String path) => _request('DELETE', path);

  Future<dynamic> _request(String method, String path,
      [Map<String, dynamic>? body]) async {
    final token = await _getAccessToken();
    var response = await _execute(method, path, body, token);

    if (response.statusCode == 401) {
      final newToken = await _tryRefresh();
      if (newToken == null) {
        await clearTokens();
        throw const UnauthorizedException();
      }
      response = await _execute(method, path, body, newToken);
      if (response.statusCode == 401) {
        await clearTokens();
        throw const UnauthorizedException();
      }
    }

    return _decode(response);
  }

  Future<http.Response> _execute(
      String method, String path, Map<String, dynamic>? body, String? token) {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final encoded = body != null ? jsonEncode(body) : null;

    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        return http.put(uri, headers: headers, body: encoded);
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  Future<String?> _tryRefresh() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String;
        final newRefresh = data['refreshToken'] as String;
        await saveTokens(newAccess, newRefresh);
        return newAccess;
      }
    } catch (_) {}
    return null;
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception(_extractMessage(response.body));
  }

  String _extractMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['message'] as String? ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}
