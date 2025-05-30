import 'package:flutter/material.dart';

import '../../models/groups.dart';
import '../../services/group_service.dart';

class GroupsProvider with ChangeNotifier {
  final List<Group> _adminGroups = [];
  final List<Group> _memberGroups = [];
  bool _loading = false;
  Group? _current;

  List<Group> get adminGroups => List.unmodifiable(_adminGroups);
  List<Group> get memberGroups => List.unmodifiable(_memberGroups);
  bool get isLoading => _loading;
  Group? get currentGroup => _current;

  Future<void> fetchGroups() async {
    _loading = true;
    notifyListeners();

    try {
      final rawAdmin = await GroupService.getAdminGroups();
      final rawMember = await GroupService.getMemberGroups();

      _adminGroups
        ..clear()
        ..addAll(rawAdmin.map((e) => Group.fromJson(e)));
      _memberGroups
        ..clear()
        ..addAll(rawMember.map((e) => Group.fromJson(e)));

      _current ??= _adminGroups.isNotEmpty
          ? _adminGroups.first
          : (_memberGroups.isNotEmpty ? _memberGroups.first : null);
    } catch (e) {
      debugPrint('fetchGroups error: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setCurrent(Group g) {
    _current = g;
    notifyListeners();
  }

  void updateGroup(Group updated) {
    bool updatedAny = false;

    for (var list in [_adminGroups, _memberGroups]) {
      final i = list.indexWhere((g) => g.id == updated.id);
      if (i != -1) {
        list[i] = updated;
        updatedAny = true;
      }
    }

    if (updatedAny && _current?.id == updated.id) {
      _current = updated;
      notifyListeners();
    }
  }
}
