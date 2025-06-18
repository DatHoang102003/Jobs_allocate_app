import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../Comments/comments_manager.dart';
import '../../Members/membership_manager.dart';
import '../../Tasks/task_detail.dart';
import '../../Tasks/tasks_manager.dart';

class TasksTab extends StatefulWidget {
  final String currentUserId;
  final String groupId;

  const TasksTab({
    Key? key,
    required this.currentUserId,
    required this.groupId,
  }) : super(key: key);

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<TasksProvider>().loadTasksByGroup(widget.groupId);
    await context.read<MemberManager>().fetchMembers(widget.groupId);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _capitalizeStatus(String status) {
    return status
        .split('_')
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TasksProvider>();
    final memberProvider = context.watch<MemberManager>();
    final tasks = taskProvider.tasks;
    final members = memberProvider.membersOfGroup(widget.groupId);

    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tasks (${tasks.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...tasks.map((t) {
            final taskId = t['id'] as String;
            final title = t['title'] as String? ?? '(No title)';
            final createdAt = t['created'] != null
                ? DateTime.tryParse(t['created'] as String)
                : null;
            final deadline = t['deadline'] != null
                ? DateTime.tryParse(t['deadline'] as String)
                : null;
            final status = t['status'] as String? ?? 'pending';
            final assignees = t['assignee'] != null
                ? List<String>.from(t['assignee'])
                : <String>[];
            final isCurrentUser = assignees.contains(widget.currentUserId);

            final assigneeInfos = assignees
                .map((id) {
                  final record = members.firstWhere(
                    (m) => m['user'] == id,
                    orElse: () => {},
                  );
                  final userInfo = record['expand'] is Map<String, dynamic>
                      ? (record['expand'] as Map<String, dynamic>)['user']
                          as Map<String, dynamic>?
                      : null;
                  return userInfo != null
                      ? {
                          'avatarUrl': userInfo['avatarUrl'] as String?,
                          'name': userInfo['name'] as String? ?? ''
                        }
                      : null;
                })
                .where((info) => info != null)
                .map((info) => info!)
                .toList();

            return ChangeNotifierProvider<CommentsProvider>(
              create: (_) => CommentsProvider()..loadComments(taskId),
              child: Consumer<CommentsProvider>(
                builder: (_, commentsProvider, __) {
                  final commentsCount = commentsProvider.commentCount;

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(
                            taskId: taskId,
                            groupId: widget.groupId,
                          ),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + overlapping avatars
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Avatar stack
                              SizedBox(
                                width: 16 +
                                    min(assigneeInfos.length, 3) * 20.0 +
                                    (assigneeInfos.length > 3 ? 24.0 : 0),
                                height: 32,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    for (var i = 0;
                                        i < min(assigneeInfos.length, 3);
                                        i++)
                                      Positioned(
                                        left: i * 20.0,
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundImage: (assigneeInfos[i]
                                                              ['avatarUrl']
                                                          as String?)
                                                      ?.isNotEmpty ==
                                                  true
                                              ? NetworkImage(assigneeInfos[i]
                                                  ['avatarUrl'] as String)
                                              : null,
                                          child: (assigneeInfos[i]
                                                          ['avatarUrl'] ==
                                                      null ||
                                                  (assigneeInfos[i]['avatarUrl']
                                                          as String)
                                                      .isEmpty)
                                              ? Text(
                                                  (assigneeInfos[i]['name']
                                                          as String)
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                    if (assigneeInfos.length > 3)
                                      Positioned(
                                        left: min(assigneeInfos.length, 3) *
                                                20.0 +
                                            4.0,
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey[300],
                                          child: Text(
                                            '+${assigneeInfos.length - 3}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),
                          // Dates line
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                              Expanded(
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  height: 1,
                                  color: Colors.grey[400],
                                ),
                              ),
                              Text(
                                _formatDate(deadline),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),
                          // Status / Dropdown
                          isCurrentUser
                              ? Row(
                                  children: [
                                    const Text(
                                      'Status: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color.fromRGBO(117, 117, 117, 1),
                                      ),
                                    ),
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
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Update status successfully')),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text('Lỗi: \$e')),
                                            );
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
                              : Text(
                                  'Status: ${_capitalizeStatus(status)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                          // Icon comment + số lượng, căn phải
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.comment,
                                  size: 15,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$commentsCount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
