import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'tasks_manager.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? taskDetail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => isLoading = true);
    try {
      final detail =
          await context.read<TasksProvider>().fetchTaskDetail(widget.taskId);
      setState(() => taskDetail = detail);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading task detail: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (taskDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Not Found')),
        body: const Center(child: Text('No data available')),
      );
    }

    // 1. Các trường cơ bản
    final title = taskDetail!['title']?.toString() ?? '';
    final description = taskDetail!['description']?.toString();

    // 2. Ngày tạo và ngày hết hạn
    DateTime? created;
    if (taskDetail!['created'] != null) {
      created = DateTime.tryParse(taskDetail!['created'].toString());
    }
    DateTime? due;
    if (taskDetail!['deadline'] != null) {
      due = DateTime.tryParse(taskDetail!['deadline'].toString());
    }

    // 3. Assignees
    List<Map<String, dynamic>> rawAssignees;
    if (taskDetail!.containsKey('assignees') &&
        taskDetail!['assignees'] is List) {
      rawAssignees =
          List<Map<String, dynamic>>.from(taskDetail!['assignees'] as List);
    } else if (taskDetail!['assigneeInfo'] != null) {
      rawAssignees = [
        Map<String, dynamic>.from(
            taskDetail!['assigneeInfo'] as Map<String, dynamic>),
      ];
    } else {
      rawAssignees = [];
    }
    final assignees = rawAssignees.map((m) {
      return {
        'name': m['name']?.toString() ?? '',
        'avatarUrl': m['avatarUrl']?.toString() ?? '',
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── ASSIGNEE SECTION ────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.person_outline),
                  const SizedBox(width: 8),
                  Text(
                    'Assign (${assignees.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var u in assignees)
                    CircleAvatar(
                      backgroundImage: u['avatarUrl']!.isNotEmpty
                          ? NetworkImage(u['avatarUrl']!)
                          : null,
                      child: u['avatarUrl']!.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                      radius: 20,
                    ),
                  GestureDetector(
                    onTap: () {
                      // TODO: mở dialog để assign thêm người
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.add, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── DESCRIPTION ────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.description_outlined),
                  const SizedBox(width: 8),
                  Text('Description',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description ?? 'No description provided.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              // ─── DUE DATE ───────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined),
                  const SizedBox(width: 8),
                  Text('Due date',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Created
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        created != null
                            ? DateFormat.yMMMd().add_jm().format(created)
                            : '—',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                  // Due
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        due != null
                            ? DateFormat.yMMMd().add_jm().format(due)
                            : '—',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── COMMENTS HEADER ────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.comment_outlined),
                  const SizedBox(width: 8),
                  Text('Comments',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),

              // COMMENTS LIST placeholder
              Expanded(
                child: Center(child: Text('Comments UI placeholder')),
              ),

              // NEW COMMENT INPUT
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Post your comment',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send,
                          color: Theme.of(context).primaryColor),
                      onPressed: () {
                        // TODO: implement comment logic
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
