import 'package:flutter/material.dart';
import 'package:task_manager_app/services/membership_service.dart';
import 'package:task_manager_app/services/auth_service.dart';

/* ───────────── search bar (unchanged) ───────────── */
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const SearchBarWidget(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search members...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/* ───────────── Members tab (UI identical to original) ───────────── */
class MembersTab extends StatefulWidget {
  final String groupId;
  final String ownerId;
  final List<dynamic> allMembers;
  final List<dynamic> admins;
  final List<dynamic> members;
  final bool isAdmin;
  final VoidCallback onRefresh;

  const MembersTab({
    super.key,
    required this.groupId,
    required this.ownerId,
    required this.allMembers,
    required this.admins,
    required this.members,
    required this.isAdmin,
    required this.onRefresh,
  });

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _removing = false;
  String? _removingId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _filterMembers(List<dynamic> list) {
    return list.where((m) {
      final user = (m['expand']?['user']) as Map<String, dynamic>?;
      final name = user?['name']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _onRemovePressed(dynamic m) async {
    final user = (m['expand'] as Map)['user'] as Map<String, dynamic>;
    final name = user['name'] ?? 'this user';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove $name from group?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _removing = true;
      _removingId = m['id'] as String?;
    });

    try {
      await MembershipService.removeMember(
        widget.groupId, // ← keep both args
        m['id'] as String,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed')),
        );
      }
      widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _removing = false;
          _removingId = null;
        });
      }
    }
  }

  Widget _memberTile(dynamic m) {
    final u = (m['expand'] as Map)['user'] as Map<String, dynamic>;
    final targetId = u['id'] as String;
    final targetRole = m['role'] as String? ?? 'member';

    final bool callerIsOwner = widget.ownerId == AuthService.currentUserId;
    final bool callerIsAdmin = widget.isAdmin;

    bool canRemove = callerIsOwner || callerIsAdmin;
    canRemove &= targetId != AuthService.currentUserId;
    canRemove &= targetId != widget.ownerId;
    if (!callerIsOwner && targetRole == 'admin') canRemove = false;

    final avatarUrl = u['avatarUrl'] as String?;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(u['name'] ?? 'Unnamed'),
      subtitle: Text(targetRole.toUpperCase()),
      trailing: (_removing && _removingId == m['id'])
          ? const SizedBox(
              width: 24, height: 24, child: CircularProgressIndicator())
          : canRemove
              ? IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _onRemovePressed(m),
                )
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admins = _filterMembers(widget.admins);
    final members = _filterMembers(widget.members);

    return Column(
      children: [
        SearchBarWidget(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (admins.isNotEmpty) ...[
                Text('Admins (${admins.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...admins.map(_memberTile),
                const SizedBox(height: 20),
              ],
              Text('Members (${members.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...members.map(_memberTile),
            ],
          ),
        ),
      ],
    );
  }
}
