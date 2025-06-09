import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../models/groups.dart';
import '../../Groups/groups_manager.dart';
import '../../Tasks/task_detail.dart';
import '../../Tasks/tasks_manager.dart';

class InProgressSection extends StatelessWidget {
  const InProgressSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<GroupsProvider, Map<String, Group>>(
      selector: (context, provider) => {
        for (var g in [...provider.adminGroups, ...provider.memberGroups])
          g.id: g
      },
      builder: (context, groupMap, child) {
        return Selector<TasksProvider, List<Map<String, dynamic>>>(
          selector: (context, provider) => provider.tasks
              .where((t) => t['status'] == 'in_progress')
              .take(2)
              .toList(),
          builder: (context, inProg, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  child: const Text("In Progress"),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    key: ValueKey(inProg.map((t) => t['id']).join()),
                    children: inProg.map((task) {
                      final groupId = task['group'] as String? ?? '';
                      final groupName = groupMap[groupId]?.name ?? 'Unknown';
                      return _buildTaskCard(task, groupName,
                          Provider.of<TasksProvider>(context, listen: false));
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTaskCard(
    Map<String, dynamic> task,
    String groupName,
    TasksProvider taskProvider,
  ) {
    final title = task['title'] as String? ?? 'Untitled';
    final created =
        DateTime.tryParse(task['created'] as String? ?? '') ?? DateTime.now();
    final deadline =
        DateTime.tryParse(task['deadline'] as String? ?? '') ?? created;
    final df = DateFormat('dd/MM/yyyy');
    final createdStr = df.format(created);
    final deadlineStr = df.format(deadline);

    return Expanded(
      child: Selector<TasksProvider, Map<String, dynamic>?>(
        selector: (context, provider) =>
            provider.getCachedAssigneeInfo(task['id'] as String),
        builder: (context, assigneeInfo, child) {
          final avatarUrl = assigneeInfo?['avatarUrl'] as String?;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TaskDetailScreen(taskId: task['id'] as String),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 12),
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
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    groupName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        createdStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          height: 1,
                          color: Colors.grey[400],
                        ),
                      ),
                      Text(
                        deadlineStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
