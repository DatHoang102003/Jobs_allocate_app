import 'package:flutter/material.dart';
import '../../services/join_service.dart';

class JoinManager with ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<dynamic> joinRequests = [];

  /// Fetch danh sách các join request đã gửi bởi user hiện tại
  Future<void> fetchJoinRequests() async {
    _setLoading(true);
    try {
      final data = await JoinService.listJoinRequests();
      joinRequests = data;
      error = null;
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  /// Gửi yêu cầu tham gia nhóm
  Future<void> sendJoinRequest(String groupId) async {
    _setLoading(true);
    try {
      await JoinService.sendJoinRequest(groupId);
      await fetchJoinRequests(); // Tải lại danh sách sau khi gửi
      error = null;
    } catch (e) {
      error = e.toString();
    }
    _setLoading(false);
  }

  /// Duyệt yêu cầu tham gia nhóm (chỉ dành cho chủ nhóm)
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

  /// Từ chối yêu cầu tham gia nhóm (chỉ dành cho chủ nhóm)
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

  /// Hàm helper cập nhật loading và thông báo cho UI
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
