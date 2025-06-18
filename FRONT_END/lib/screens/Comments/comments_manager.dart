import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../services/comments_service.dart';

class CommentsProvider with ChangeNotifier {
  // STATE
  List<Map<String, dynamic>> _comments = [];
  bool _loading = false;

  // Getter: danh sách comments
  List<Map<String, dynamic>> get comments => List.unmodifiable(_comments);
  // Getter: đang loading
  bool get isLoading => _loading;

  // MỚI: số lượng comment của task hiện tại
  int get commentCount => _comments.length;

  // Internal safe notify để tránh notifyListeners khi đang trong frame
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

  /// Load comments for a task, optionally paginated
  Future<void> loadComments(
    String taskId, {
    int? page,
    int? perPage,
  }) async {
    _setLoading(true);
    try {
      final data = await CommentsService.listComments(
        taskId,
        page: page,
        perPage: perPage,
      );
      // API có thể trả về list hoặc object paginated
      List<Map<String, dynamic>> items;
      if (data is Map<String, dynamic> && data['items'] is List) {
        items = List<Map<String, dynamic>>.from(data['items']);
      } else if (data is List) {
        items = List<Map<String, dynamic>>.from(data);
      } else {
        items = [];
      }
      _comments = items;
    } catch (e) {
      debugPrint('loadComments error: \$e');
      _comments = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Create a comment and prepend to list
  Future<void> createComment(
    String taskId,
    String contents, {
    List<String>? attachments,
  }) async {
    _setLoading(true);
    try {
      final comment = await CommentsService.createComment(
        taskId,
        contents,
        attachments: attachments,
      );
      _comments.insert(0, comment);
      _safeNotify();
    } catch (e) {
      debugPrint('createComment error: \$e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing comment
  Future<void> updateComment(
    String taskId,
    String commentId, {
    String? contents,
    List<String>? attachments,
  }) async {
    _setLoading(true);
    try {
      final updated = await CommentsService.updateComment(
        taskId,
        commentId,
        contents: contents,
        attachments: attachments,
      );
      final idx = _comments.indexWhere((c) => c['id'] == commentId);
      if (idx != -1) {
        _comments[idx] = updated;
      }
      _safeNotify();
    } catch (e) {
      debugPrint('updateComment error: \$e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Soft-delete a comment
  Future<void> deleteComment(
    String taskId,
    String commentId,
  ) async {
    _setLoading(true);
    try {
      final ok = await CommentsService.deleteComment(
        taskId,
        commentId,
      );
      if (ok) {
        _comments.removeWhere((c) => c['id'] == commentId);
        _safeNotify();
      }
    } catch (e) {
      debugPrint('deleteComment error: \$e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all comments (e.g. when switching tasks)
  void clearComments() {
    _comments = [];
    _safeNotify();
  }
}
