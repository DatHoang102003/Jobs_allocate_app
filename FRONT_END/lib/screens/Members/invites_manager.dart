import 'package:flutter/foundation.dart';
import '../../services/invite_service.dart';

class InviteManager extends ChangeNotifier {
  final Map<String, List<dynamic>> _invitesByGroup = {};
  bool _loading = false;

  bool get isLoading => _loading;
  List<dynamic> invitesOf(String groupId) =>
      List.unmodifiable(_invitesByGroup[groupId] ?? []);

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> fetchInvites(String groupId) async {
    _setLoading(true);
    try {
      final all = await InviteService.listMyInvites();
      _invitesByGroup[groupId] = all
          .where((i) => i['group'] == groupId && i['status'] == 'pending')
          .toList();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendInvite(String groupId, String userId) async {
    _setLoading(true);
    try {
      await InviteService.sendInviteRequest(groupId, userId);
      await fetchInvites(groupId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelInvite(String groupId, String inviteId) async {
    _setLoading(true);
    try {
      await InviteService.rejectInvite(inviteId);
      _invitesByGroup[groupId]?.removeWhere((i) => i['id'] == inviteId);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}
