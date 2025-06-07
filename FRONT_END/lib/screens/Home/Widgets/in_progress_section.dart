import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Groups/groups_manager.dart';
import '../../Tasks/tasks_manager.dart';

class InProgressSection extends StatelessWidget {
  const InProgressSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy 2 provider từ context
    final taskProvider = Provider.of<TasksProvider>(context);
    final groupsProvider = Provider.of<GroupsProvider>(context);

    // Gom tất cả nhóm của mình (admin + member)
    final allGroups = [
      ...groupsProvider.adminGroups,
      ...groupsProvider.memberGroups,
    ];

    // Lọc ra 2 task đang in_progress
    final inProg = taskProvider.tasks
        .where((t) => t['status'] == 'in_progress')
        .take(2)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "In Progress",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: inProg.map((task) {
            // Lấy groupId từ task
            final groupId = task['group'] as String? ?? '';

            // Tìm Group tương ứng
            final matched = allGroups.where((g) => g.id == groupId).toList();
            final groupName =
                matched.isNotEmpty ? matched.first.name : 'Unknown';

            return _buildTaskCard(task, groupName);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, String groupName) {
    final title = task['title'] as String? ?? 'Untitled';
    final prog = (task['progress'] as num?)?.toDouble() ?? 0.0;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(groupName,
                style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            const SizedBox(height: 4),
            Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: prog,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
