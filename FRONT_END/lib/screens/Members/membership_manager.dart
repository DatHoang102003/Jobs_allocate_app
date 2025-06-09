import 'package:flutter/material.dart';
import '../../services/membership_service.dart';

class MemberManager extends ChangeNotifier {
  // Cache of fetched members per group
  final Map<String, List<dynamic>> _membersByGroup = {};

  // Current group’s members
  List<dynamic> _members = [];

  // My membership record ID within the current group
  String? _myMembershipId;

  // Loading state
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  String? get myMembershipId => _myMembershipId;

  /* ───────────────────────── Helpers ───────────────────────── */

  /// Cache fetched members for [groupId] and compute myMembershipId if [myUserId] provided.
  void _cache(
    String groupId,
    List<dynamic> fetched, {
    String? myUserId,
  }) {
    _membersByGroup[groupId] = fetched;
    _members = fetched;

    if (myUserId != null) {
      final mine = fetched.firstWhere(
        (m) => m['user'] == myUserId,
        orElse: () => null,
      );
      _myMembershipId = mine != null ? mine['id'] : null;
    } else {
      _myMembershipId = null;
    }
  }

  /* ───────────────────── Public API ───────────────────── */

  /// Get cached members for [groupId], or empty if never fetched.
  List<dynamic> membersOfGroup(String groupId) =>
      _membersByGroup[groupId] ?? [];

  /// Fetch members for [groupId] once; caches and notifies listeners.
  Future<void> fetchMembers(String groupId, {String? myUserId}) async {
    // If already cached, sync current list and return
    if (_membersByGroup.containsKey(groupId)) {
      _members = _membersByGroup[groupId]!;
      return;
    }

    _isLoading = true;
    try {
      final fetched = await MembershipService.listMembersOfGroup(groupId);
      _cache(groupId, fetched, myUserId: myUserId);
    } catch (e) {
      debugPrint('❌ Failed to fetch members: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Leave the group identified by [groupId], remove cache and notify.
  Future<void> leaveGroup(String groupId) async {
    _isLoading = true;
    try {
      await MembershipService.leaveGroupByGroup(groupId);
      _membersByGroup.remove(groupId);
      _members = [];
      _myMembershipId = null;
    } catch (e) {
      debugPrint('❌ Failed to leave group: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns true if [userId] is in the _members list of the current group.
  bool isUserMember(String userId) => _members.any((m) => m['user'] == userId);

  /// Server-side search of members in [groupId] matching [keyword].
  Future<List<dynamic>> searchMembers(String groupId, String keyword) async {
    try {
      return await MembershipService.searchMembersInGroup(groupId, keyword);
    } catch (e) {
      debugPrint('❌ Failed to search members: $e');
      return [];
    }
  }
}
