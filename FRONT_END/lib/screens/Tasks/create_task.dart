// create_task.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/services/task_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final String groupId;
  const CreateTaskScreen({super.key, required this.groupId});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  DateTime? _deadline;
  bool _saving = false;

  Future<void> _submit() async {
    final title = _titleCtl.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    try {
      await TaskService.createTask(
        widget.groupId,
        title: title,
        description: _descCtl.text.trim(),
        deadline: _deadline,
      );
      if (mounted) Navigator.pop(context, true); // return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi khi tạo task: $e'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _titleCtl,
                decoration: const InputDecoration(labelText: 'Tiêu đề')),
            TextField(
                controller: _descCtl,
                decoration: const InputDecoration(labelText: 'Mô tả')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_deadline == null
                      ? 'Chọn ngày'
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
                  child: const Text('Chọn'),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Tạo Task'),
            ),
          ],
        ),
      ),
    );
  }
}
