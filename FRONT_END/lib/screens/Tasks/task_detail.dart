import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../Auth/auth_manager.dart';
import '../Comments/comment_wiget.dart';
import '../Members/membership_manager.dart';
import 'edit_task.dart';
import 'tasks_manager.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final String groupId;

  const TaskDetailScreen({
    Key? key,
    required this.taskId,
    required this.groupId,
  }) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? taskDetail;
  bool isLoading = true;
  bool isLoadingMembers = true;
  bool isUpdating = false;
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> assignees = [];
  String? _previousUserId;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _loadMembers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = context.watch<AuthManager>().userId;

    // Reload data if userId changes
    if (_previousUserId != currentUserId) {
      _loadDetail();
      _loadMembers();
      _previousUserId = currentUserId;
    }
  }

  Future<void> _loadDetail() async {
    setState(() => isLoading = true);
    try {
      final detail =
          await context.read<TasksProvider>().fetchTaskDetail(widget.taskId);
      final members =
          await context.read<MemberManager>().membersOfGroup(widget.groupId);
      final assignees = (detail['assignee'] != null
              ? List<String>.from(detail['assignee'])
              : <String>[])
          .map<Map<String, dynamic>>((id) {
        final member = members.firstWhere(
          (m) => m['user'] == id,
          orElse: () => {},
        );
        final userInfo = member['expand'] is Map<String, dynamic>
            ? (member['expand'] as Map<String, dynamic>)['user']
                as Map<String, dynamic>?
            : null;
        return userInfo != null
            ? {
                'id': id,
                'name': userInfo['name'] as String? ??
                    userInfo['email'] as String? ??
                    'Unknown',
                'avatarUrl': userInfo['avatarUrl'] as String?,
              }
            : {
                'id': id,
                'name': 'Unknown',
                'avatarUrl': null,
              };
      }).toList();
      setState(() {
        taskDetail = detail;
        this.assignees = assignees;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading task detail: $e')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMembers() async {
    setState(() => isLoadingMembers = true);
    try {
      final raw =
          await context.read<MemberManager>().membersOfGroup(widget.groupId);
      setState(() {
        members = raw.cast<Map<String, dynamic>>();
        isLoadingMembers = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $e')),
        );
      }
      setState(() => isLoadingMembers = false);
    }
  }

  void _openAssigneeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: [
          for (var m in members)
            (() {
              final userMap =
                  (m['expand'] as Map?)?['user'] as Map<String, dynamic>?;
              if (userMap == null) return const SizedBox();
              final userId = userMap['id'] as String;
              final name = userMap['name'] as String? ??
                  userMap['email'] as String? ??
                  'Unknown';
              final avatarUrl = userMap['avatarUrl'] as String?;
              final selected = assignees.any((a) => a['id'] == userId);

              return ListTile(
                leading: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
                    : CircleAvatar(child: Text(name.characters.first)),
                title: Text(name),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () async {
                  setState(() => isUpdating = true);
                  try {
                    List<Map<String, dynamic>> updatedAssignees =
                        List.from(assignees);
                    if (selected) {
                      updatedAssignees.removeWhere((a) => a['id'] == userId);
                    } else {
                      updatedAssignees.add({
                        'id': userId,
                        'name': name,
                        'avatarUrl': avatarUrl,
                      });
                    }
                    await context.read<TasksProvider>().updateTask(
                          widget.taskId,
                          assignees: updatedAssignees
                              .map((a) => a['id'] as String)
                              .toList(),
                        );
                    setState(() {
                      assignees = updatedAssignees;
                      taskDetail?['assignee'] =
                          updatedAssignees.map((a) => a['id']).toList();
                      isUpdating = false;
                    });
                    Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating assignee: $e')),
                      );
                    }
                    setState(() => isUpdating = false);
                  }
                },
              );
            })(),
        ],
      ),
    );
  }

  void _handleEditTask() {
    if (taskDetail != null) {
      showTaskEditDialog(
        context: context,
        taskId: widget.taskId,
        initialTask: taskDetail!,
      );
    }
  }

  void _handleDeleteTask() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        setState(() => isUpdating = true);
        await context.read<TasksProvider>().deleteTask(widget.taskId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => isUpdating = false);
      }
    }
  }

  String? _getCurrentUserId() {
    return context.read<AuthManager>().userId;
  }

  bool _isTaskCreator() {
    final creatorId = taskDetail?['createdBy']?.toString();
    final currentUserId = _getCurrentUserId();
    return creatorId != null &&
        currentUserId != null &&
        creatorId == currentUserId;
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
        appBar: AppBar(title: const Text('No Task Found')),
        body: const Center(child: Text('No data available')),
      );
    }

    final title = taskDetail!['title']?.toString() ?? '';
    final description = taskDetail!['description']?.toString();

    DateTime? created;
    if (taskDetail!['created'] != null) {
      created = DateTime.tryParse(taskDetail!['created'].toString());
    }
    DateTime? due;
    if (taskDetail!['deadline'] != null) {
      due = DateTime.tryParse(taskDetail!['deadline'].toString());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isTaskCreator())
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings),
              onSelected: (value) {
                if (value == 'edit') {
                  _handleEditTask();
                } else if (value == 'delete') {
                  _handleDeleteTask();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline),
                  const SizedBox(width: 8),
                  Text(
                    'Assignees (${assignees.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (var u in assignees.take(3))
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: u['avatarUrl'] != null &&
                                  u['avatarUrl'].isNotEmpty
                              ? NetworkImage(u['avatarUrl'] as String)
                              : null,
                          child:
                              u['avatarUrl'] == null || u['avatarUrl'].isEmpty
                                  ? Text(
                                      u['name'].isNotEmpty
                                          ? u['name'][0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          u['name']?.toString() ?? 'Unknown',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  if (assignees.length > 3)
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[300],
                          child: Text(
                            '+${assignees.length - 3}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Others',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  if (_isTaskCreator())
                    GestureDetector(
                      onTap: isLoadingMembers || isUpdating
                          ? null
                          : _openAssigneeSelector,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isLoadingMembers || isUpdating
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add, color: Colors.grey),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
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
                description ?? 'No description.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined),
                  const SizedBox(width: 8),
                  Text('Due Date',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
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
                            ? DateFormat.yMMMd().format(created)
                            : '—',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
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
              Expanded(
                child: CommentsSection(
                  taskId: widget.taskId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
