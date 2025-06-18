import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';

class TasksProvider with ChangeNotifier {
  /* ───────────────────────────────
     STATE
  ─────────────────────────────── */
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _todayTasks = [];
  List<Map<String, dynamic>> _deadlineTasks = [];
  List<Map<String, dynamic>> _assignedTasks = [];
  bool _loading = false;
  final Map<String, List<Map<String, dynamic>>> _assigneeCache = {};

  List<Map<String, dynamic>> get tasks => List.unmodifiable(_tasks);
  List<Map<String, dynamic>> get todayTasks => List.unmodifiable(_todayTasks);
  List<Map<String, dynamic>> get deadlineTasks =>
      List.unmodifiable(_deadlineTasks);
  List<Map<String, dynamic>> get assignedTasks =>
      List.unmodifiable(_assignedTasks);
  bool get isLoading => _loading;
  List<Map<String, dynamic>>? getCachedAssigneeInfo(String taskId) =>
      _assigneeCache[taskId];

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
        expand: 'assignee.user',
      );
      _tasks = List<Map<String, dynamic>>.from(fetched);
      await _prefetchAssigneeInfo(_tasks);
      _safeNotify();
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
    List<String>? assignees,
    DateTime? deadline,
  }) async {
    try {
      final newTask = await TaskService.createTask(
        groupId,
        title: title,
        description: description,
        assignees: assignees,
        deadline: deadline,
      );
      _tasks.insert(0, newTask);
      if (newTask['assignee'] != null) {
        await fetchAssigneeInfo(newTask['id'] as String);
      }
      await loadTasksByGroup(groupId);
      await loadTasks();
      await fetchAssignedTasks(status: 'all');
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
      String? groupId;
      if (index != -1) {
        groupId = _tasks[index]['groupId'] as String?;
        _tasks[index] = updated;
        if (updated['assignee'] != null &&
            !_assigneeCache.containsKey(taskId)) {
          await fetchAssigneeInfo(taskId);
        }
        if (groupId != null) {
          await loadTasksByGroup(groupId);
        }
        await loadTasks();
        await fetchAssignedTasks(status: status);
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
        final groupId = _tasks.firstWhere((t) => t['id'] == taskId,
            orElse: () => {})['groupId'] as String?;
        _tasks.removeWhere((t) => t['id'] == taskId);
        _assigneeCache.remove(taskId);
        if (groupId != null) {
          await loadTasksByGroup(groupId);
        }
        await loadTasks();
        await fetchAssignedTasks(status: 'all');
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
    _todayTasks = [];
    _deadlineTasks = [];
    _assignedTasks = [];
    _assigneeCache.clear();
    _safeNotify();
  }

  /// Lấy danh sách task cho ngày hôm nay hoặc ngày cụ thể (theo ngày tạo hoặc deadline)
  Future<void> loadTasks({
    DateTime? date,
    bool byDeadline = false,
  }) async {
    _setLoading(true);
    try {
      final fetched = await TaskService.getTasksByFilter(
        filterBy: byDeadline ? 'deadline' : 'created',
        date: date?.toIso8601String().split('T')[0],
        expand: 'assignee.user',
      );

      final meId = AuthService.currentUserId;
      final seenIds = <String>{};
      final filtered = fetched.where((task) {
        final taskId = task['id'] as String?;
        if (taskId == null || seenIds.contains(taskId)) return false;
        final assigneesList = List<String>.from(task['assignee'] ?? <String>[]);
        if (assigneesList.contains(meId)) {
          seenIds.add(taskId);
          return true;
        }
        return false;
      }).toList();

      if (byDeadline) {
        _deadlineTasks = List<Map<String, dynamic>>.from(filtered);
      } else {
        _todayTasks = List<Map<String, dynamic>>.from(filtered);
      }
      await _prefetchAssigneeInfo(byDeadline ? _deadlineTasks : _todayTasks);
      _safeNotify();
    } catch (e) {
      debugPrint('loadTasks error: $e');
      if (byDeadline) {
        _deadlineTasks = [];
      } else {
        _todayTasks = [];
      }
      _safeNotify();
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy danh sách task được giao cho người dùng hiện tại theo status
  Future<void> fetchAssignedTasks({
    required String status,
  }) async {
    _setLoading(true);
    try {
      final fetched = await TaskService.getTasksByFilter(
        filterBy: 'status',
        status: status,
        expand: 'assignee.user',
      );

      final meId = AuthService.currentUserId;
      final seenIds = <String>{};
      final filtered = fetched.where((task) {
        final taskId = task['id'] as String?;
        if (taskId == null || seenIds.contains(taskId)) return false;
        final assigneesList = List<String>.from(task['assignee'] ?? <String>[]);
        if (assigneesList.contains(meId)) {
          seenIds.add(taskId);
          return true;
        }
        return false;
      }).toList();

      _assignedTasks = List<Map<String, dynamic>>.from(filtered);
      await _prefetchAssigneeInfo(_assignedTasks);
      _safeNotify();
    } catch (e) {
      debugPrint('fetchAssignedTasks error: $e');
      _assignedTasks = [];
      _safeNotify();
    } finally {
      _setLoading(false);
    }
  }

  /// Đếm số lượng task theo group (có tùy chọn lọc theo status)
  Future<int> countTasks(String groupId, {String? status}) async {
    try {
      return await TaskService.countTasks(groupId, status: status);
    } catch (e) {
      debugPrint('countTasks error: $e');
      rethrow;
    }
  }

  /// Lấy thông tin người được giao của một task
  Future<List<Map<String, dynamic>>> fetchAssigneeInfo(String taskId) async {
    if (_assigneeCache.containsKey(taskId)) {
      return _assigneeCache[taskId]!;
    }
    _setLoading(true);
    try {
      final info = await TaskService.getAssigneeInfo(taskId);
      _assigneeCache[taskId] = info
          .map((item) => {
                'id': item['id'],
                'avatarUrl': item['avatarUrl'] ?? '',
                'name': item['name'] ?? 'Unknown User',
              })
          .toList();
      _safeNotify();
      return _assigneeCache[taskId]!;
    } catch (e) {
      debugPrint('fetchAssigneeInfo error: $e');
      _assigneeCache[taskId] = [];
      _safeNotify();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Pre-fetch assignee info for a list of tasks
  Future<void> _prefetchAssigneeInfo(List<dynamic> tasks) async {
    for (var task in tasks) {
      final taskId = task['id'] as String?;
      if (taskId != null &&
          task['assignee'] != null &&
          !_assigneeCache.containsKey(taskId)) {
        try {
          // Sử dụng dữ liệu từ expand nếu có
          if (task['expand']?['assignee'] != null) {
            _assigneeCache[taskId] =
                (task['expand']['assignee'] as List<dynamic>)
                    .map((user) => {
                          'id': user['id'] as String,
                          'avatarUrl': user['avatarUrl'] ?? '',
                          'name': user['name'] ?? 'Unknown User',
                        })
                    .toList();
          } else {
            // Fallback về getAssigneeInfo nếu không có expand
            final info = await TaskService.getAssigneeInfo(taskId);
            _assigneeCache[taskId] = info
                .map((item) => {
                      'id': item['id'],
                      'avatarUrl': item['avatarUrl'] ?? '',
                      'name': item['name'] ?? 'Unknown User',
                    })
                .toList();
          }
        } catch (e) {
          debugPrint('Prefetch assignee info error for task $taskId: $e');
          _assigneeCache[taskId] = [];
        }
      }
    }
  }

  /// Lấy chi tiết một task theo ID
  Future<Map<String, dynamic>> fetchTaskDetail(String taskId) async {
    _setLoading(true);
    try {
      final task = await TaskService.getTaskDetail(taskId);
      if (task['assignee'] != null) {
        await fetchAssigneeInfo(taskId);
      }
      return task;
    } catch (e) {
      debugPrint('fetchTaskDetail error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Cập nhật thông tin task (title, description, deadline, assignees)
  Future<void> updateTask(
    String taskId, {
    String? title,
    String? description,
    DateTime? deadline,
    List<String>? assignees,
  }) async {
    try {
      final updated = await TaskService.updateTask(
        taskId,
        title: title,
        description: description,
        deadline: deadline,
        assignees: assignees,
      );
      final index = _tasks.indexWhere((t) => t['id'] == taskId);
      String? groupId;
      if (index != -1) {
        groupId = _tasks[index]['groupId'] as String?;
        _tasks[index] = updated;
      } else {
        _tasks.add(updated);
      }

      final now = DateTime.now();
      final createdAt = updated['createdAt'] != null
          ? DateTime.parse(updated['createdAt'])
          : now;
      final due = updated['deadline'] != null
          ? DateTime.parse(updated['deadline'])
          : null;
      final meId = AuthService.currentUserId;
      final assigneesList =
          List<String>.from(updated['assignee'] ?? <String>[]);

      if (assigneesList.contains(meId)) {
        if (isSameDay(createdAt, now)) {
          final i = _todayTasks.indexWhere((t) => t['id'] == taskId);
          if (i != -1) {
            _todayTasks[i] = updated;
          } else {
            _todayTasks.add(updated);
          }
        } else {
          _todayTasks.removeWhere((t) => t['id'] == taskId);
        }
        if (due != null && isSameDay(due, now)) {
          final j = _deadlineTasks.indexWhere((t) => t['id'] == taskId);
          if (j != -1) {
            _deadlineTasks[j] = updated;
          } else {
            _deadlineTasks.add(updated);
          }
        } else {
          _deadlineTasks.removeWhere((t) => t['id'] == taskId);
        }
      } else {
        _todayTasks.removeWhere((t) => t['id'] == taskId);
        _deadlineTasks.removeWhere((t) => t['id'] == taskId);
      }

      if (assignees != null && assignees.isNotEmpty) {
        await fetchAssigneeInfo(taskId);
      } else {
        _assigneeCache.remove(taskId);
      }

      if (groupId != null) {
        await loadTasksByGroup(groupId);
      }
      await loadTasks();
      await fetchAssignedTasks(status: 'all');
      _safeNotify();
    } catch (e) {
      debugPrint('updateTask error: $e');
      rethrow;
    }
  }

  /// Dữ liệu cho 7 ngày gần nhất
  List<DayAnalytics> get weeklyAnalytics {
    final now = DateTime.now();
    final start =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: 6));
    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      final inProgress = _tasks.where((t) {
        final created = DateTime.parse(t['createdAt']);
        return isSameDay(created, day) && t['status'] == 'in_progress';
      }).length;
      final completed = _tasks.where((t) {
        final created = DateTime.parse(t['createdAt']);
        return isSameDay(created, day) && t['status'] == 'completed';
      }).length;
      return DayAnalytics(
          date: day, inProgress: inProgress, completed: completed);
    });
  }

  /// Dữ liệu cho tháng hiện tại (tính đến ngày hôm nay)
  List<DayAnalytics> get monthlyAnalytics {
    final now = DateTime.now();
    return List.generate(now.day, (i) {
      final day = DateTime(now.year, now.month, i + 1);
      final inProgress = _tasks.where((t) {
        final created = DateTime.parse(t['createdAt']);
        return isSameDay(created, day) && t['status'] == 'in_progress';
      }).length;
      final completed = _tasks.where((t) {
        final created = DateTime.parse(t['createdAt']);
        return isSameDay(created, day) && t['status'] == 'completed';
      }).length;
      return DayAnalytics(
          date: day, inProgress: inProgress, completed: completed);
    });
  }
}

/// Model nhỏ để lưu kết quả
class DayAnalytics {
  final DateTime date;
  final int inProgress;
  final int completed;
  DayAnalytics({
    required this.date,
    required this.inProgress,
    required this.completed,
  });
}
