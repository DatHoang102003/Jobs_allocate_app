import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/services/group_service.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/task_service.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _loading = true;
  bool _savingGroup = false;
  bool _savingTask = false;
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

  /* ─── Edit Group (unchanged) ──────────────────────────────── */
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
      setState(() {
        detail!['group'] = updated;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _savingGroup = false);
    }
  }

  /* ─── Add Task Dialog ─────────────────────────────────────── */
  Future<void> _showAddTaskDialog() async {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    DateTime? pickedDate;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setInner) {
          return AlertDialog(
            title: const Text('Thêm Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleCtl,
                    decoration: const InputDecoration(labelText: 'Tiêu đề')),
                TextField(
                    controller: descCtl,
                    decoration: const InputDecoration(labelText: 'Mô tả')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(pickedDate == null
                          ? 'Chọn ngày'
                          : DateFormat('dd/MM/yyyy').format(pickedDate!)),
                    ),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setInner(() => pickedDate = d);
                      },
                      child: const Text('Chọn'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Thêm')),
            ],
          );
        });
      },
    );

    if (ok != true || titleCtl.text.trim().isEmpty) return;

    setState(() => _savingTask = true);
    try {
      await TaskService.createTask(
        widget.groupId,
        title: titleCtl.text.trim(),
        description: descCtl.text.trim(),
        deadline: pickedDate,
      );
      await _fetch(); // reload list of tasks
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã thêm task')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi thêm task: $e')));
    } finally {
      if (mounted) setState(() => _savingTask = false);
    }
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
    final tasks = detail!['tasks'] as List;
    final created =
        DateFormat('dd/MM/yyyy').format(DateTime.parse(g['created']));
    final allMembers = detail!['members'] as List<dynamic>;
    final admins = allMembers.where((m) {
      final role = m['role'] as String? ?? 'member';
      final u = (m['expand'] as Map?)?['user'] as Map<String, dynamic>?;
      return role == 'admin' || (u?['id'] == g['owner']);
    }).toList();

    final members = allMembers.where((m) {
      final role = m['role'] as String? ?? 'member';
      final u = (m['expand'] as Map?)?['user'] as Map<String, dynamic>?;
      return !(role == 'admin' || (u?['id'] == g['owner']));
    }).toList();

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

      /* ─── Add-Task FAB ───────────────────────────────────────── */
      floatingActionButton: FloatingActionButton.extended(
        icon: _savingTask
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_task),
        label: const Text('Thêm Task'),
        onPressed: _savingTask ? null : _showAddTaskDialog,
      ),

      /* ─── Main body ─────────────────────────────────────────── */
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /* Group info card */
          Card(
            child: ListTile(
              title: Text(g['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(g['description'] ?? ''),
              trailing: Text('Tạo: $created'),
            ),
          ),
          const SizedBox(height: 20),

          /* Admins */
          if (admins.isNotEmpty) ...[
            Text('Admins (${admins.length})',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...admins.map(_memberTile),
            const SizedBox(height: 20),
          ],

          /* Members */
          Text('Members (${members.length})',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...members.map(_memberTile),
          const SizedBox(height: 20),

          /* Tasks */
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

  /* ─── Renders one member row ───────────────────────────── */
  Widget _memberTile(dynamic m) {
    final expanded = m['expand'] as Map<String, dynamic>?;
    final u = expanded?['user'] as Map<String, dynamic>?;
    final avatarUrl = u?['avatarUrl'] as String?;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(u?['name'] ?? 'Unknown'),
      subtitle: Text(u?['email'] ?? ''),
    );
  }
}
