import 'package:flutter/material.dart';
import 'package:task_manager_app/screens/Tasks/create_task.dart';
import 'package:task_manager_app/services/group_service.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/auth_service.dart';

// local widgets
import 'member_tab.dart';
import 'tasks_tab.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? detail; // {group, members, tasks}

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final groupDetail = await GroupService.getGroupDetail(widget.groupId);
      final members =
          await MembershipService.listMembersOfGroup(widget.groupId);

      if (mounted) {
        setState(() {
          detail = {
            'group': groupDetail['group'],
            'members': members,
            'tasks': groupDetail['tasks'] ?? [],
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openCreateTaskDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        child: CreateTaskScreen(groupId: widget.groupId), // ← correct class
      ),
    );
    if (created == true) await _fetch(); // refresh if a task was added
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (detail == null) {
      return const Center(child: Text('Failed to load group details.'));
    }

    final group = detail!['group'] as Map<String, dynamic>;
    final allMembers = detail!['members'] as List<dynamic>;
    final tasks = detail!['tasks'] as List<dynamic>;

    /* owner vs admins vs members */
    final ownerId = group['owner'] as String;
    final admins = allMembers.where((m) {
      final role = m['role'] as String? ?? 'member';
      return role == 'admin';
    }).toList();
    final members = allMembers.where((m) => !admins.contains(m)).toList();

    final bool isAdmin = admins.any((m) =>
        (m['expand']?['user']?['id'] as String?) == AuthService.currentUserId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group['name']),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Members'),
              Tab(text: 'Tasks'),
            ],
          ),
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                onPressed: _openCreateTaskDialog,
                child: const Icon(Icons.add),
              )
            : null,
        body: TabBarView(
          children: [
            MembersTab(
              groupId: widget.groupId,
              ownerId: ownerId,
              allMembers: allMembers,
              admins: admins,
              members: members,
              isAdmin: isAdmin,
              onRefresh: _fetch,
            ),
            TasksTab(
              tasks: tasks,
              idToName: {
                for (var m in allMembers)
                  (m['expand']?['user']?['id'] as String): //
                      (m['expand']?['user']?['name'] as String? ?? '')
              },
            ),
          ],
        ),
      ),
    );
  }
}
