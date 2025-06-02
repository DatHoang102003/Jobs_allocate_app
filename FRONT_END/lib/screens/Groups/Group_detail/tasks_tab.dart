import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Tasks/tasks_manager.dart'; // Đảm bảo đúng đường dẫn

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
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
    await tasksProvider.loadTasksByGroup(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    final tasksProvider = Provider.of<TasksProvider>(context);
    final isLoading = tasksProvider.isLoading;
    final tasks = tasksProvider.tasks;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tasks (${tasks.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...tasks.map((t) {
            final assigneeId = t['assignee'] as String?;
            final isCurrentUser = assigneeId == widget.currentUserId;
            final assignee = assigneeId != null
                ? widget.idToName[assigneeId] ?? 'Unknown'
                : 'Unassigned';
            final status = t['status'] as String;
            final taskId = t['id'] as String;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.task_alt, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t['title'] ?? '(No title)',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Assigned to: $assignee'),
                    const SizedBox(height: 4),
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
                                      await tasksProvider.updateTaskStatus(
                                          taskId, newStatus);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Cập nhật thành công')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('Lỗi: $e')),
                                      );
                                    }
                                  }
                                },
                                items: const [
                                  DropdownMenuItem(
                                      value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(
                                      value: 'todo',
                                      child: Text('In Progress')),
                                  DropdownMenuItem(
                                      value: 'done', child: Text('Completed')),
                                ],
                              ),
                            ],
                          )
                        : Text('Status: $status'),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
