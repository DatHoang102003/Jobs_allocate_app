import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /* ───────── configuration ───────── */
  static const String _baseUrl = "http://10.0.2.2:3000";

  /* ───────── keys used in SharedPreferences ───────── */
  static const _kTokenKey = 'auth_token';
  static const _kUserIdKey = 'auth_user_id';

  /* ───────── in-memory cache ───────── */
  static String? _cachedUserId;
  static String? _cachedToken;

  /// quick synchronous access to the logged-in user ID (empty if none)
  static String get currentUserId => _cachedUserId ?? '';

  /* ─────────────────────────────────────────────────── */
  /*  Call this once in main() BEFORE runApp() to fill  */
  /*  the cache from SharedPreferences                  */
  /* ─────────────────────────────────────────────────── */
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getString(_kUserIdKey);
    _cachedToken = prefs.getString(_kTokenKey);
  }

  /* ───────── helpers ───────── */
  static Future<String> getToken() async {
    if (_cachedToken != null) return _cachedToken!;
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_kTokenKey) ?? '';
    _cachedToken = t;
    return t;
  }

  static Future<String> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kUserIdKey) ?? '';
    _cachedUserId = id;
    return id;
  }

  /* ───────── login ───────── */
  static Future<bool> loginUser(String email, String password) async {
    final url = Uri.parse("$_baseUrl/auth/login");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kTokenKey, token);
        await prefs.setString(_kUserIdKey, user['id'] as String);

        _cachedToken = token;
        _cachedUserId = user['id'] as String;
        return true;
      }
      return false;
    } catch (_) {
      rethrow;
    }
  }

  /* ───────── register ───────── */
  static Future<bool> registerUser(String name, String email, String password,
      String passwordConfirm) async {
    final url = Uri.parse("$_baseUrl/auth/register");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "passwordConfirm": passwordConfirm,
      }),
    );
    return res.statusCode == 201;
  }

  /* ───────── logout ───────── */
  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kUserIdKey);
    _cachedToken = null;
    _cachedUserId = null;
  }
}
