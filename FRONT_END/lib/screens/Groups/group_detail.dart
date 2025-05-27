import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/screens/Tasks/create_task.dart';
import 'package:task_manager_app/services/group_service.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/task_service.dart';
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
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
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
    if (created == true) await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (detail == null) {
      return const Scaffold(
          body: Center(child: Text('Không tải được dữ liệu')));
    }

    final g = detail!['group'];
    final allMembers = detail!['members'] as List<dynamic>;

    final meId = AuthService.currentUserId;
    final myMs = allMembers
        .cast<Map<String, dynamic>>()
        .firstWhere((m) => m['user'] == meId, orElse: () => {});
    final bool isOwner = g['owner'] == meId;
    final bool isAdmin = isOwner || myMs['role'] == 'admin';

    final admins = allMembers.where((m) {
      final role = m['role'] as String? ?? 'member';
      return role == 'admin' || m['user'] == g['owner'];
    }).toList();

    final members = allMembers.where((m) => !admins.contains(m)).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(g['name']),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Members'),
              Tab(text: 'Tasks'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add_task),
          label: const Text('Thêm Task'),
          onPressed: _openCreateTaskDialog,
        ),
        body: TabBarView(
          children: [
            MembersTab(
              groupId: widget.groupId,
              allMembers: allMembers,
              isAdmin: isAdmin,
              admins: admins,
              members: members,
              onRefresh: _fetch,
            ),
            TasksTab(tasks: detail!['tasks']),
          ],
        ),
      ),
    );
  }
}

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search members...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class MembersTab extends StatefulWidget {
  final String groupId;
  final List<dynamic> allMembers;
  final List<dynamic> admins;
  final List<dynamic> members;
  final bool isAdmin;
  final VoidCallback onRefresh;

  const MembersTab({
    super.key,
    required this.groupId,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _filterMembers(List<dynamic> list) {
    return list.where((member) {
      final user = (member['expand']?['user']) as Map<String, dynamic>?;
      final name = user?['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAdmins = _filterMembers(widget.admins);
    final filteredMembers = _filterMembers(widget.members);

    return Column(
      children: [
        SearchBarWidget(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (filteredAdmins.isNotEmpty) ...[
                Text('Admins (${filteredAdmins.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...filteredAdmins
                    .map((m) => _memberTile(context, m, widget.isAdmin)),
                const SizedBox(height: 20),
              ],
              Text('Members (${filteredMembers.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...filteredMembers
                  .map((m) => _memberTile(context, m, widget.isAdmin)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _memberTile(BuildContext context, dynamic m, bool canRemove) {
    final u = (m['expand'] as Map)['user'] as Map<String, dynamic>;
    final avatarUrl = u['avatarUrl'] as String?;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(u['name'] ?? 'Unknown'),
      subtitle: Text(u['email'] ?? ''),
      trailing: canRemove && u['id'] != AuthService.currentUserId
          ? IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Remove member?'),
                    content: Text('Xóa ${u['name'] ?? u['email']} khỏi nhóm?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Xóa')),
                    ],
                  ),
                );
                if (ok == true) {
                  await MembershipService.removeMember(
                    widget.groupId,
                    m['id'] as String,
                  );
                  widget.onRefresh();
                }
              },
            )
          : null,
    );
  }
}

class TasksTab extends StatelessWidget {
  final List<dynamic> tasks;
  const TasksTab({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tasks (${tasks.length})',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...tasks.map((t) => ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(t['title']),
              subtitle: Text('Trạng thái: ${t['status']}'),
            )),
      ],
    );
  }
}
