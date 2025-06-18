import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Auth/auth_manager.dart';
import '../../Groups/groups_manager.dart';
import '../../Members/membership_manager.dart';
import '../../Tasks/task.dart';
import '../../Tasks/task_detail.dart';
import '../../Tasks/tasks_manager.dart';

class InProgressSection extends StatefulWidget {
  const InProgressSection({Key? key}) : super(key: key);

  @override
  _InProgressSectionState createState() => _InProgressSectionState();
}

class _InProgressSectionState extends State<InProgressSection> {
  String? _previousUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tasksProvider = context.read<TasksProvider>();
    final currentUserId = context.read<AuthManager>().userId;

    if (_previousUserId != currentUserId ||
        tasksProvider.assignedTasks.isEmpty) {
      Future.microtask(() async {
        try {
          await tasksProvider.fetchAssignedTasks(status: 'in_progress');
        } catch (e) {
          debugPrint('Failed to fetch assigned tasks: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load in-progress tasks: $e')),
          );
        }
      });
      _previousUserId = currentUserId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksProvider = context.watch<TasksProvider>();
    final groupsProvider = context.watch<GroupsProvider>();
    final membersProvider = context.watch<MemberManager>();

    final groupMap = {
      for (var g in [
        ...groupsProvider.adminGroups,
        ...groupsProvider.memberGroups
      ])
        g.id: g
    };

    final inProgressTasks = tasksProvider.assignedTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'On Progress (${inProgressTasks.length} tasks)',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, TaskScreen.routeName);
                },
                child: const Text(
                  'View More',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (inProgressTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No tasks in progress',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: inProgressTasks.map((task) {
                final groupId = task['group'] as String? ?? '';
                final groupName = groupMap[groupId]?.name ?? 'Unknown';
                return TaskCard(
                  task: task,
                  groupName: groupName,
                  taskProvider: tasksProvider,
                  membersProvider: membersProvider,
                  key: ValueKey(task['id']),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final String groupName;
  final TasksProvider taskProvider;
  final MemberManager membersProvider;

  const TaskCard({
    required this.task,
    required this.groupName,
    required this.taskProvider,
    required this.membersProvider,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = task['title'] as String? ?? 'Untitled';
    final description = task['description'] as String? ?? '';
    final created =
        DateTime.tryParse(task['created'] as String? ?? '') ?? DateTime.now();
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(created);
    final progressValue = (task['progress'] as num?)?.toDouble() ?? 0.0;
    final taskId = task['id'] as String;
    final groupId = task['group'] as String? ?? '';

    final members = membersProvider.membersOfGroup(groupId);
    final assignees = (task['assignee'] as List<dynamic>?)
            ?.cast<String>()
            .map((id) {
              try {
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
                        'name': userInfo['name'] as String? ?? 'Unknown'
                      }
                    : null;
              } catch (e) {
                debugPrint('Error processing assignee $id: $e');
                return null;
              }
            })
            .where((e) => e != null)
            .map((e) => e!)
            .toList() ??
        [];

    return GestureDetector(
      onTap: () {
        if (groupId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(
                taskId: taskId,
                groupId: groupId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No group ID found for this task'),
            ),
          );
        }
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & date
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Description
            if (description.isNotEmpty) ...[
              Text(
                'Description:',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 12),
            ],

            // Avatars + Progress
            Row(
              children: [
                // Avatars xếp chồng
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < min(assignees.length, 3); i++)
                          Positioned(
                            left:
                                i * 20.0, // 28px diameter − 8px overlap = 20px
                            child: CircleAvatar(
                              radius: 14,
                              backgroundImage:
                                  (assignees[i]['avatarUrl'] as String?)
                                              ?.isNotEmpty ==
                                          true
                                      ? NetworkImage(
                                          assignees[i]['avatarUrl'] as String)
                                      : null,
                              child: (assignees[i]['avatarUrl'] == null ||
                                      (assignees[i]['avatarUrl'] as String)
                                          .isEmpty)
                                  ? Text(
                                      (assignees[i]['name'] as String)
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: GoogleFonts.poppins(
                                          fontSize: 10, color: Colors.white),
                                    )
                                  : null,
                            ),
                          ),
                        if (assignees.length > 3)
                          Positioned(
                            left: min(assignees.length, 3) * 20.0 + 4.0,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                '+${assignees.length - 3}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Progress indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Progress',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progressValue,
                            strokeWidth: 4,
                            backgroundColor: Colors.grey[200],
                          ),
                          Text(
                            '${(progressValue * 100).toInt()}%',
                            style: GoogleFonts.poppins(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
