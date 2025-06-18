import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InviteService {
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
     Admin invites a user to join a group
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> sendInviteRequest(
      String groupId, String userId) async {
    final body = jsonEncode({
      'userId': userId,
    });
    final res = await http.post(
      Uri.parse('$_base/groups/$groupId/invite'),
      headers: await _headers(),
      body: body,
    );
    if (res.statusCode != 201) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  /* -------------------------------------------------
     List all invites sent to the user
  ------------------------------------------------- */
  static Future<List<dynamic>> listMyInvites(
      {int page = 1, int perPage = 500}) async {
    final queryParams = {
      if (page > 0 && perPage > 0) 'page': page.toString(),
      if (page > 0 && perPage > 0) 'perPage': perPage.toString(),
    };
    final uri =
        Uri.parse('$_base/group_invites').replace(queryParameters: queryParams);
    final res = await http.get(
      uri,
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    final data = jsonDecode(res.body);
    return page > 0 && perPage > 0 ? (data['items'] ?? data) : data;
  }

  /* -------------------------------------------------
     Accept an invitation to join a group
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> acceptInvite(String inviteId) async {
    final res = await http.post(
      Uri.parse('$_base/group_invites/$inviteId/accept'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  /* -------------------------------------------------
     Reject an invitation to join a group
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> rejectInvite(String inviteId) async {
    final res = await http.post(
      Uri.parse('$_base/group_invites/$inviteId/reject'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }
}
