import 'package:flutter/material.dart';
import 'package:task_manager_app/screens/Tasks/create_task.dart';
import 'package:task_manager_app/services/group_service.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/auth_service.dart';

import 'members_tab.dart';
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
    _init(); // ← new wrapper
  }

  /// Ensures the current user-id is cached, **then** fetches group data.
  Future<void> _init() async {
    await AuthService.getUserId(); // ← one-time cache fill
    await _fetch();
  }

  /* ───────── fetch data ───────── */
  Future<void> _fetch() async {
    try {
      final gDetail = await GroupService.getGroupDetail(widget.groupId);
      final members =
          await MembershipService.listMembersOfGroup(widget.groupId);

      if (mounted) {
        setState(() {
          detail = {
            'group': gDetail['group'],
            'members': members,
            'tasks': gDetail['tasks'] ?? [],
          };
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ───────── add-task dialog ───────── */
  Future<void> _openCreateTaskDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(child: CreateTaskScreen(groupId: widget.groupId)),
    );
    if (created == true) await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    /* loading / error states */
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (detail == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load group details')),
      );
    }

    /* ── de-structure ── */
    final g = detail!['group'] as Map<String, dynamic>;
    final membersAll = detail!['members'] as List<dynamic>;
    final tasks = detail!['tasks'] as List<dynamic>;

    final ownerId = g['owner'] as String;
    final current = AuthService.currentUserId; // now cached

    /* split admins vs members */
    final admins = membersAll
        .where(
          (m) => (m['role'] as String? ?? 'member') == 'admin',
        )
        .toList();
    final members = membersAll.where((m) => !admins.contains(m)).toList();

    /* permission: owner OR admin membership */
    final bool canManage = ownerId == current ||
        membersAll.any(
          (m) =>
              (m['role'] == 'admin') &&
              ((m['user'] == current) ||
                  (m['expand']?['user']?['id'] == current)),
        );

    /* map id → name for TasksTab */
    final idToName = {
      for (var m in membersAll)
        ((m['expand']?['user']?['id']) ?? m['user']) as String:
            (m['expand']?['user']?['name'] as String? ?? 'Unnamed'),
    };

    /* ── UI ── */
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(g['name']),
          bottom: const TabBar(
            tabs: [Tab(text: 'Members'), Tab(text: 'Tasks')],
          ),
        ),
        floatingActionButton: canManage
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
              allMembers: membersAll,
              admins: admins,
              members: members,
              canManage: canManage,
              onRefresh: _fetch,
            ),
            TasksTab(tasks: tasks, idToName: idToName),
          ],
        ),
      ),
    );
  }
}
