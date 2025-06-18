import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Tasks/create_task.dart';
import 'package:task_manager_app/screens/Tasks/tasks_manager.dart';
import 'package:task_manager_app/services/auth_service.dart';
import 'package:task_manager_app/services/group_service.dart';
import 'package:task_manager_app/services/invite_service.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/user_service.dart';
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

      if (!mounted) return;
      setState(() {
        detail = {
          'group': gDetail['group'],
          'members': members,
          'tasks': gDetail['tasks'] ?? [],
        };
        _loading = false;
      });
      final memberManager = Provider.of<MemberManager>(context, listen: false);
      await memberManager.fetchMembers(
        widget.groupId,
        myUserId: currentUserId,
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateTaskDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        child: CreateTaskScreen(groupId: widget.groupId),
      ),
    );
    if (created == true) {
      await _fetch();
      await context.read<TasksProvider>().loadTasksByGroup(widget.groupId);
    }
  }

  Future<void> _addMember() async {
    if (detail == null) return;

    // 1) IDs of existing members
    final allMembers = detail!['members'] as List<dynamic>;
    final existingIds = allMembers.map((m) {
      final u = m['expand']?['user'];
      return u != null ? u['id'] as String : m['user'] as String;
    }).toSet();

    // 2) Fetch pending invites for this group
    List<dynamic> invites;
    try {
      invites = await InviteService.listMyInvites();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load invites: $e')),
      );
      return;
    }
    final pendingIds = invites
        .where((inv) =>
            inv['group'] == widget.groupId && inv['status'] == 'pending')
        .map((inv) => inv['invitee'] as String)
        .toSet();

    // 3) Fetch all users
    List<dynamic> users;
    try {
      users = await UserService.getAllUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
      return;
    }

    // 4) Show dialog
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        // copy pendingIds into a mutable set
        final currentPending = Set<String>.from(pendingIds);

        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Invite members'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final u = users[i];
                  final id = u['id'] as String;
                  final name = (u['name'] ?? u['email']) as String;
                  // determine state
                  final isMember = existingIds.contains(id);
                  final isPending = currentPending.contains(id);

                  Widget btn;
                  if (isMember) {
                    btn = ElevatedButton(
                      onPressed: null,
                      child: const Text('Member'),
                    );
                  } else if (isPending) {
                    btn = ElevatedButton(
                      onPressed: null,
                      child: const Text('Pending'),
                    );
                  } else {
                    btn = ElevatedButton(
                      onPressed: () async {
                        try {
                          await InviteService.sendInviteRequest(
                              widget.groupId, id);
                          setState(() => currentPending.add(id));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Invite failed for $name: $e')),
                          );
                        }
                      },
                      child: const Text('Send'),
                    );
                  }

                  return ListTile(
                    title: Text(name),
                    subtitle: Text(u['email'] as String),
                    trailing: btn,
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CLOSE'),
              ),
            ],
          ),
        );
      },
    );

    // 5) Refresh your detail so pendingIds updates next time
    await _fetch();
  }

  Future<void> _editGroupInfo() async {
    final g = detail!['group'] as Map<String, dynamic>;
    final groupModel = Group(
      id: g['id'],
      name: g['name'],
      description: g['description'] ?? '',
      owner: g['owner'],
      created: DateTime.parse(g['created']),
      updated: DateTime.parse(g['updated']),
    );

    await showEditGroupDialog(
      context,
      groupModel,
      (updatedGroup) async {
        await _fetch();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated successfully')),
        );
      },
    );
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final groupsProvider =
          Provider.of<GroupsProvider>(context, listen: false);
      final currentGroup = groupsProvider.adminGroups
          .firstWhere((g) => g.id == widget.groupId, orElse: () {
        return groupsProvider.memberGroups
            .firstWhere((g) => g.id == widget.groupId);
      });
      final groupData = {
        'id': currentGroup.id,
        'isAdmin': groupsProvider.adminGroups.contains(currentGroup),
      };

      await groupsProvider.deleteGroup(widget.groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Group deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                try {
                  await groupsProvider.restoreGroup(groupData);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group restored')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e')),
                  );
                }
              },
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final memberManager = Provider.of<MemberManager>(context, listen: false);
      final groupsProvider =
          Provider.of<GroupsProvider>(context, listen: false);
      final membershipId = memberManager.myMembershipId;
      if (membershipId == null) {
        throw Exception('Not a member');
      }
      await memberManager.leaveGroup(membershipId);
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
    final canManage = ownerId == current ||
        membersAll.any((m) =>
            (m['role'] == 'admin') &&
            ((m['user'] == current) ||
                (m['expand']?['user']?['id'] == current)));

    final idToName = {
      for (var m in membersAll)
        ((m['expand']?['user']?['id']) ?? m['user']) as String:
            (m['expand']?['user']?['name'] as String? ?? 'Unnamed'),
    };

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
                itemBuilder: (_) => const [
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
