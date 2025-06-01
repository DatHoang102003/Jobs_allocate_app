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

  // ───────────────────────────────────────────────
  // Fetch all groups I own or belong to
  // ───────────────────────────────────────────────
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

  // ───────────────────────────────────────────────
  // Create a new group
  // ───────────────────────────────────────────────
  Future<void> createGroup({
    required String name,
    String description = '',
    bool isPublic = true,
  }) async {
    try {
      final data = await GroupService.createGroup(
        name: name,
        description: description,
        isPublic: isPublic,
      );
      final newGroup = Group.fromJson(data);
      _adminGroups.add(newGroup);
      _current ??= newGroup;
      notifyListeners();
    } catch (e) {
      debugPrint('createGroup error: $e');
      rethrow;
    }
  }

  // ───────────────────────────────────────────────
  // Update name / description of a group
  // ───────────────────────────────────────────────
  Future<void> updateGroupInfo({
    required String id,
    required String name,
    required String description,
  }) async {
    try {
      final data = await GroupService.updateGroup(id,
          name: name, description: description);
      final updated = Group.fromJson(data);
      updateGroup(updated);
    } catch (e) {
      debugPrint('updateGroupInfo error: $e');
      rethrow;
    }
  }

  // ───────────────────────────────────────────────
  // Search groups by name
  // ───────────────────────────────────────────────
  Future<List<Group>> searchGroups(String keyword) async {
    try {
      final results = await GroupService.searchGroups(keyword);
      return results.map((e) => Group.fromJson(e)).toList();
    } catch (e) {
      debugPrint('searchGroups error: $e');
      rethrow;
    }
  }

  // ───────────────────────────────────────────────
  // Fetch full detail of a group (including members, tasks)
  // ───────────────────────────────────────────────
  Future<Group> fetchGroupDetail(String groupId) async {
    try {
      final data = await GroupService.getGroupDetail(groupId);
      return Group.fromJson(data);
    } catch (e) {
      debugPrint('fetchGroupDetail error: $e');
      rethrow;
    }
  }

  // ───────────────────────────────────────────────
  // Refresh current group data
  // ───────────────────────────────────────────────
  Future<void> refreshCurrentGroup() async {
    if (_current == null) return;
    try {
      final updated = await fetchGroupDetail(_current!.id);
      updateGroup(updated);
    } catch (e) {
      debugPrint('refreshCurrentGroup error: $e');
    }
  }

  // ───────────────────────────────────────────────
  // Set current active group
  // ───────────────────────────────────────────────
  void setCurrent(Group g) {
    _current = g;
    notifyListeners();
  }

  // ───────────────────────────────────────────────
  // Update group in admin/member list
  // ───────────────────────────────────────────────
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
