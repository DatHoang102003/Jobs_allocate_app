import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JoinService {
  static const _base = 'http://10.0.2.2:3000';

  /* -------------------------------------------------
     Helpers
  ------------------------------------------------- */
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /* -------------------------------------------------
     Send a request to join a group
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> sendJoinRequest(String groupId) async {
    final body = jsonEncode({
      'status': 'pending',
    });
    final res = await http.post(
      Uri.parse('$_base/groups/$groupId/join'),
      headers: await _headers(),
      body: body,
    );
    if (res.statusCode != 201) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  /* -------------------------------------------------
     List all join requests sent by the user
  ------------------------------------------------- */
  static Future<List<dynamic>> listJoinRequests(
      {int page = 1, int perPage = 500}) async {
    final queryParams = {
      if (page > 0 && perPage > 0) 'page': page.toString(),
      if (page > 0 && perPage > 0) 'perPage': perPage.toString(),
    };
    final uri =
        Uri.parse('$_base/join_requests').replace(queryParameters: queryParams);
    final res = await http.get(
      uri,
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    final data = jsonDecode(res.body);
    return page > 0 && perPage > 0 ? (data['items'] ?? data) : data;
  }

  /* -------------------------------------------------
     Approve a user's join request (group owner only)
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> approveJoinRequest(String jrId) async {
    final res = await http.post(
      Uri.parse('$_base/join_requests/$jrId/approve'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  /* -------------------------------------------------
     Reject a join request (group owner only)
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> rejectJoinRequest(String jrId) async {
    final res = await http.post(
      Uri.parse('$_base/join_requests/$jrId/reject'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }
}
