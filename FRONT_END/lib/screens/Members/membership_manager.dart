import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/membership_service.dart';

class MemberManager extends ChangeNotifier {
  /* ─────────────────────────────────────────────
     STATE
  ───────────────────────────────────────────── */
  List<dynamic> _members = [];
  List<dynamic> get members => _members;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _myMembershipId;
  String? get myMembershipId => _myMembershipId;

  /* ─────────────────────────────────────────────
     INTERNAL: safe notifier
  ───────────────────────────────────────────── */
  void _safeNotify() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotify();
  }

  /* ─────────────────────────────────────────────
     PUBLIC API
  ───────────────────────────────────────────── */

  /// Fetch all members of a group and cache my membership ID (if any).
  Future<void> fetchMembers(String groupId, {String? myUserId}) async {
    _setLoading(true);
    try {
      final fetched = await MembershipService.listMembersOfGroup(groupId);
      _members = fetched;

      // If current user provided, figure out their membership row (if any)
      if (myUserId != null) {
        final found = fetched.firstWhere(
          (m) => m['user'] == myUserId,
          orElse: () => null,
        );
        _myMembershipId = found != null ? found['id'] : null;
      }

      _safeNotify(); // ← post-frame notify
    } catch (e) {
      debugPrint('Failed to fetch members: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Is [userId] already a member of the current cache?
  bool isUserMember(String userId) => _members.any((m) => m['user'] == userId);

  /// Current user leaves the group.
  Future<void> leaveGroup() async {
    if (_myMembershipId == null) return;

    try {
      await MembershipService.leaveGroup(_myMembershipId!);
      _members.removeWhere((m) => m['id'] == _myMembershipId);
      _myMembershipId = null;
      _safeNotify();
    } catch (e) {
      debugPrint('Failed to leave group: $e');
      rethrow;
    }
  }

  /// Keyword search inside a group.
  Future<List<dynamic>> searchMembers(String groupId, String keyword) async {
    try {
      return await MembershipService.searchMembersInGroup(groupId, keyword);
    } catch (e) {
      debugPrint('Failed to search members: $e');
      return [];
    }
  }

  /// Clear cached list (e.g. on logout).
  void clearMembers() {
    _members = [];
    _myMembershipId = null;
    _safeNotify();
  }
}
