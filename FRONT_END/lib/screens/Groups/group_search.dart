import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/groups.dart';
import '../Auth/auth_manager.dart';
import '../Members/join_manager.dart';
import '../Members/membership_manager.dart';
import 'Group_detail/group_detail.dart';
import 'groups_manager.dart';

enum UserGroupStatus { admin, member, pending, notJoined }

/* ─────────────────────────────────────────────
   Helper: decide current user’s relationship
───────────────────────────────────────────── */
Future<UserGroupStatus> checkUserGroupStatus({
  required String groupId,
  required String userId,
  required GroupsProvider groupsProvider,
  required MemberManager memberManager,
  required JoinManager joinManager,
}) async {
  if (groupsProvider.adminGroups.any((g) => g.id == groupId)) {
    return UserGroupStatus.admin;
  }
  if (groupsProvider.memberGroups.any((g) => g.id == groupId)) {
    return UserGroupStatus.member;
  }
  if (joinManager.isPending(groupId)) return UserGroupStatus.pending;

  await memberManager.fetchMembers(groupId, myUserId: userId);
  if (memberManager.isUserMember(userId)) return UserGroupStatus.member;

  if (joinManager.joinRequests.isEmpty) {
    await joinManager.fetchJoinRequests();
    if (joinManager.isPending(groupId)) return UserGroupStatus.pending;
  }
  return UserGroupStatus.notJoined;
}

/* ─────────────────────────────────────────────
   Widget
───────────────────────────────────────────── */
class GroupSearch extends StatefulWidget {
  const GroupSearch({super.key});

  @override
  State<GroupSearch> createState() => _GroupSearchState();
}

class _GroupSearchState extends State<GroupSearch> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<Group> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String keyword) async {
    // wait until the current build frame is done
    await Future.delayed(Duration.zero);

    if (keyword.trim().isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    try {
      final groupProvider = context.read<GroupsProvider>();
      final results = await groupProvider.searchGroups(keyword);
      if (mounted) setState(() => _searchResults = results);

      await context.read<JoinManager>().fetchJoinRequests();
    } catch (e) {
      debugPrint("Search failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authManager = context.watch<AuthManager>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _searchBox(),
        const SizedBox(height: 16),
        if (_searchResults.isNotEmpty)
          _buildSearchResultsCard(authManager.userId),
      ],
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: _handleSearch,
      decoration: InputDecoration(
        hintText: 'Search group.',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            setState(() => _searchResults = []);
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }

  Widget _buildSearchResultsCard(String? currentUserId) {
    if (currentUserId == null) {
      return const Center(child: Text('User not logged in'));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final group = _searchResults[index];
          final memberManager = context.read<MemberManager>();
          final groupsProvider = context.read<GroupsProvider>();
          final joinManager = context.read<JoinManager>();
          final adminName =
              group.owner.isNotEmpty ? group.owner : 'Unknown Admin';

          return FutureBuilder<UserGroupStatus>(
            future: checkUserGroupStatus(
              groupId: group.id,
              userId: currentUserId,
              groupsProvider: groupsProvider,
              memberManager: memberManager,
              joinManager: joinManager,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(title: Text('Loading...'));
              }

              final userStatus = snapshot.data ?? UserGroupStatus.notJoined;

              Color _btnColor() {
                switch (userStatus) {
                  case UserGroupStatus.admin:
                  case UserGroupStatus.pending:
                    return Colors.grey;
                  case UserGroupStatus.member:
                    return Colors.redAccent;
                  default:
                    return Colors.green;
                }
              }

              String _btnLabel() {
                switch (userStatus) {
                  case UserGroupStatus.admin:
                    return 'Owner';
                  case UserGroupStatus.member:
                    return 'Leave';
                  case UserGroupStatus.pending:
                    return 'Pending';
                  default:
                    return 'Join';
                }
              }

              return ListTile(
                title: Text(group.name),
                subtitle: Text('Admin: $adminName'),
                trailing: ElevatedButton(
                  onPressed: (userStatus == UserGroupStatus.admin ||
                          userStatus == UserGroupStatus.pending)
                      ? null
                      : () async {
                          try {
                            if (userStatus == UserGroupStatus.member) {
                              await memberManager.leaveGroup();
                            } else {
                              await joinManager.sendJoinRequest(group.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Join request sent 🎉'),
                                ),
                              );
                            }

                            final updated = await groupsProvider
                                .searchGroups(_searchController.text);
                            if (mounted)
                              setState(() => _searchResults = updated);
                          } catch (e) {
                            debugPrint('Action failed: $e');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _btnColor(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(_btnLabel()),
                ),
                onTap: () {
                  groupsProvider.setCurrent(group);
                  _searchController.clear();
                  setState(() => _searchResults = []);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(groupId: group.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
