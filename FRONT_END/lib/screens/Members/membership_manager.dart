import 'package:flutter/material.dart';
import '../../services/membership_service.dart';

class MemberManager extends ChangeNotifier {
  // Cache of fetched members per group
  final Map<String, List<Map<String, dynamic>>> _membersByGroup = {};

  // Current group's member list
  List<Map<String, dynamic>> _members = [];

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
    List<Map<String, dynamic>> fetched, {
    String? myUserId,
  }) {
    _membersByGroup[groupId] = fetched;
    _members = fetched;

    if (myUserId != null) {
      final mine = fetched.firstWhere(
        (m) => m['user'] == myUserId,
        orElse: () => {},
      );
      _myMembershipId = mine['id'] as String?;
    } else {
      _myMembershipId = null;
    }
  }

  /* ───────────────────── Public API ───────────────────── */

  /// Get cached members for [groupId], or empty if never fetched.
  List<Map<String, dynamic>> membersOfGroup(String groupId) =>
      _membersByGroup[groupId] ?? [];

  /// Fetch members for [groupId] once; caches and notifies listeners.
  Future<void> fetchMembers(String groupId, {String? myUserId}) async {
    // If already cached, schedule a notify after current build to avoid calling during build
    if (_membersByGroup.containsKey(groupId)) {
      Future.microtask(() => notifyListeners());
      return;
    }

    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      // Fetch raw list and cast to desired type
      final raw = await MembershipService.listMembersOfGroup(groupId);
      final fetched = (raw as List).cast<Map<String, dynamic>>();

      // Optionally remove current user
      if (myUserId != null) {
        fetched.removeWhere((m) => m['user'] == myUserId);
      }

      // Cache and compute myMembershipId
      _cache(groupId, fetched, myUserId: myUserId);
    } catch (e) {
      debugPrint('❌ Failed to fetch members: $e');
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Leave the group identified by [groupId], remove cache and notify.
  Future<void> leaveGroup(String groupId) async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

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
      Future.microtask(() => notifyListeners());
    }
  }

  /// Returns true if [userId] is in the current group's members.
  bool isUserMember(String userId) => _members.any((m) => m['user'] == userId);

  /// Server-side search of members in [groupId] matching [keyword].
  Future<List<Map<String, dynamic>>> searchMembers(
      String groupId, String keyword) async {
    try {
      final raw =
          await MembershipService.searchMembersInGroup(groupId, keyword);
      return (raw as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to search members: $e');
      return [];
    }
  }
}
