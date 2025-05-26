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

  static Future<Map<String, dynamic>?> getDrawerProfile() async {
    final data = await getUserProfile();
    if (data == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final avatarFile = data['avatar'];
    if (avatarFile != null && avatarFile.toString().isNotEmpty) {
      data['avatarUrl'] = 'http://10.0.2.2:8090/api/files/_pb_users_auth_/'
          '${data['id']}/$avatarFile?token=$token';
    } else {
      data['avatarUrl'] = null;
    }

    return {
      'name': data['name'] ?? '',
      'username': data['username'] ?? data['email'] ?? '',
      'avatarUrl': data['avatarUrl'],
    };
  }

  static Future<Map<String, dynamic>?> _rawProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      print('⚠️  No token found – user not logged in');
      return null;
    }

    final res = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

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

    print('❌ Failed to fetch profile – status ${res.statusCode}');
    return null;
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final data = await _rawProfile();
    if (data == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final avatar = data['avatar'];

    data['avatarUrl'] = (avatar != null && avatar.toString().isNotEmpty)
        ? 'http://10.0.2.2:8090/api/files/_pb_users_auth_/${data['id']}/$avatar?token=$token'
        : null;

    return data;
  }

  static Future<bool> updateName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final res = await http.patch(
      Uri.parse('http://10.0.2.2:3000/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': newName}),
    );
    return res.statusCode == 200;
  }

  /* -------------------------------------------------
   Get list of users
------------------------------------------------- */
  static Future<List<dynamic>> getAllUsers() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/users'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}
