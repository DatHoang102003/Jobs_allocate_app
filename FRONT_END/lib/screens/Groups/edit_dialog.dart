import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/groups.dart';
import 'groups_manager.dart';

Future<void> showEditGroupDialog(
  BuildContext context,
  Group group,
  void Function(Group updated) onGroupEdited,
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
          // ElevatedButton(
          //   // onPressed: () async {
          //   //   try {
          //   //     // Access GroupsProvider to call updateGroupInfo
          //   //     await Provider.of<GroupsProvider>(context, listen: false)
          //   //         .updateGroupInfo(
          //   //       id: group.id,
          //   //       name: nameController.text,
          //   //       description: descriptionController.text,
          //   //     );
          //   //     Navigator.of(context).pop();
          //   //   } catch (e) {
          //   //     // Show error message
          //   //     ScaffoldMessenger.of(context).showSnackBar(
          //   //       SnackBar(content: Text('Failed to update group: $e')),
          //   //     );
          //   //   }
          //   // },
          //   style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          //   child: const Text('Save'),
          // ),
        ],
      );
    },
  );
}
