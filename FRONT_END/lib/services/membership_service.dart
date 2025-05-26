import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MembershipService {
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
     List all memberships across my groups
  ------------------------------------------------- */
  static Future<List<dynamic>> listMyGroupMembers() async {
    final res = await http.get(
      Uri.parse('$_base/memberships'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  /* -------------------------------------------------
     List members of a specific group
  ------------------------------------------------- */
  static Future<List<dynamic>> listMembersOfGroup(String groupId) async {
    final res = await http.get(
      Uri.parse('$_base/groups/$groupId/members'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  /* -------------------------------------------------
     Leave a group (delete my own membership)
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> leaveGroup(String membershipId) async {
    final res = await http.delete(
      Uri.parse('$_base/memberships/$membershipId'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  /* -------------------------------------------------
     Owner removes a member
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> removeMember(
      String groupId, String membershipId) async {
    final res = await http.delete(
      Uri.parse('$_base/groups/$groupId/members/$membershipId'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  /* -------------------------------------------------
     Owner updates a member's role
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> updateMemberRole(
      String membershipId, String role) async {
    final body = jsonEncode({'role': role});
    final res = await http.patch(
      Uri.parse('$_base/memberships/$membershipId/role'),
      headers: await _headers(),
      body: body,
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }
}
