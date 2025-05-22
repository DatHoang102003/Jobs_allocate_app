import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/services/group_service.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? detail; // {group, members, tasks}

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final d = await GroupService.getGroupDetail(widget.groupId);
      if (mounted) setState(() => detail = d);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* --------------- dialog to edit name/desc ---------------- */
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

    setState(() => _saving = true);
    try {
      final updated = await GroupService.updateGroup(
        widget.groupId,
        name: nameCtl.text.trim(),
        description: descCtl.text.trim(),
      );
      setState(() {
        detail!['group'] = updated; // refresh local copy
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final members = detail!['members'] as List;
    final tasks = detail!['tasks'] as List;

    final created =
        DateFormat('dd/MM/yyyy').format(DateTime.parse(g['created']));

    return Scaffold(
      appBar: AppBar(
        title: Text(g['name']),
        actions: [
          IconButton(
            icon: _saving
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.edit),
            onPressed: _saving ? null : _editGroup,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /* ------------ Group info card ------------ */
          Card(
            child: ListTile(
              title: Text(g['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(g['description'] ?? ''),
              trailing: Text('Tạo: $created'),
            ),
          ),
          const SizedBox(height: 20),

          /* ------------ Members ------------ */
          Text('Member (${members.length})',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...members.map((m) {
            final u = m['expand']['user'];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: u['avatarUrl'] != null
                    ? NetworkImage(u['avatarUrl'])
                    : null,
                child: u['avatarUrl'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(u['name'] ?? ''),
              subtitle: Text(m['role']),
            );
          }),
          const SizedBox(height: 20),

          /* ------------ Tasks ------------ */
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
}
