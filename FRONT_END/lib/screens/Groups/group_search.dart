import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/groups.dart';
import '../Auth/auth_manager.dart';
import '../Members/join_manager.dart';
import '../Members/membership_manager.dart';
import 'Group_detail/group_detail.dart';
import 'groups_manager.dart';

enum UserGroupStatus { admin, member, notJoined }

Future<UserGroupStatus> checkUserGroupStatus({
  required String groupId,
  required String userId,
  required GroupsProvider groupsProvider,
  required MemberManager memberManager,
}) async {
  if (groupsProvider.adminGroups.any((group) => group.id == groupId)) {
    return UserGroupStatus.admin;
  }

  if (groupsProvider.memberGroups.any((group) => group.id == groupId)) {
    return UserGroupStatus.member;
  }

  await memberManager.fetchMembers(groupId, myUserId: userId);
  if (memberManager.isUserMember(userId)) {
    return UserGroupStatus.member;
  }

  return UserGroupStatus.notJoined;
}

class GroupSearch extends StatefulWidget {
  const GroupSearch({super.key});

  @override
  State<GroupSearch> createState() => _GroupSearchState();
}

class _GroupSearchState extends State<GroupSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Group> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final groupProvider = Provider.of<GroupsProvider>(context, listen: false);
      final results = await groupProvider.searchGroups(keyword);
      setState(() => _searchResults = results);
    } catch (e) {
      debugPrint("Search failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authManager = Provider.of<AuthManager>(context);

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
        hintText: "Search group...",
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
      return const Center(child: Text("User not logged in"));
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
          final memberManager =
              Provider.of<MemberManager>(context, listen: false);
          final groupsProvider =
              Provider.of<GroupsProvider>(context, listen: false);
          final adminName =
              group.owner.isNotEmpty ? group.owner : "Unknown Admin";

          return FutureBuilder<UserGroupStatus>(
            future: checkUserGroupStatus(
              groupId: group.id,
              userId: currentUserId,
              groupsProvider: groupsProvider,
              memberManager: memberManager,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(title: Text("Loading..."));
              }

              final userStatus = snapshot.data ?? UserGroupStatus.notJoined;

              return ListTile(
                title: Text(group.name),
                subtitle: Text("Admin: $adminName"),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final joinManager =
                        Provider.of<JoinManager>(context, listen: false);
                    try {
                      if (userStatus == UserGroupStatus.admin) return;
                      if (userStatus == UserGroupStatus.member) {
                        await memberManager.leaveGroup();
                      } else {
                        await joinManager.sendJoinRequest(group.id);
                      }

                      final updatedResults = await groupsProvider
                          .searchGroups(_searchController.text);
                      setState(() => _searchResults = updatedResults);
                    } catch (e) {
                      debugPrint("Action failed: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: userStatus == UserGroupStatus.admin
                        ? Colors.grey
                        : (userStatus == UserGroupStatus.member
                            ? Colors.redAccent
                            : Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    userStatus == UserGroupStatus.admin
                        ? "Owner"
                        : (userStatus == UserGroupStatus.member
                            ? "Leave"
                            : "Join"),
                  ),
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
