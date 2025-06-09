import 'package:flutter/material.dart';

import '../../../models/groups.dart';
import '../../Groups/groups_manager.dart';
import '../../Tasks/tasks_manager.dart';
import '../../Members/membership_manager.dart';
import '../../Groups/Group_detail/group_detail.dart';

class GroupCard extends StatefulWidget {
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
  _GroupCardState createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard>
    with AutomaticKeepAliveClientMixin {
  late Future<void> _loadFuture;
  int _total = 0;
  int _done = 0;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    // Concurrently load counts and members once
    _loadFuture = Future.wait([
      widget.taskProvider.countTasks(widget.group.id),
      widget.taskProvider.countTasks(widget.group.id, status: 'completed'),
      widget.memberProvider.fetchMembers(widget.group.id),
    ]).then((results) {
      _total = results[0] as int;
      _done = results[1] as int;
      // after fetchMembers completes, get members list
      _members = widget.memberProvider.membersOfGroup(widget.group.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Placeholder card while loading
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final pct = _total == 0 ? 0.0 : _done / _total;

        return InkWell(
          onTap: () {
            widget.groupProvider.setCurrent(widget.group);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailScreen(groupId: widget.group.id),
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
                  // Group name & avatars
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.group.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var m in _members.take(3))
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundImage:
                                    (m['avatarUrl'] as String?)?.isNotEmpty ==
                                            true
                                        ? NetworkImage(m['avatarUrl'] as String)
                                        : null,
                                child: (m['avatarUrl'] as String?)?.isEmpty ==
                                        true
                                    ? Text(
                                        (m['name'] as String?)?.isNotEmpty ==
                                                true
                                            ? (m['name']![0].toUpperCase())
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          if (_members.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  '+${_members.length - 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Description
                  if (widget.group.description != null &&
                      widget.group.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.group.description!,
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
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$_done/$_total tasks',
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

  @override
  bool get wantKeepAlive => true;
}
