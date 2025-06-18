import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  static const _baseUrl = 'http://10.0.2.2:3000';

  /// Helper để thêm header xác thực
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Lấy thông tin user từ endpoint /users/:userId
  static Future<Map<String, dynamic>> _fetchUserInfo(String userId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch user info: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /* ─────────────────────────────
     CREATE (POST /groups/:groupId/tasks)
     - assignees: List<String>?
  ───────────────────────────── */
  static Future<Map<String, dynamic>> createTask(
    String groupId, {
    required String title,
    String? description,
    List<String>? assignees,
    DateTime? deadline,
  }) async {
    final body = <String, dynamic>{'title': title};
    if (description?.isNotEmpty ?? false) {
      body['description'] = description;
    }
    if (assignees != null && assignees.isNotEmpty) {
      body['assignee'] = assignees;
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

  /* ─────────────────────────────
     LIST (GET /groups/:groupId/tasks)
     - Có phân trang và hỗ trợ expand
  ───────────────────────────── */
  static Future<List<dynamic>> getTasks(
    String groupId, {
    String? status,
    String? assignee,
    int? page,
    int? perPage,
    String? expand,
  }) async {
    final qp = <String, String>{};
    if (status != null) qp['status'] = status;
    if (assignee != null) qp['assignee'] = assignee;
    if (page != null) qp['page'] = '$page';
    if (perPage != null) qp['perPage'] = '$perPage';
    if (expand != null) qp['expand'] = expand;

    final uri = Uri.parse('$_baseUrl/groups/$groupId/tasks')
        .replace(queryParameters: qp);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load tasks: ${res.body}');
    }

    final data = jsonDecode(res.body);
    return (data is List) ? data : data['items'];
  }

  /* ─────────────────────────────
     PATCH /tasks/:taskId/status
  ───────────────────────────── */
  static Future<Map<String, dynamic>> updateTaskStatus(
      String taskId, String status) async {
    const allowed = ['pending', 'in_progress', 'completed'];
    if (!allowed.contains(status)) {
      throw Exception('Invalid status. Allowed: $allowed');
    }

    final res = await http.patch(
      Uri.parse('$_baseUrl/tasks/$taskId/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update status: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /* ─────────────────────────────
     PATCH /tasks/:taskId
  ───────────────────────────── */
  static Future<Map<String, dynamic>> updateTask(
    String taskId, {
    String? title,
    String? description,
    DateTime? deadline,
    List<String>? assignees,
  }) async {
    final body = <String, dynamic>{};
    if (title?.isNotEmpty ?? false) body['title'] = title;
    if (description != null) body['description'] = description;
    if (deadline != null) body['deadline'] = deadline.toIso8601String();
    if (assignees != null && assignees.isNotEmpty) {
      body['assignee'] = assignees;
    }

    final res = await http.patch(
      Uri.parse('$_baseUrl/tasks/$taskId'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update task: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /* ─────────────────────────────
     DELETE /tasks/:taskId
  ───────────────────────────── */
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

  /* ─────────────────────────────
     COUNT /groups/:groupId/tasks/count
  ───────────────────────────── */
  static Future<int> countTasks(String groupId, {String? status}) async {
    final uri = Uri.parse('$_baseUrl/groups/$groupId/tasks/count')
        .replace(queryParameters: status != null ? {'status': status} : null);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to count tasks: ${res.body}');
    }
    return (jsonDecode(res.body)['count'] as int);
  }

  /* ─────────────────────────────
     GET /tasks/filter
     - Hỗ trợ expand
  ───────────────────────────── */
  static Future<List<dynamic>> getTasksByFilter({
    required String filterBy,
    String? date,
    String? status,
    String? expand,
  }) async {
    if (!['created', 'deadline', 'status'].contains(filterBy)) {
      throw Exception('filterBy must be one of created, deadline, status');
    }
    if (filterBy == 'status' && status == null) {
      throw Exception('Status is required when filterBy is "status"');
    }

    final qp = <String, String>{'filterBy': filterBy};
    if (date != null) qp['date'] = date;
    if (status != null) qp['status'] = status;
    if (expand != null) qp['expand'] = expand;

    final uri =
        Uri.parse('$_baseUrl/tasks/filter').replace(queryParameters: qp);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch filtered tasks: ${res.body}');
    }
    final data = jsonDecode(res.body);
    return (data is List) ? data : [data];
  }

  /* ─────────────────────────────
     GET /tasks/:taskId/assignee
     - Lấy thông tin assignee với avatarUrl và name
  ───────────────────────────── */
  static Future<List<Map<String, dynamic>>> getAssigneeInfo(
      String taskId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/tasks/$taskId?expand=assignee.user'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch task details: ${res.body}');
    }

    final task = jsonDecode(res.body) as Map<String, dynamic>;
    final assignees = List<String>.from(task['assignee'] ?? []);
    final assigneeInfo = <Map<String, dynamic>>[];

    for (var userId in assignees) {
      try {
        // Giả sử API trả về expand.user, nếu không thì gọi /users/:userId
        final userData = task['expand']?['assignee']?.firstWhere(
              (u) => u['id'] == userId,
              orElse: () => null,
            ) ??
            await _fetchUserInfo(userId);
        assigneeInfo.add({
          'id': userId,
          'avatarUrl': userData['avatarUrl'] ?? '',
          'name': userData['name'] ?? 'Unknown User',
        });
      } catch (e) {
        assigneeInfo.add({
          'id': userId,
          'avatarUrl': '',
          'name': 'Unknown User',
        });
      }
    }
    return assigneeInfo;
  }

  /* ─────────────────────────────
     GET /tasks/:taskId
     - Hỗ trợ expand
  ───────────────────────────── */
  static Future<Map<String, dynamic>> getTaskDetail(String taskId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/tasks/$taskId?expand=assignee.user'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch task detail: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
