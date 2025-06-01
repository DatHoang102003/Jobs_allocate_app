import 'package:flutter/material.dart';
import '/services/task_service.dart';

class TasksProvider with ChangeNotifier {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = false;

  List<Map<String, dynamic>> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _loading;

  /// Tải danh sách task theo group (hỗ trợ lọc và phân trang)
  Future<void> loadTasksByGroup(
    String groupId, {
    String? status,
    String? assignee,
    int? page,
    int? perPage,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final fetched = await TaskService.getTasks(
        groupId,
        status: status,
        assignee: assignee,
        page: page,
        perPage: perPage,
      );
      _tasks = List<Map<String, dynamic>>.from(fetched);
    } catch (e) {
      print('loadTasksByGroup error: $e');
      _tasks = [];
    } finally {
      _loading = false;
      notifyListeners();
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
      _tasks.insert(0, newTask); // chèn lên đầu danh sách
      notifyListeners();
    } catch (e) {
      print('createTask error: $e');
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
        notifyListeners();
      }
    } catch (e) {
      print('updateTaskStatus error: $e');
      rethrow;
    }
  }

  /// Xoá task khỏi danh sách
  Future<void> deleteTask(String taskId) async {
    try {
      final success = await TaskService.deleteTask(taskId);
      if (success) {
        _tasks.removeWhere((t) => t['id'] == taskId);
        notifyListeners();
      }
    } catch (e) {
      print('deleteTask error: $e');
      rethrow;
    }
  }

  /// Xoá toàn bộ task trong provider (dọn dẹp khi đổi group)
  void clearTasks() {
    _tasks = [];
    notifyListeners();
  }

  /// Lấy danh sách task cho ngày hôm nay hoặc ngày cụ thể (không theo group)
  Future<void> loadTasksForToday({DateTime? date}) async {
    _loading = true;
    notifyListeners();

    try {
      final fetched = await TaskService.getTasksForToday(date: date);
      _tasks = List<Map<String, dynamic>>.from(fetched);
    } catch (e) {
      print('loadTasksForToday error: $e');
      _tasks = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
