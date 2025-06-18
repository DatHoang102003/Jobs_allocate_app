import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/task_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final String groupId;
  const CreateTaskScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  DateTime? _deadline;
  bool _saving = false;

  // Multi-assignee support
  final Set<String> _selectedUserIds = {};
  List<Map<String, dynamic>> _members = [];
  bool _loadingMembers = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final raw = await MembershipService.listMembersOfGroup(widget.groupId);
      setState(() {
        _members = raw.cast<Map<String, dynamic>>();
        _loadingMembers = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading members: $e')));
      }
      setState(() => _loadingMembers = false);
    }
  }

  void _openMemberSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: [
          for (var m in _members)
            (() {
              final userMap =
                  (m['expand'] as Map?)?['user'] as Map<String, dynamic>?;
              if (userMap == null) return const SizedBox();
              final userId = userMap['id'] as String;
              final name = userMap['name'] as String? ??
                  userMap['email'] as String? ??
                  'Unknown';
              final avatarUrl = userMap['avatarUrl'] as String?;
              final selected = _selectedUserIds.contains(userId);

              return ListTile(
                leading: avatarUrl != null
                    ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
                    : CircleAvatar(child: Text(name.characters.first)),
                title: Text(name),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    if (selected)
                      _selectedUserIds.remove(userId);
                    else
                      _selectedUserIds.add(userId);
                  });
                  Navigator.pop(context);
                },
              );
            })(),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _deadline = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _deadline?.hour ?? 0,
          _deadline?.minute ?? 0,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now()),
    );
    if (pickedTime != null && mounted) {
      setState(() {
        _deadline = DateTime(
          _deadline?.year ?? DateTime.now().year,
          _deadline?.month ?? DateTime.now().month,
          _deadline?.day ?? DateTime.now().day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleCtl.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    try {
      await TaskService.createTask(
        widget.groupId,
        title: title,
        description: _descCtl.text.trim(),
        assignees:
            _selectedUserIds.isNotEmpty ? _selectedUserIds.toList() : null,
        deadline: _deadline,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error creating task: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task ToDo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Added SingleChildScrollView to handle overflow
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text('Title Task',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtl,
              decoration: const InputDecoration(
                hintText: 'Add Task Name..',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Description
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add Descriptions..',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Assignees
            const Text('Assignees (optional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _loadingMembers
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 60,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (var uid in _selectedUserIds)
                          (() {
                            final m = _members.firstWhere(
                              (m) =>
                                  ((m['expand'] as Map)['user']['id']
                                      as String) ==
                                  uid,
                              orElse: () => {},
                            );
                            final userMap = (m['expand'] as Map?)?['user']
                                as Map<String, dynamic>?;
                            if (userMap == null) return const SizedBox();
                            final avatar = userMap['avatarUrl'] as String?;
                            final name = userMap['name'] as String? ??
                                userMap['email'] as String? ??
                                'U';
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundImage: avatar != null
                                    ? NetworkImage(avatar)
                                    : null,
                                child: avatar == null
                                    ? Text(name.characters.first)
                                    : null,
                              ),
                            );
                          })(),
                        GestureDetector(
                          onTap: _loadingMembers ? null : _openMemberSelector,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.deepPurple),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                const Icon(Icons.add, color: Colors.deepPurple),
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 16),
            // Date & Time
            const Text('Date'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _deadline == null
                          ? 'dd/mm/yy'
                          : DateFormat('dd/MM/yy').format(_deadline!),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _deadline == null
                          ? 'hh:mm'
                          : DateFormat('HH:mm').format(_deadline!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
