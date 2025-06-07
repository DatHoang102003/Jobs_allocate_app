import 'package:flutter/material.dart';

import '../../../models/groups.dart';
import '../../Groups/groups_manager.dart';
import '../../Members/membership_manager.dart';
import '../../Tasks/tasks_manager.dart';
import '../../Groups/Group_detail/group_detail.dart';

class GroupCard extends StatelessWidget {
  final GroupsProvider groupProvider;
  final TasksProvider taskProvider;
  final MemberManager memberProvider;
  final Group group;

  const GroupCard({
    Key? key,
    required this.groupProvider,
    required this.taskProvider,
    required this.memberProvider,
    required this.group,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        taskProvider.countTasks(group.id),
        taskProvider.countTasks(group.id, status: 'completed'),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final total = snapshot.data![0];
        final done = snapshot.data![1];
        final pct = total == 0 ? 0.0 : done / total;
        final members = memberProvider.membersOfGroup(group.id);

        return InkWell(
          onTap: () {
            groupProvider.setCurrent(group);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailScreen(groupId: group.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên group và avatar members
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: members.take(3).map((m) {
                          final url = (m['avatarUrl'] as String?) ?? '';
                          final name = (m['name'] as String?) ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  url.isNotEmpty ? NetworkImage(url) : null,
                              child: url.isEmpty
                                  ? Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        }).toList()
                          ..addAll(members.length > 3
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.orange,
                                      child: Text(
                                        '+${members.length - 3}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  )
                                ]
                              : []),
                      ),
                    ],
                  ),

                  // Mô tả (nếu có)
                  if (group.description != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      group.description!,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],

                  const SizedBox(height: 16),
                  // Progress bar
                  Row(
                    children: [
                      Text(
                        '${(pct * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.grey.shade300,
                          color: Theme.of(context).primaryColor,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$done/$total tasks',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
