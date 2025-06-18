import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'tasks_manager.dart';

Future<void> showTaskEditDialog({
  required BuildContext context,
  required String taskId,
  required Map<String, dynamic> initialTask,
}) async {
  final tasksProvider = context.read<TasksProvider>();
  TextEditingController titleController =
      TextEditingController(text: initialTask['title'] ?? '');
  TextEditingController descriptionController =
      TextEditingController(text: initialTask['description'] ?? '');
  DateTime? deadline = initialTask['deadline'] != null
      ? DateTime.tryParse(initialTask['deadline'].toString())
      : null;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Edit Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: deadline ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          deadline = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              deadline?.hour ?? 0,
                              deadline?.minute ?? 0);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date'),
                        child: Text(deadline != null
                            ? DateFormat('dd/MM/yyyy').format(deadline!)
                            : ''),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                              deadline ?? DateTime.now()),
                        );
                        if (picked != null && deadline != null) {
                          deadline = DateTime(deadline!.year, deadline!.month,
                              deadline!.day, picked.hour, picked.minute);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Time'),
                        child: Text(deadline != null
                            ? DateFormat('hh:mm a').format(deadline!)
                            : ''),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await tasksProvider.updateTask(
                  taskId,
                  title: titleController.text.isNotEmpty
                      ? titleController.text
                      : null,
                  description: descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : null,
                  deadline: deadline,
                  assignees: null,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating task: $e')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
}
