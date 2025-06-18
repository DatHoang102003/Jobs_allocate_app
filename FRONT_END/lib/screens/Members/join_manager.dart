import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/join_service.dart';

class JoinManager with ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<dynamic> joinRequests = [];

  /* ─────────────────────────────────────────────
     PUBLIC HELPERS
  ───────────────────────────────────────────── */

  /// Returns `true` if I already have a *pending* request for this group.
  bool isPending(String groupId) => joinRequests
      .any((jr) => jr['group'] == groupId && jr['status'] == 'pending');

  /* ─────────────────────────────────────────────
     CRUD
  ───────────────────────────────────────────── */

  Future<void> fetchJoinRequests() async {
    _setLoading(true);
    try {
      joinRequests = await JoinService.listJoinRequests();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> sendJoinRequest(String groupId) async {
    _setLoading(true);
    try {
      await JoinService.sendJoinRequest(groupId);
      await fetchJoinRequests(); // refresh local cache
      error = null;
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> approveJoinRequest(String jrId) async {
    _setLoading(true);
    try {
      await JoinService.approveJoinRequest(jrId);
      await fetchJoinRequests();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> rejectJoinRequest(String jrId) async {
    _setLoading(true);
    try {
      await JoinService.rejectJoinRequest(jrId);
      await fetchJoinRequests();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  /* ─────────────────────────────────────────────
     INTERNAL
  ───────────────────────────────────────────── */
  void _setLoading(bool value) {
    isLoading = value;

    // notify only after the current frame is done
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }
}
