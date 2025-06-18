import 'package:flutter/material.dart';
import '../../services/group_service.dart';
import '../../services/invite_service.dart';
import '../../services/user_service.dart';
import 'Group_detail/group_detail.dart';

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final Set<String> selectedMemberIds = {};
  List<dynamic> allUsers = [];

  bool _isCreating = false;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await UserService.getAllUsers();
      final currentUserId =
          await UserService.getCurrentUserId(); // Assume this method exists
      setState(() => allUsers =
          users.where((user) => user['id'] != currentUserId).toList());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load users: $e")),
      );
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  void _openUserSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: allUsers.map((user) {
          final id = user['id'];
          final name = user['name'];
          final isSelected = selectedMemberIds.contains(id);

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user['avatarUrl'] != null
                  ? NetworkImage(user['avatarUrl'])
                  : null,
              child: user['avatarUrl'] == null ? Text(name[0]) : null,
            ),
            title: Text(name),
            trailing: isSelected ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedMemberIds.remove(id);
                } else {
                  selectedMemberIds.add(id);
                }
              });
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Create group",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Group name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text("Members",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var id in selectedMemberIds)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundImage: allUsers.firstWhere(
                                    (u) => u['id'] == id)['avatarUrl'] !=
                                null
                            ? NetworkImage(allUsers
                                .firstWhere((u) => u['id'] == id)['avatarUrl'])
                            : null,
                        child: allUsers.firstWhere(
                                    (u) => u['id'] == id)['avatarUrl'] ==
                                null
                            ? Text(
                                allUsers.firstWhere(
                                    (u) => u['id'] == id)['name'][0],
                              )
                            : null,
                      ),
                    ),
                  GestureDetector(
                    onTap: _isLoadingUsers ? null : _openUserSelector,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurple),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoadingUsers
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add, color: Colors.deepPurple),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isCreating
                  ? null
                  : () async {
                      final name = _nameController.text.trim();
                      final desc = _descController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Group name cannot be empty")),
                        );
                        return;
                      }

                      setState(() => _isCreating = true);

                      try {
                        final response = await GroupService.createGroup(
                          name: name,
                          description: desc,
                          isPublic: true,
                        );

                        final groupId = response['group']['id'];

                        // Send invites to selected members
                        for (final userId in selectedMemberIds) {
                          print('Inviting user $userId to group $groupId');
                          try {
                            await InviteService.sendInviteRequest(
                                groupId, userId);
                          } catch (e) {
                            debugPrint("Failed to invite $userId: $e");
                          }
                        }

                        if (!context.mounted) return;

                        // Navigate to GroupDetailScreen instead of popping
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GroupDetailScreen(groupId: groupId),
                          ),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Group created successfully"),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Failed to create group: ${e.toString()}")),
                        );
                      } finally {
                        if (mounted) setState(() => _isCreating = false);
                      }
                    },
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward, color: Colors.white),
              label: const Text(
                "Create",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
