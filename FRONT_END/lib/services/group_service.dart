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
    final res = await http.get(
      Uri.parse('$_base/groups'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body) as List<dynamic>;
  }

  /* -------------------------------------------------
     Browse public groups
  ------------------------------------------------- */
  static Future<List<dynamic>> getPublicGroups() async {
    final res = await http.get(
      Uri.parse('$_base/groups/explore'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception(
          jsonDecode(res.body)['error'] ?? 'Failed to load public groups');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  /* -------------------------------------------------
     Get a single group's full detail (group + members + tasks)
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> getGroupDetail(String id) async {
    final res = await http.get(
      Uri.parse('$_base/groups/$id'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception(res.body);

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final members = data['members'] as List<dynamic>?;
    if (members != null) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      for (final m in members) {
        final expand = m['expand'] as Map<String, dynamic>?;
        final u = expand?['user'] as Map<String, dynamic>?;
        if (u != null) {
          final fileId = u['avatar'] as String?;
          if (fileId != null && fileId.isNotEmpty) {
            u['avatarUrl'] =
                'http://10.0.2.2:8090/api/files/_pb_users_auth_/${u['id']}/avatar/$fileId?token=$token';
          } else {
            u['avatarUrl'] = null;
          }
        }
      }
    }

    return data;
  }

  /* -------------------------------------------------
     Create a new group
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> createGroup({
    required String name,
    String description = '',
    bool isPublic = true,
    List<String>? members,
  }) async {
    final body = jsonEncode({
      'name': name,
      'description': description,
      'isPublic': isPublic,
      if (members != null && members.isNotEmpty) 'members': members,
    });

    final res = await http.post(
      Uri.parse('$_base/groups'),
      headers: await _headers(),
      body: body,
    );

    if (res.statusCode != 201) throw Exception(res.body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /* -------------------------------------------------
     Search groups I own or am a member of by name
  ------------------------------------------------- */
  static Future<List<dynamic>> searchGroups(String keyword) async {
    if (keyword.trim().isEmpty) {
      throw Exception('Search keyword cannot be empty');
    }
    final encoded = Uri.encodeQueryComponent(keyword);
    final res = await http.get(
      Uri.parse('$_base/groups/search?q=$encoded'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Search failed');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  /* -------------------------------------------------
     List groups where I'm an admin (excluding soft-deleted)
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
    return (jsonDecode(res.body) as List<dynamic>)
        .where((g) => g['deleted'] != true)
        .toList();
  }

  /* -------------------------------------------------
     List groups where I'm a member (excluding soft-deleted)
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
    return (jsonDecode(res.body) as List<dynamic>)
        .where((g) => g['deleted'] != true)
        .toList();
  }

  /* -------------------------------------------------
     Update a group
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> updateGroup({
    required String groupId,
    String? name,
    String? description,
    bool? isPublic,
    bool? deleted,
  }) async {
    final body = jsonEncode({
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isPublic != null) 'isPublic': isPublic,
      if (deleted != null) 'deleted': deleted,
    });
    final res = await http.patch(
      Uri.parse('$_base/groups/$groupId'),
      headers: await _headers(),
      body: body,
    );
    if (res.statusCode != 200) {
      throw Exception(
          jsonDecode(res.body)['error'] ?? 'Failed to update group');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /* -------------------------------------------------
     Soft-delete a group
  ------------------------------------------------- */
  static Future<void> deleteGroup(String groupId) async {
    final res = await http.delete(
      Uri.parse('$_base/groups/$groupId'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception(
          jsonDecode(res.body)['error'] ?? 'Failed to delete group');
    }
  }

  /* -------------------------------------------------
     Restore a soft-deleted group
  ------------------------------------------------- */
  static Future<Map<String, dynamic>> restoreGroup(String groupId) async {
    final res = await http.patch(
      Uri.parse('$_base/groups/$groupId/restore'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception(
          jsonDecode(res.body)['error'] ?? 'Failed to restore group');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
