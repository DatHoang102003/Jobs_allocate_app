import 'package:flutter/material.dart';
import '../../models/groups.dart';

Future<void> showEditGroupDialog(
  BuildContext context,
  Group group,
  Function(Group) onUpdate,
) async {
  final nameController = TextEditingController(text: group.name);
  final descriptionController = TextEditingController(text: group.description);

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedGroup = Group(
                id: group.id,
                name: nameController.text,
                description: descriptionController.text,
                owner: group.owner,
                created: group.created,
                updated: DateTime.now(),
              );
              onUpdate(updatedGroup);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
