import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroupService {
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
     List all groups I own / belong to
  ------------------------------------------------- */
  static Future<List<dynamic>> getGroups() async {
    final res =
        await http.get(Uri.parse('$_base/groups'), headers: await _headers());
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  /* -------------------------------------------------
     Get a single group's full detail (group + members + tasks)
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> getGroupDetail(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final res = await http.get(
      Uri.parse('$_base/groups/$id'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    // ── Build avatarUrl for each member ──
    final members = data['members'] as List<dynamic>?;
    if (members != null) {
      for (final m in members) {
        // Safely grab expand/user
        final expand = m['expand'] as Map<String, dynamic>?;
        final u = expand?['user'] as Map<String, dynamic>?;

        if (u != null) {
          final fileId = u['avatar'] as String?;
          if (fileId != null && fileId.isNotEmpty) {
            u['avatarUrl'] = 'http://10.0.2.2:8090/api/files/_pb_users_auth_/'
                '${u['id']}/$fileId?token=$token';
          } else {
            u['avatarUrl'] = null;
          }
        }
      }
    }

    return data;
  }

  /* -------------------------------------------------
     Update basic group info (name / description)
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> updateGroup(String id,
      {required String name, required String description}) async {
    final body = jsonEncode({'name': name, 'description': description});
    final res = await http.patch(Uri.parse('$_base/groups/$id'),
        headers: await _headers(), body: body);

    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }

  /* -------------------------------------------------
   Create a new group
------------------------------------------------- */
  static Future<Map<String, dynamic>> createGroup({
    required String name,
    String description = '',
    bool isPublic = true,
  }) async {
    final body = jsonEncode({
      'name': name,
      'description': description,
      'isPublic': isPublic,
    });

    final res = await http.post(
      Uri.parse('$_base/groups'),
      headers: await _headers(),
      body: body,
    );

    if (res.statusCode != 201) throw Exception(res.body);

    final data = jsonDecode(res.body);
    print("✅ Created group: $data");

    return data;
  }

  /* -------------------------------------------------
   Search groups I own or am a member of by name
------------------------------------------------- */
  static Future<List<dynamic>> searchGroups(String keyword) async {
    if (keyword.trim().isEmpty) {
      throw Exception("Search keyword cannot be empty");
    }

    final encodedKeyword = Uri.encodeQueryComponent(keyword);
    final res = await http.get(
      Uri.parse('$_base/groups/search?q=$encodedKeyword'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['error'] ?? "Search failed");
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  /* -------------------------------------------------
     List groups where I'm an admin
  ------------------------------------------------- */
  static Future<List<dynamic>> getAdminGroups() async {
    final res = await http.get(
      Uri.parse('$_base/groups/admin'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception(
          jsonDecode(res.body)['error'] ?? 'Failed to load admin groups');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }

  /* -------------------------------------------------
     List groups where I'm a member (non-admin)
  ------------------------------------------------- */
  static Future<List<dynamic>> getMemberGroups() async {
    final res = await http.get(
      Uri.parse('$_base/groups/member'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception(
          jsonDecode(res.body)['error'] ?? 'Failed to load member groups');
    }

    return jsonDecode(res.body) as List<dynamic>;
  }
}
