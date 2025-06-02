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

  Future<void> _openCreateTaskDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(child: CreateTaskScreen(groupId: widget.groupId)),
    );
    if (created == true) await _fetch();
  }

  // Placeholder for Add Member functionality
  Future<void> _addMember() async {
    // Implement your add member logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Member functionality coming soon!')),
    );
  }

  // Placeholder for Edit Group Info functionality
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

    await showEditGroupDialog(context, groupModel, (updatedGroup) async {
      await _fetch(); // Refresh group detail
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated successfully')),
      );
    });
  }

  // Placeholder for Delete Group functionality
  Future<void> _deleteGroup() async {
    // Implement your delete group logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete Group functionality coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy userId từ AuthService (có thể thay bằng Provider nếu dùng AuthManager)
    final current = AuthService.currentUserId;
    // Nếu bạn dùng Provider:
    // final current = Provider.of<AuthManager>(context).userId;

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

    final g = detail!['group'] as Map<String, dynamic>;
    final membersAll = detail!['members'] as List<dynamic>;
    final tasks = detail!['tasks'] as List<dynamic>;

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

    final idToName = {
      for (var m in membersAll)
        ((m['expand']?['user']?['id']) ?? m['user']) as String:
            (m['expand']?['user']?['name'] as String? ?? 'Unnamed'),
    };

    return DefaultTabController(
      length: 2,
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
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'add_member',
                  child: Text('Add members'),
                ),
                const PopupMenuItem(
                  value: 'add_task',
                  child: Text('Add task'),
                ),
                const PopupMenuItem(
                  value: 'edit_info',
                  child: Text('Edit group'),
                ),
                const PopupMenuItem(
                  value: 'delete_group',
                  child: Text('Delete group'),
                ),
              ],
            ),
          ],
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
            TasksTab(
              currentUserId: current,
              groupId: widget.groupId,
              idToName: idToName,
            ),
          ],
        ),
      ),
    );
  }
}
