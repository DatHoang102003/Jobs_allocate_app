// lib/services/user_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _baseUrl = 'http://10.0.2.2:3000';

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // ─── DEBUG: print token ───────────────────────────────
    print('🔐 stored token: $token');

    if (token == null) {
      print('⚠️  No token found – user not logged in');
      return null;
    }

    final res = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // ─── DEBUG: print raw response ───────────────────────
    print('📡 GET /me → status: ${res.statusCode}');
    print('📡 response body: ${res.body}');

    if (res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        print('✅ Parsed user profile: $data');
        return data;
      } catch (e) {
        print('❌ JSON parse error: $e');
        return null;
      }
    }

    // any non-200
    print('❌ Failed to fetch profile – status ${res.statusCode}');
    return null;
  }

  static Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final res = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) return true;

    // token bad → wipe it
    await prefs.remove('auth_token');
    return false;
  }

  static Future<bool> updateAvatar(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final uri = Uri.parse('$_baseUrl/me');
    final request = http.MultipartRequest('PATCH', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('avatar', file.path));

    final resp = await request.send();
    return resp.statusCode == 200;
  }
}
