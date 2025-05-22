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
    final res = await http.get(Uri.parse('$_base/groups/$id'),
        headers: await _headers());
    if (res.statusCode != 200) throw Exception(res.body);

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    // Build avatarUrl for each member so UI can use it directly
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    for (final m in data['members'] as List) {
      final u = m['expand']['user'];
      final file = u['avatar'];
      if (file != null && file != '') {
        u['avatarUrl'] =
            'http://10.0.2.2:8090/api/files/_pb_users_auth_/${u['id']}/$file?token=$token';
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
}
