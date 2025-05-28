import 'package:flutter/material.dart';

class TasksTab extends StatelessWidget {
  final List<dynamic> tasks;
  final Map<String, String> idToName;
  const TasksTab({super.key, required this.tasks, required this.idToName});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tasks (${tasks.length})',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...tasks.map((t) {
          final assigneeId = t['assignee'] as String?;
          final assignee = assigneeId != null
              ? idToName[assigneeId] ?? 'Unknown'
              : 'Unassigned';

          return ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(t['title']),
            subtitle: Text('Status: ${t['status']} • Assigned to: $assignee'),
          );
        }),
      ],
    );
  }
}
