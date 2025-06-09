import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Tasks/task_detail.dart';
import '../../Tasks/tasks_manager.dart';

class TasksTab extends StatefulWidget {
  final String currentUserId;
  final String groupId;
  final Map<String, String> idToName;

  const TasksTab({
    super.key,
    required this.currentUserId,
    required this.groupId,
    required this.idToName,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  @override
  void initState() {
    super.initState();
    // Defer loadTasks cho đến khi frame đầu tiên vẽ xong
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    await context.read<TasksProvider>().loadTasksByGroup(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TasksProvider>();
    final tasks = provider.tasks;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tasks (${tasks.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          // Duyệt qua từng task
          ...tasks.map((t) {
            final assigneeId = t['assignee'] as String?;
            final assignee = assigneeId != null
                ? widget.idToName[assigneeId] ?? 'Unknown'
                : 'Unassigned';
            final isCurrentUser = assigneeId == widget.currentUserId;
            final status = t['status'] as String? ?? 'pending';
            final taskId = t['id'] as String;
            final creatorId = t['createdBy'] as String?;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  // Điều hướng sang TaskDetailScreen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(
                        taskId: taskId,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề + nút xóa (nếu creator)
                      Row(
                        children: [
                          const Icon(Icons.task_alt, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t['title'] as String? ?? '(No title)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (creatorId == widget.currentUserId)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirm delete'),
                                    content: const Text(
                                        'Are you sure you want to delete this task?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('DELETE'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true) {
                                  try {
                                    await context
                                        .read<TasksProvider>()
                                        .deleteTask(taskId);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text('Task deleted'),
                                    ));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text('Error: $e'),
                                    ));
                                  }
                                }
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      // Assignee
                      Text('Assigned to: $assignee',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[800])),
                      const SizedBox(height: 4),

                      // Status: dropdown nếu là currentUser, else chỉ hiển thị text
                      isCurrentUser
                          ? Row(
                              children: [
                                const Text('Status: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                DropdownButton<String>(
                                  value: status,
                                  onChanged: (newStatus) async {
                                    if (newStatus != null &&
                                        newStatus != status) {
                                      try {
                                        await context
                                            .read<TasksProvider>()
                                            .updateTaskStatus(
                                                taskId, newStatus);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text('Cập nhật thành công'),
                                        ));
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text('Lỗi: $e'),
                                        ));
                                      }
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'pending',
                                        child: Text('Pending')),
                                    DropdownMenuItem(
                                        value: 'in_progress',
                                        child: Text('In Progress')),
                                    DropdownMenuItem(
                                        value: 'completed',
                                        child: Text('Completed')),
                                  ],
                                ),
                              ],
                            )
                          : Text('Status: $status',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[800])),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
