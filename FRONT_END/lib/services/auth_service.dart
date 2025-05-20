import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = "http://10.0.2.2:3000";

  static Future<bool> loginUser(String email, String password) async {
    final url = Uri.parse("$_baseUrl/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> registerUser(String name, String email, String password,
      String passwordConfirm) async {
    final url = Uri.parse("$_baseUrl/auth/register");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "passwordConfirm": passwordConfirm,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("Register error: $e");
      return false;
    }
  }

  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Clear saved token
  }
}
