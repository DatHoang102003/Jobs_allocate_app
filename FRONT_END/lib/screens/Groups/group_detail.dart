import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/screens/Tasks/create_task.dart';
import 'package:task_manager_app/services/group_service.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/task_service.dart';
import 'package:task_manager_app/services/auth_service.dart';           // NEW

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _loading = true;
  bool _savingGroup = false;
  Map<String, dynamic>? detail; // {group, members, tasks}

  /* ───────────────── fetch all data ───────────────── */
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

      setState(() {
        detail = {
          'group': groupDetail['group'],
          'members': members,
          'tasks': groupDetail['tasks'] ?? [],
        };
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        setState(() => _loading = false);
      }
    }
  }

  /* ───────────────── edit group info ───────────────── */
  Future<void> _editGroup() async {
    final g = detail!['group'];
    final nameCtl = TextEditingController(text: g['name']);
    final descCtl = TextEditingController(text: g['description'] ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa nhóm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Tên')),
            TextField(
                controller: descCtl,
                decoration: const InputDecoration(labelText: 'Mô tả')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _savingGroup = true);
    try {
      final updated = await GroupService.updateGroup(
        widget.groupId,
        name: nameCtl.text.trim(),
        description: descCtl.text.trim(),
      );
      setState(() => detail!['group'] = updated);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _savingGroup = false);
    }
  }

  /* ───────────────── add task (new dialog) ───────────────── */
  Future<void> _openCreateTaskDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        child: CreateTaskScreen(groupId: widget.groupId),
      ),
    );
    if (created == true) await _fetch();
  }

  /* ───────────────── build ───────────────── */
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
    final tasks = detail!['tasks'] as List;
    final created =
        DateFormat('dd/MM/yyyy').format(DateTime.parse(g['created']));
    final allMembers = detail!['members'] as List<dynamic>;

    /* current-user permissions */
    final meId = AuthService.currentUserId;                   // adjust to your auth
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

    return Scaffold(
      appBar: AppBar(
        title: Text(g['name']),
        actions: [
          IconButton(
            icon: _savingGroup
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit),
            onPressed: _savingGroup ? null : _editGroup,
          ),
        ],
      ),

      /* add-task FAB */
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTaskDialog,
        child: const Icon(Icons.add),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /* group info */
          Card(
            child: ListTile(
              title: Text(g['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(g['description'] ?? ''),
              trailing: Text('Tạo: $created'),
            ),
          ),
          const SizedBox(height: 20),

          /* admins */
          if (admins.isNotEmpty) ...[
            Text('Admins (${admins.length})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...admins.map((m) => _memberTile(m, isAdmin)),
            const SizedBox(height: 20),
          ],

          /* members */
          Text('Members (${members.length})',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...members.map((m) => _memberTile(m, isAdmin)),
          const SizedBox(height: 20),

          /* tasks */
          Text('Tasks (${tasks.length})',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...tasks.map((t) => ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(t['title']),
                subtitle: Text('Trạng thái: ${t['status']}'),
              )),
        ],
      ),
    );
  }

  /* ───────────────── member row ───────────────── */
  Widget _memberTile(dynamic m, bool canRemove) {
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
                if (ok != true) return;

                await MembershipService.removeMember(
                  widget.groupId,
                  m['id'] as String,
                );
                await _fetch();
              },
            )
          : null,
    );
  }
}
