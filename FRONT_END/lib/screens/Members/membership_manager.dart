import 'package:flutter/material.dart';
import '../../services/membership_service.dart';

class MemberManager extends ChangeNotifier {
  List<dynamic> _members = [];
  List<dynamic> get members => _members;
  final Map<String, List<dynamic>> _membersByGroup = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _myMembershipId;
  String? get myMembershipId => _myMembershipId;

  // Set loading and notify
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set members and optionally detect my membershipId
  void _setMembers(String groupId, List<dynamic> fetched, {String? myUserId}) {
    _membersByGroup[groupId] = fetched;
    if (myUserId != null) {
      final myM = fetched.firstWhere(
        (m) => m['user'] == myUserId,
        orElse: () => null,
      );
      _myMembershipId = myM != null ? myM['id'] : null;
    } else {
      _myMembershipId = null;
    }
    notifyListeners();
  }

  /// Fetch members of a specific group and cache under that groupId
  Future<void> fetchMembers(String groupId, {String? myUserId}) async {
    _setLoading(true);
    try {
      final fetched = await MembershipService.listMembersOfGroup(groupId);
      _setMembers(groupId, fetched, myUserId: myUserId);
    } catch (e) {
      debugPrint('❌ Failed to fetch members: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Đồng bộ: trả về list members đã fetch (hoặc empty nếu chưa fetch)
  List<dynamic> membersOfGroup(String groupId) {
    return _membersByGroup[groupId] ?? [];
  }

  /// Clear cache toàn bộ hoặc chỉ 1 group
  void clearMembers([String? groupId]) {
    if (groupId != null) {
      _membersByGroup.remove(groupId);
    } else {
      _membersByGroup.clear();
    }
    _myMembershipId = null;
    notifyListeners();
  }

  /// Leave the group (giữ nguyên)
  Future<void> leaveGroup(String membershipId) async {
    _setLoading(true);
    try {
      await MembershipService.leaveGroup(membershipId);
      clearMembers(); // hoặc clearMembers(groupId) nếu biết
    } catch (e) {
      debugPrint('❌ Failed to leave group: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if a specific user is a member of the group
  bool isUserMember(String userId) {
    return _members.any((m) => m['user'] == userId);
  }

  /// Search members in the group
  Future<List<dynamic>> searchMembers(String groupId, String keyword) async {
    try {
      return await MembershipService.searchMembersInGroup(groupId, keyword);
    } catch (e) {
      debugPrint('❌ Failed to search members: $e');
      return [];
    }
  }
}
