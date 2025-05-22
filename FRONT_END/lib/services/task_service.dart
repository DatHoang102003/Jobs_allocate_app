import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  static const _baseUrl = 'http://10.0.2.2:3000';

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<Map<String, dynamic>> createTask(
    String groupId, {
    required String title,
    String? description,
    String? assignee,
    DateTime? deadline,
  }) async {
    final body = <String, dynamic>{'title': title};
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (assignee != null && assignee.isNotEmpty) {
      body['assignee'] = assignee;
    }
    if (deadline != null) {
      body['deadline'] = deadline.toIso8601String();
    }

    final res = await http.post(
      Uri.parse('$_baseUrl/groups/$groupId/tasks'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create task: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
