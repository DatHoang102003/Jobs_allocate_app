// create_task.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/task_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final String groupId;
  const CreateTaskScreen({super.key, required this.groupId});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  /* ── Form state ───────────────────────────────────────── */
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  DateTime? _deadline;
  String? _assigneeId; // ← picked user.id

  /* ── Data ─────────────────────────────────────────────── */
  List<Map<String, dynamic>> _members = []; // expanded memberships
  bool _loadingMembers = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final rawList =
          await MembershipService.listMembersOfGroup(widget.groupId);
      final list = rawList.map((e) => e as Map<String, dynamic>).toList();

      setState(() {
        _members = list;
        _loadingMembers = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $e')),
        );
      }
      setState(() => _loadingMembers = false);
    }
  }

  /* ── Submit ───────────────────────────────────────────── */
  Future<void> _submit() async {
    final title = _titleCtl.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    try {
      await TaskService.createTask(
        widget.groupId,
        title: title,
        description: _descCtl.text.trim(),
        assignee: _assigneeId, // may be null
        deadline: _deadline,
      );
      if (mounted) Navigator.pop(context, true); // success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating task: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /* ── UI ──────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /* Title + description */
            TextField(
                controller: _titleCtl,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: _descCtl,
                decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 16),

            /* Deadline picker */
            Row(
              children: [
                Expanded(
                  child: Text(_deadline == null
                      ? 'Select date'
                      : DateFormat('dd/MM/yyyy').format(_deadline!)),
                ),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _deadline = d);
                  },
                  child: const Text('Select'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /* Assignee dropdown */
            _loadingMembers
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _assigneeId,
                    decoration:
                        const InputDecoration(labelText: 'Assignee (optional)'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Unassigned')),
                      ..._members.map((m) {
                        final u = (m['expand'] as Map?)?['user']
                            as Map<String, dynamic>?;
                        if (u == null) return null;
                        return DropdownMenuItem(
                          value: u['id'] as String,
                          child: Text(u['name'] ?? u['email'] ?? 'Unknown'),
                        );
                      }).whereType<DropdownMenuItem<String>>(),
                    ],
                    onChanged: (val) => setState(() => _assigneeId = val),
                  ),
            const Spacer(),

            /* Submit button */
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }
}
