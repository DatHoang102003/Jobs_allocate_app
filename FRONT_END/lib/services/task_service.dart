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

  /// Tạo task mới trong group
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

  /// Lấy danh sách task trong group (có thể lọc và phân trang)
  static Future<List<dynamic>> getTasks(
    String groupId, {
    String? status,
    String? assignee,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, String>{};

    if (status != null) queryParams['status'] = status;
    if (assignee != null) queryParams['assignee'] = assignee;
    if (page != null) queryParams['page'] = page.toString();
    if (perPage != null) queryParams['perPage'] = perPage.toString();

    final uri = Uri.parse('$_baseUrl/groups/$groupId/tasks')
        .replace(queryParameters: queryParams);

    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode != 200) {
      throw Exception('Failed to load tasks: ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data is List) {
      return data; // No pagination
    } else {
      return data['items']; // With pagination
    }
  }

  /// Cập nhật trạng thái của task
  static Future<Map<String, dynamic>> updateTaskStatus(
      String taskId, String status) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/tasks/$taskId/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update task status: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Xoá task
  static Future<bool> deleteTask(String taskId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/tasks/$taskId'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to delete task: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['ok'] == true;
  }

  /// Đếm số lượng task theo group và (optionally) status
  static Future<int> countTasks(String groupId, {String? status}) async {
    final queryParams = status != null ? '?status=$status' : '';
    final url = '$_baseUrl/groups/$groupId/tasks/count$queryParams';

    final res = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to count tasks: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['count'] as int;
  }

  /// Lấy danh sách task của người dùng cho ngày hôm nay (hoặc ngày cụ thể)
  static Future<List<dynamic>> getTasksForToday({DateTime? date}) async {
    final queryParams = <String, String>{};
    if (date != null) {
      // Format: yyyy-MM-dd
      final formattedDate =
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      queryParams['date'] = formattedDate;
    }

    final uri = Uri.parse('$_baseUrl/tasks/today')
        .replace(queryParameters: queryParams);

    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch today\'s tasks: ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data is List) {
      return data;
    } else {
      return [data]; // fallback nếu server trả về 1 object
    }
  }
}
