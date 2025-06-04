import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/join_service.dart';
import '../../Members/join_manager.dart';

class JoinRequestsTab extends StatefulWidget {
  final String groupId;
  final VoidCallback onUpdate; // ← callback to notify parent

  const JoinRequestsTab({
    super.key,
    required this.groupId,
    required this.onUpdate,
  });

  @override
  State<JoinRequestsTab> createState() => _JoinRequestsTabState();
}

class _JoinRequestsTabState extends State<JoinRequestsTab> {
  bool _loading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    // Defer until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      _requests = await JoinService.listGroupJoinRequests(widget.groupId);
    } catch (e) {
      debugPrint('Failed to fetch join requests: $e');
      _requests = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handle(
    String jrId,
    Future<void> Function(String) action,
  ) async {
    try {
      await action(jrId);
      if (!mounted) return;

      // Remove from local list
      setState(() => _requests.removeWhere((r) => r['id'] == jrId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request updated ✔')),
      );

      // Notify parent to refresh members
      widget.onUpdate();
    } catch (e) {
      debugPrint('Update failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_requests.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }

    // Use JoinManager for approve/reject methods
    final joinManager = context.read<JoinManager>();

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _requests.length,
        itemBuilder: (_, i) {
          final r = _requests[i];
          final user = r['expand']?['user'] as Map<String, dynamic>? ?? {};
          final userName = user['name'] as String? ?? 'Unknown';
          final avatarUrl = user['avatar'] as String?;

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?')
                  : null,
            ),
            title: Text(userName),
            subtitle: const Text('wants to join'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Approve',
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _handle(
                      r['id'] as String, joinManager.approveJoinRequest),
                ),
                IconButton(
                  tooltip: 'Reject',
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () =>
                      _handle(r['id'] as String, joinManager.rejectJoinRequest),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
