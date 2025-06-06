import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Tasks/create_task.dart';
import 'package:task_manager_app/screens/Tasks/tasks_manager.dart';
import 'package:task_manager_app/services/group_service.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/auth_service.dart';

import '../../../models/groups.dart';
import '../../Members/membership_manager.dart';
import '../edit_dialog.dart';
import '../groups_manager.dart';
import 'members_tab.dart';
import 'tasks_tab.dart';
import 'join_requests_tab.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? detail;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /* ─────────────────────────────────────────────
     LOAD DATA
  ───────────────────────────────────────────── */
  Future<void> _init() async {
    await AuthService.getUserId();
    await _fetch();
  }

  Future<void> _fetch() async {
    try {
      final currentUserId = AuthService.currentUserId;
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
        // Cập nhật MemberManager với userId hiện tại
        final memberManager =
            Provider.of<MemberManager>(context, listen: false);
        await memberManager.fetchMembers(widget.groupId,
            myUserId: currentUserId);
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
    if (created == true) {
      // 1) Refresh your “detail” map (so TasksTab’s count/header is correct):
      await _fetch();

      // 2) ALSO tell the TasksProvider to reload from backend so the list updates:
      await context.read<TasksProvider>().loadTasksByGroup(widget.groupId);
    }
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

    await showEditGroupDialog(context, groupModel, (updatedGroup) async {
      await _fetch();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated successfully')),
      );
    });
  }

  Future<void> _deleteGroup() async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa nhóm'),
          content: const Text('Bạn có chắc chắn muốn xóa nhóm này?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    try {
      final groupsProvider =
          Provider.of<GroupsProvider>(context, listen: false);
      final groupId = widget.groupId;
      final currentGroup = groupsProvider.adminGroups.firstWhere(
        (group) => group.id == groupId,
        orElse: () => groupsProvider.memberGroups.firstWhere(
          (group) => group.id == groupId,
          orElse: () => throw Exception('Group not found'),
        ),
      );
      final groupData = {
        'id': currentGroup.id,
        'isAdmin': groupsProvider.adminGroups.contains(currentGroup),
      };

      await groupsProvider.deleteGroup(groupId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xóa nhóm thành công'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () async {
                try {
                  await groupsProvider.restoreGroup(groupData);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã khôi phục nhóm')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Khôi phục nhóm thất bại: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa nhóm thất bại: $e')),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final membershipManager =
          Provider.of<MemberManager>(context, listen: false);
      final groupsProvider =
          Provider.of<GroupsProvider>(context, listen: false);
      final membershipId = membershipManager.myMembershipId;

      if (membershipId == null) {
        throw Exception('You are not a member of this group');
      }

      await membershipManager.leaveGroup(membershipId);
      await groupsProvider.fetchGroups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the group')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave group: $e')),
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
        idToName: idToName,
      ),
      if (canManage)
        JoinRequestsTab(
          groupId: widget.groupId,
          onUpdate: _fetch,
        ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(g['name']),
          actions: [
            if (canManage)
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
                itemBuilder: (BuildContext context) => const [
                  PopupMenuItem(
                      value: 'add_member', child: Text('Add members')),
                  PopupMenuItem(value: 'add_task', child: Text('Add task')),
                  PopupMenuItem(value: 'edit_info', child: Text('Edit group')),
                  PopupMenuItem(
                      value: 'delete_group', child: Text('Delete group')),
                ],
              )
            else
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Leave group',
                onPressed: _leaveGroup,
              ),
          ],
          bottom: TabBar(tabs: tabs),
        ),
        floatingActionButton: canManage
            ? FloatingActionButton(
                onPressed: _openCreateTaskDialog,
                child: const Icon(Icons.add),
              )
            : null,
        body: TabBarView(children: tabViews),
      ),
    );
  }
}
