import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TasksProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _tasks = [];
  bool _loading = false;

  List<Map<String, dynamic>> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _loading;

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {'Authorization': 'Bearer $token'};
  }

  /* fetch last 20 tasks across all groups the user can see */
  Future<void> fetchRecent() async {
    _loading = true;
    notifyListeners();

    try {
      final res = await http.get(
        Uri.parse('http://10.0.2.2:3000/tasks/recent?limit=20'),
        headers: await _headers(),
      );
      if (res.statusCode != 200) throw Exception(res.body);
      _tasks
        ..clear()
        ..addAll(jsonDecode(res.body));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
