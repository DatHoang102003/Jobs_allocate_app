// lib/screens/Groups/invite_requests_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Members/invites_manager.dart';
import 'package:task_manager_app/services/user_service.dart';

class InviteRequestsTab extends StatefulWidget {
  final String groupId;
  const InviteRequestsTab({super.key, required this.groupId});

  @override
  State<InviteRequestsTab> createState() => _InviteRequestsTabState();
}

class _InviteRequestsTabState extends State<InviteRequestsTab> {
  @override
  void initState() {
    super.initState();
    // Initial load
    context.read<InviteManager>().fetchInvites(widget.groupId);
  }

  /* ───────────────────────────────
   *  Dialog: pick one user to invite
   * ─────────────────────────────── */
  Future<String?> _pickUser(BuildContext ctx) async {
    final users = await UserService.getAllUsers(); // [{id,name,email}, …]
    String? selected;

    return showDialog<String>(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite member'),
          content: users.isEmpty
              ? const CircularProgressIndicator()
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    children: users.map((u) {
                      final label =
                          (u['name'] ?? u['username'] ?? u['email']) as String;
                      return RadioListTile<String>(
                        value: u['id'],
                        groupValue: selected,
                        title: Text(label),
                        subtitle: Text(u['email']),
                        onChanged: (v) => setState(() => selected = v),
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(context, selected),
              child: const Text('INVITE'),
            ),
          ],
        ),
      ),
    );
  }

  /* ───────────────────────────────
   *  Send invite helper
   * ─────────────────────────────── */
  Future<void> _sendInvite(BuildContext ctx) async {
    final userId = await _pickUser(ctx);
    if (userId == null) return;

    final im = ctx.read<InviteManager>();
    try {
      await im.sendInvite(widget.groupId, userId);
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Invite sent 🎉')),
        );
      }
    } catch (e) {
      debugPrint('sendInvite error: $e');
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Failed to send invite')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final im = context.watch<InviteManager>();

    return Stack(
      children: [
        // --------------- List ---------------
        RefreshIndicator(
          onRefresh: () => im.fetchInvites(widget.groupId),
          child: im.isLoading
              ? const Center(child: CircularProgressIndicator())
              : (im.invitesOf(widget.groupId).isEmpty
                  ? const Center(child: Text('No pending invites'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: im.invitesOf(widget.groupId).length,
                      itemBuilder: (_, i) {
                        final inv = im.invitesOf(widget.groupId)[i];
                        final invitee =
                            inv['expand']?['invitee'] ?? inv['invitee'];
                        final name = invitee?['name'] ??
                            invitee?['username'] ??
                            invitee?['email'] ??
                            'Unknown user';

                        return Card(
                          child: ListTile(
                            title: Text(name),
                            subtitle: const Text('Invite pending'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  im.cancelInvite(widget.groupId, inv['id']),
                              tooltip: 'Cancel invite',
                            ),
                          ),
                        );
                      },
                    )),
        ),
        // -------- Floating Invite Button --------
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: im.isLoading ? null : () => _sendInvite(context),
            tooltip: 'Invite member',
            child: const Icon(Icons.person_add),
          ),
        ),
      ],
    );
  }
}
