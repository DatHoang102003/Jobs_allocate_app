import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/screens/Tasks/create_task.dart';
import 'package:task_manager_app/services/group_service.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/auth_service.dart';

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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _openCreateTaskDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(child: CreateTaskScreen(groupId: widget.groupId)),
    );
    if (created == true) await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (detail == null) {
      return const Scaffold(body: Center(child: Text('Failed to load data')));
    }

    final g = detail!['group'];
    final allMembers = detail!['members'] as List<dynamic>;

    /* current-user permission flags */
    final meId = AuthService.currentUserId;
    final myMs = allMembers
        .cast<Map<String, dynamic>>()
        .firstWhere((m) => m['user'] == meId, orElse: () => {});
    final bool isOwner = g['owner'] == meId;
    final bool isAdmin = isOwner || myMs['role'] == 'admin';

    /* split admin vs members */
    final admins = allMembers.where((m) {
      final role = m['role'] as String? ?? 'member';
      return role == 'admin' || m['user'] == g['owner'];
    }).toList();
    final members = allMembers.where((m) => !admins.contains(m)).toList();

    /* id → name map for tasks */
    final idToName = <String, String>{
      for (var m in allMembers)
        if (m['expand']?['user'] != null)
          m['user'] as String: (m['expand']['user']['name'] ??
              m['expand']['user']['email']) as String,
    };

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(g['name']),
          bottom: const TabBar(
            tabs: [Tab(text: 'Members'), Tab(text: 'Tasks')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add_task),
          label: const Text('Add Task'),
          onPressed: _openCreateTaskDialog,
        ),
        body: TabBarView(
          children: [
            MembersTab(
              groupId: widget.groupId,
              ownerId: g['owner'] as String,
              allMembers: allMembers,
              admins: admins,
              members: members,
              isAdmin: isAdmin,
              onRefresh: _fetch,
            ),
            TasksTab(tasks: detail!['tasks'], idToName: idToName),
          ],
        ),
      ),
    );
  }
}

/* ───────────────── Search box ───────────────── */
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const SearchBarWidget(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search members...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/* ───────────────── Members tab ───────────────── */
class MembersTab extends StatefulWidget {
  final String groupId;
  final String ownerId;
  final List<dynamic> allMembers;
  final List<dynamic> admins;
  final List<dynamic> members;
  final bool isAdmin; // caller’s admin/owner flag
  final VoidCallback onRefresh;

  const MembersTab({
    super.key,
    required this.groupId,
    required this.ownerId,
    required this.allMembers,
    required this.admins,
    required this.members,
    required this.isAdmin,
    required this.onRefresh,
  });

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _removing = false;
  String? _removingId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _filterMembers(List<dynamic> list) {
    return list.where((m) {
      final user = (m['expand']?['user']) as Map<String, dynamic>?;
      final name = user?['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  /* remove flow */
  Future<void> _onRemovePressed(dynamic m) async {
    final u = (m['expand'] as Map)['user'] as Map<String, dynamic>;
    final name = u['name'] ?? u['email'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove $name from group?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _removing = true;
      _removingId = m['id'] as String;
    });

    try {
      await MembershipService.removeMember(
        widget.groupId,
        m['id'] as String,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed')),
      );
      widget.onRefresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _removing = false;
          _removingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admins = _filterMembers(widget.admins);
    final members = _filterMembers(widget.members);

    return Column(
      children: [
        SearchBarWidget(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (admins.isNotEmpty) ...[
                Text('Admins (${admins.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...admins.map(_memberTile),
                const SizedBox(height: 20),
              ],
              Text('Members (${members.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...members.map(_memberTile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _memberTile(dynamic m) {
    final u = (m['expand'] as Map)['user'] as Map<String, dynamic>;
    final targetId = u['id'] as String;
    final targetRole = m['role'] as String? ?? 'member';

    final bool callerIsOwner = widget.ownerId == AuthService.currentUserId;
    final bool callerIsAdmin = widget.isAdmin;

    /* permission checks */
    bool canRemove = callerIsOwner || callerIsAdmin;
    canRemove &= targetId != AuthService.currentUserId; // not myself
    canRemove &= targetId != widget.ownerId; // not owner
    if (!callerIsOwner && targetRole == 'admin') {
      canRemove = false; // admins can’t kick admins
    }

    final avatarUrl = u['avatarUrl'] as String?;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(u['name'] ?? 'Unknown'),
      subtitle: Text(u['email'] ?? ''),
      trailing: canRemove
          ? (_removing && _removingId == m['id'])
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _onRemovePressed(m),
                )
          : null,
    );
  }
}

/* ───────────────── Tasks tab ───────────────── */
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
