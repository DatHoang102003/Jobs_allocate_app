import 'package:flutter/material.dart';
import '../../services/membership_service.dart';

class MemberManager extends ChangeNotifier {
  List<dynamic> _members = [];
  List<dynamic> get members => _members;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _myMembershipId;
  String? get myMembershipId => _myMembershipId;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Lấy danh sách thành viên của một group
  Future<void> fetchMembers(String groupId, {String? myUserId}) async {
    _setLoading(true);
    try {
      final fetched = await MembershipService.listMembersOfGroup(groupId);
      _members = fetched;

      // Nếu có userId hiện tại, tìm xem user có trong nhóm không
      if (myUserId != null) {
        final found = fetched.firstWhere(
          (m) => m['user'] == myUserId,
          orElse: () => null,
        );
        _myMembershipId = found != null ? found['id'] : null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch members: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Xác định người dùng đã tham gia nhóm chưa
  bool isUserMember(String userId) {
    return _members.any((m) => m['user'] == userId);
  }

  /// Rời nhóm
  Future<void> leaveGroup() async {
    if (_myMembershipId == null) return;
    try {
      await MembershipService.leaveGroup(_myMembershipId!);
      _members.removeWhere((m) => m['id'] == _myMembershipId);
      _myMembershipId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to leave group: $e');
      rethrow;
    }
  }

  /// Tìm kiếm thành viên trong nhóm theo từ khóa
  Future<List<dynamic>> searchMembers(String groupId, String keyword) async {
    try {
      return await MembershipService.searchMembersInGroup(groupId, keyword);
    } catch (e) {
      debugPrint('Failed to search members: $e');
      return [];
    }
  }

  /// Làm mới danh sách thành viên
  void clearMembers() {
    _members = [];
    _myMembershipId = null;
    notifyListeners();
  }
}
