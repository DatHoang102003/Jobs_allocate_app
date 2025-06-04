import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:task_manager_app/screens/Tasks/create_task.dart';
import 'package:task_manager_app/services/group_service.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/auth_service.dart';

import '../../../models/groups.dart';
import '../edit_dialog.dart';
import '../groups_manager.dart';
import 'members_tab.dart';
import 'tasks_tab.dart';
import 'join_requests_tab.dart'; // 🔸 NEW

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
    _init();
  }

  /* ─────────────────────────────────────────────
     LOAD DATA
  ───────────────────────────────────────────── */
  Future<void> _init() async {
    await AuthService.getUserId(); // make sure cache is filled
    await _fetch();
  }

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

  /* ─────────────────────────────────────────────
     UI HELPERS
  ───────────────────────────────────────────── */
  Future<void> _openCreateTaskDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(child: CreateTaskScreen(groupId: widget.groupId)),
    );
    if (created == true) await _fetch();
  }

  Future<void> _addMember() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Member functionality coming soon!')),
    );
  }

  Future<void> _editGroupInfo() async {
    final g = detail!['group'];
    final groupModel = Group(
      id: g['id'],
      name: g['name'],
      description: g['description'] ?? '',
      owner: g['owner'],
      created: DateTime.parse(g['created']),
      updated: DateTime.parse(g['updated']),
    );

    await showEditGroupDialog(context, groupModel, (_) async {
      await _fetch();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated successfully')),
      );
    });
  }

  Future<void> _deleteGroup() async {
    try {
      await Provider.of<GroupsProvider>(context, listen: false)
          .deleteGroup(widget.groupId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group deleted successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete group: $e')),
      );
    }
  }

  /* ─────────────────────────────────────────────
     BUILD
  ───────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    final current = AuthService.currentUserId;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (detail == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load group details')),
      );
    }

    final g = detail!['group'] as Map<String, dynamic>;
    final membersAll = detail!['members'] as List<dynamic>;
    final ownerId = g['owner'] as String;

    final admins = membersAll
        .where((m) => (m['role'] as String? ?? 'member') == 'admin')
        .toList();
    final members = membersAll.where((m) => !admins.contains(m)).toList();

    final bool canManage = ownerId == current ||
        membersAll.any((m) =>
            (m['role'] == 'admin') &&
            ((m['user'] == current) ||
                (m['expand']?['user']?['id'] == current)));

    /* ---- tabs & views ----------------------------------------------- */
    final tabs = <Tab>[
      const Tab(text: 'Members'),
      const Tab(text: 'Tasks'),
      if (canManage) const Tab(text: 'Requests'),
    ];

    final tabViews = <Widget>[
      MembersTab(
        groupId: widget.groupId,
        ownerId: ownerId,
        allMembers: membersAll,
        admins: admins,
        members: members,
        canManage: canManage,
        onRefresh: _fetch,
      ),
      TasksTab(
        currentUserId: current,
        groupId: widget.groupId,
        idToName: {
          for (var m in membersAll)
            ((m['expand']?['user']?['id']) ?? m['user']) as String:
                (m['expand']?['user']?['name'] as String? ?? 'Unnamed'),
        },
      ),
      if (canManage) JoinRequestsTab(groupId: widget.groupId, onUpdate: _fetch, ),
    ];

    return DefaultTabController(
      length: tabs.length, // 🔸 dynamic
      child: Scaffold(
        appBar: AppBar(
          title: Text(g['name']),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.settings),
              onSelected: (value) {
                switch (value) {
                  case 'add_member':
                    _addMember();
                    break;
                  case 'add_task':
                    _openCreateTaskDialog();
                    break;
                  case 'edit_info':
                    _editGroupInfo();
                    break;
                  case 'delete_group':
                    _deleteGroup();
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'add_member', child: Text('Add members')),
                PopupMenuItem(value: 'add_task', child: Text('Add task')),
                PopupMenuItem(value: 'edit_info', child: Text('Edit group')),
                PopupMenuItem(
                    value: 'delete_group', child: Text('Delete group')),
              ],
            ),
          ],
          bottom: TabBar(tabs: tabs), // 🔸 use list
        ),
        floatingActionButton: canManage
            ? FloatingActionButton(
                onPressed: _openCreateTaskDialog,
                child: const Icon(Icons.add),
              )
            : null,
        body: TabBarView(children: tabViews), // 🔸 use list
      ),
    );
  }
}
