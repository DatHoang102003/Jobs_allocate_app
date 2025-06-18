import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommentsService {
  static const _baseUrl = 'http://10.0.2.2:3000';

  /// Helper to get headers with auth token
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Create a new comment for a task (POST /tasks/:taskId/comments)
  /// Returns the created comment as Map<String, dynamic>.
  static Future<Map<String, dynamic>> createComment(
      String taskId, String contents,
      {List<String>? attachments}) async {
    final body = <String, dynamic>{'contents': contents};
    if (attachments != null && attachments.isNotEmpty) {
      body['attachments'] = attachments;
    }

    final res = await http.post(
      Uri.parse('$_baseUrl/tasks/$taskId/comments'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to create comment: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// List comments for a task (GET /tasks/:taskId/comments)
  /// Supports optional pagination via page and perPage.
  /// Returns either a List or a paginated response Map.
  static Future<dynamic> listComments(
    String taskId, {
    int? page,
    int? perPage,
  }) async {
    final qp = <String, String>{};
    if (page != null) qp['page'] = '$page';
    if (perPage != null) qp['perPage'] = '$perPage';

    final uri = Uri.parse('$_baseUrl/tasks/$taskId/comments')
        .replace(queryParameters: qp.isNotEmpty ? qp : null);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to list comments: ${res.body}');
    }
    final data = jsonDecode(res.body);
    return data;
  }

  /// Update a comment (PATCH /tasks/:taskId/comments/:commentId)
  /// Returns the updated comment as Map<String, dynamic>.
  static Future<Map<String, dynamic>> updateComment(
      String taskId, String commentId,
      {String? contents, List<String>? attachments}) async {
    final body = <String, dynamic>{};
    if (contents != null) body['contents'] = contents;
    if (attachments != null) body['attachments'] = attachments;

    if (body.isEmpty) {
      throw Exception('No valid fields to update');
    }

    final res = await http.patch(
      Uri.parse('$_baseUrl/tasks/$taskId/comments/$commentId'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update comment: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Soft-delete a comment (DELETE /tasks/:taskId/comments/:commentId)
  /// Returns true if deletion succeeded.
  static Future<bool> deleteComment(String taskId, String commentId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/tasks/$taskId/comments/$commentId'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to delete comment: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['ok'] == true;
  }
}
