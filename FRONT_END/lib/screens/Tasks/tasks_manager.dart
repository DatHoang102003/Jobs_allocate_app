import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '/services/task_service.dart';

class TasksProvider with ChangeNotifier {
  /* ───────────────────────────────
     STATE
  ─────────────────────────────── */
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = false;

  List<Map<String, dynamic>> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _loading;

  /* ───────────────────────────────
     INTERNAL – safe notifier
  ─────────────────────────────── */
  void _safeNotify() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    _safeNotify();
  }

  /* ───────────────────────────────
     PUBLIC API
  ─────────────────────────────── */

  /// Tải danh sách task theo group (hỗ trợ lọc và phân trang)
  Future<void> loadTasksByGroup(
    String groupId, {
    String? status,
    String? assignee,
    int? page,
    int? perPage,
  }) async {
    _setLoading(true);

    try {
      final fetched = await TaskService.getTasks(
        groupId,
        status: status,
        assignee: assignee,
        page: page,
        perPage: perPage,
      );
      _tasks = List<Map<String, dynamic>>.from(fetched);
      _safeNotify(); // update list after fetch
    } catch (e) {
      debugPrint('loadTasksByGroup error: $e');
      _tasks = [];
      _safeNotify();
    } finally {
      _setLoading(false);
    }
  }

  /// Tạo task mới và thêm vào danh sách
  Future<void> createTask(
    String groupId, {
    required String title,
    String? description,
    String? assignee,
    DateTime? deadline,
  }) async {
    try {
      final newTask = await TaskService.createTask(
        groupId,
        title: title,
        description: description,
        assignee: assignee,
        deadline: deadline,
      );
      _tasks.insert(0, newTask);
      _safeNotify();
    } catch (e) {
      debugPrint('createTask error: $e');
      rethrow;
    }
  }

  /// Cập nhật trạng thái của một task
  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      final updated = await TaskService.updateTaskStatus(taskId, status);
      final index = _tasks.indexWhere((t) => t['id'] == taskId);
      if (index != -1) {
        _tasks[index] = updated;
        _safeNotify();
      }
    } catch (e) {
      debugPrint('updateTaskStatus error: $e');
      rethrow;
    }
  }

  /// Xoá task khỏi danh sách
  Future<void> deleteTask(String taskId) async {
    try {
      final success = await TaskService.deleteTask(taskId);
      if (success) {
        _tasks.removeWhere((t) => t['id'] == taskId);
        _safeNotify();
      }
    } catch (e) {
      debugPrint('deleteTask error: $e');
      rethrow;
    }
  }

  /// Xoá toàn bộ task trong provider (dọn dẹp khi đổi group)
  void clearTasks() {
    _tasks = [];
    _safeNotify();
  }

  /// Lấy danh sách task cho ngày hôm nay hoặc ngày cụ thể (không theo group)
  Future<void> loadTasksForToday({DateTime? date}) async {
    _setLoading(true);

    try {
      final fetched = await TaskService.getTasksForToday(date: date);
      _tasks = List<Map<String, dynamic>>.from(fetched);
      _safeNotify();
    } catch (e) {
      debugPrint('loadTasksForToday error: $e');
      _tasks = [];
      _safeNotify();
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy danh sách task được giao cho người dùng hiện tại
  /// Optional: lọc theo status, groupId, deadline (định dạng yyyy-MM-dd)
  static Future<List<dynamic>> fetchAssignedTasks({
    String? status,
    String? groupId,
    DateTime? deadline,
    DateTime? create,
  }) async {
    try {
      return await TaskService.getAssignedTasks(
        status: status,
        groupId: groupId,
        deadline: deadline,
        create: create,
      );
    } catch (e) {
      print('TaskManager.fetchAssignedTasks error: $e');
      rethrow;
    }
  }

  /// Đếm số lượng task theo group (có tùy chọn lọc theo status)
  Future<int> countTasks(String groupId, {String? status}) async {
    try {
      final count = await TaskService.countTasks(groupId, status: status);
      return count;
    } catch (e) {
      debugPrint('countTasks error: $e');
      rethrow;
    }
  }
}
