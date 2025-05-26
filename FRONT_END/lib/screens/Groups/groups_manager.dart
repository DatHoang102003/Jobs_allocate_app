import 'package:flutter/material.dart';

import '../../models/groups.dart';
import '../../services/group_service.dart';

class GroupsProvider with ChangeNotifier {
  final List<Group> _groups = [];
  bool _loading = false;
  Group? _current;

  List<Group> get groups => List.unmodifiable(_groups);
  bool get isLoading => _loading;
  Group? get currentGroup => _current;

  /* ---------------- fetch all groups from backend ---------------- */
  Future<void> fetchGroups() async {
    _loading = true;
    notifyListeners();

    try {
      final raw = await GroupService.getGroups(); // REST → List<Map>
      _groups
        ..clear()
        ..addAll(raw.map((e) => Group.fromJson(e))); // convert to model
      _current ??= _groups.isNotEmpty ? _groups.first : null;
    } catch (e) {
      debugPrint('fetchGroups error: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /* ---------------- select a group (for edit / detail) ----------- */
  void setCurrent(Group g) {
    _current = g;
    notifyListeners();
  }

  /* ---------------- update a group after edit dialog ------------- */
  void updateGroup(Group updated) {
    final i = _groups.indexWhere((g) => g.id == updated.id);
    if (i != -1) {
      _groups[i] = updated;
      if (_current?.id == updated.id) _current = updated;
      notifyListeners();
    }
  }
}
