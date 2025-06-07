import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  static const _baseUrl = 'http://10.0.2.2:3000';

  /* ─────────────────────────────
     Auth headers helper
  ───────────────────────────── */
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /* ─────────────────────────────
     CREATE  (POST /groups/:id/tasks)
  ───────────────────────────── */
  static Future<Map<String, dynamic>> createTask(
    String groupId, {
    required String title,
    String? description,
    String? assignee,
    DateTime? deadline,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      // omit status → backend defaults to "pending"
      // or add `'status': 'pending'` explicitly
    };
    if (description?.isNotEmpty ?? false) body['description'] = description;
    if (assignee?.isNotEmpty ?? false) body['assignee'] = assignee;
    if (deadline != null) body['deadline'] = deadline.toIso8601String();

    final res = await http.post(
      Uri.parse('$_baseUrl/groups/$groupId/tasks'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode != 201)
      throw Exception('Failed to create task: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /* ─────────────────────────────
     LIST  (GET /groups/:id/tasks)
  ───────────────────────────── */
  static Future<List<dynamic>> getTasks(
    String groupId, {
    String? status,
    String? assignee,
    int? page,
    int? perPage,
  }) async {
    final qp = <String, String>{};
    if (status != null) qp['status'] = status;
    if (assignee != null) qp['assignee'] = assignee;
    if (page != null) qp['page'] = '$page';
    if (perPage != null) qp['perPage'] = '$perPage';

    final uri = Uri.parse('$_baseUrl/groups/$groupId/tasks')
        .replace(queryParameters: qp);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200)
      throw Exception('Failed to load tasks: ${res.body}');

    final data = jsonDecode(res.body);
    return (data is List) ? data : data['items'];
  }

  /* ─────────────────────────────
     STATUS-ONLY UPDATE (PATCH /tasks/:id/status)
  ───────────────────────────── */
  static Future<Map<String, dynamic>> updateTaskStatus(
      String taskId, String status) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/tasks/$taskId/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode != 200)
      throw Exception('Failed to update status: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /* ─────────────────────────────
     FULL EDIT (PATCH /tasks/:id)
     Call only if you expose an “Edit Task” screen.
  ───────────────────────────── */
  static Future<Map<String, dynamic>> updateTask(
      String taskId, Map<String, dynamic> patch) async {
    // patch may include title / description / assignee / deadline / status
    final res = await http.patch(
      Uri.parse('$_baseUrl/tasks/$taskId'),
      headers: await _headers(),
      body: jsonEncode(patch),
    );
    if (res.statusCode != 200)
      throw Exception('Failed to update task: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /* ─────────────────────────────
     DELETE (DELETE /tasks/:id)
  ───────────────────────────── */
  static Future<bool> deleteTask(String taskId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/tasks/$taskId'),
      headers: await _headers(),
    );
    if (res.statusCode != 200)
      throw Exception('Failed to delete task: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['ok'] == true;
  }

  /* ─────────────────────────────
     COUNT (GET /groups/:id/tasks/count)
  ───────────────────────────── */
  static Future<int> countTasks(String groupId, {String? status}) async {
    final uri = Uri.parse(
      '$_baseUrl/groups/$groupId/tasks/count${status != null ? '?status=$status' : ''}',
    );
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200)
      throw Exception('Failed to count tasks: ${res.body}');
    return (jsonDecode(res.body)['count'] as int);
  }

  /* ─────────────────────────────
     SUMMARY (GET /groups/:id/tasks/summary)
  ───────────────────────────── */
  static Future<Map<String, int>> getTaskSummary(String groupId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/groups/$groupId/tasks/summary'),
      headers: await _headers(),
    );
    if (res.statusCode != 200)
      throw Exception('Failed to fetch summary: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return {
      'total': data['total'] as int,
      'pending': data['pending'] as int,
      'in_progress': data['in_progress'] as int,
      'completed': data['completed'] as int,
    };
  }

  /* ─────────────────────────────
     TODAY (GET /tasks/today?date=yyyy-MM-dd)
  ───────────────────────────── */
  static Future<List<dynamic>> getTasksForToday({DateTime? date}) async {
    final qp = <String, String>{};
    if (date != null) {
      final d = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      qp['date'] = d;
    }
    final uri = Uri.parse('$_baseUrl/tasks/today').replace(queryParameters: qp);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200)
      throw Exception("Failed to fetch today's tasks: ${res.body}");

    final data = jsonDecode(res.body);
    return (data is List) ? data : [data];
  }

  static Future<List<dynamic>> getAssignedTasks({
    String? status,
    String? groupId,
    DateTime? deadline,
    DateTime? create,
  }) async {
    final queryParams = <String, String>{};

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (groupId != null && groupId.isNotEmpty) {
      queryParams['groupId'] = groupId;
    }
    if (deadline != null) {
      final formattedDeadline =
          "${deadline.year.toString().padLeft(4, '0')}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}";
      queryParams['deadline'] = formattedDeadline;
    }
    if (create != null) {
      final formattedCreate =
          "${create.year.toString().padLeft(4, '0')}-${create.month.toString().padLeft(2, '0')}-${create.day.toString().padLeft(2, '0')}";
      queryParams['create'] = formattedCreate;
    }

    final uri = Uri.parse('$_baseUrl/tasks/assigned')
        .replace(queryParameters: queryParams);

    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch assigned tasks: ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data is List) {
      return data;
    } else {
      return [data]; // fallback nếu server trả về object thay vì mảng
    }
  }
}
