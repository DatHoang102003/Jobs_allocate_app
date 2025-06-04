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
      // Gọi API đã lọc sẵn các nhóm bị soft-delete
      final rawAdmin = await GroupService.getAdminGroups();
      final rawMember = await GroupService.getMemberGroups();

      // Chuyển dữ liệu thành đối tượng Group
      final adminGroups = rawAdmin.map((e) => Group.fromJson(e)).toList();
      final memberGroups = rawMember.map((e) => Group.fromJson(e)).toList();

      // Dùng Map để loại bỏ nhóm trùng lặp theo ID
      final allGroupsMap = <String, Group>{};

      for (final group in [...adminGroups, ...memberGroups]) {
        allGroupsMap[group.id] = group;
      }

      // Cập nhật danh sách admin/member groups từ map
      _adminGroups
        ..clear()
        ..addAll(allGroupsMap.values
            .where((g) => rawAdmin.any((e) => e['id'] == g.id)));

      _memberGroups
        ..clear()
        ..addAll(allGroupsMap.values
            .where((g) => rawMember.any((e) => e['id'] == g.id)));

      // Thiết lập nhóm hiện tại nếu chưa có
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
// Update a group's details
// ───────────────────────────────────────────────
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final data = await GroupService.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        isPublic: isPublic,
      );
      final updatedGroup = Group.fromJson(data);

      // Update the group in adminGroups or memberGroups
      bool updated = false;
      for (var list in [_adminGroups, _memberGroups]) {
        final index = list.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          list[index] = updatedGroup;
          updated = true;
        }
      }

      // Update current group if it matches the updated group
      if (_current?.id == groupId) {
        _current = updatedGroup;
      }

      if (updated) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('updateGroup error: $e');
      rethrow;
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
  // Soft-delete a group
  // ───────────────────────────────────────────────
  Future<void> deleteGroup(String groupId) async {
    try {
      await GroupService.deleteGroup(groupId);
      // Remove from admin or member groups
      bool removed = false;
      for (var list in [_adminGroups, _memberGroups]) {
        final i = list.indexWhere((g) => g.id == groupId);
        if (i != -1) {
          list.removeAt(i);
          removed = true;
        }
      }
      // Clear current group if it was the deleted one
      if (_current?.id == groupId) {
        _current = _adminGroups.isNotEmpty
            ? _adminGroups.first
            : (_memberGroups.isNotEmpty ? _memberGroups.first : null);
      }
      if (removed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('deleteGroup error: $e');
      rethrow;
    }
  }

// ───────────────────────────────────────────────
// Restore a soft-deleted group (Undo delete)
// ───────────────────────────────────────────────
  Future<void> restoreGroup(Map<String, dynamic> groupData) async {
    try {
      final groupId = groupData['id'];
      final isAdmin = groupData['isAdmin'] == true;

      // Gửi yêu cầu khôi phục lên server
      final restored = await GroupService.restoreGroup(groupId);

      final restoredGroup = Group.fromJson(restored);

      // Thêm lại vào danh sách đúng (admin/member)
      if (isAdmin) {
        _adminGroups.add(restoredGroup);
      } else {
        _memberGroups.add(restoredGroup);
      }

      // Nếu không có group nào được chọn thì chọn group này làm mặc định
      _current ??= restoredGroup;

      notifyListeners();
    } catch (e) {
      debugPrint('restoreGroup error: $e');
      rethrow;
    }
  }
}
