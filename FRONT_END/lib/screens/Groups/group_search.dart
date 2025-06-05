import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/groups.dart';
import '../Auth/auth_manager.dart';
import 'Group_detail/group_detail.dart';
import 'groups_manager.dart';

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
    await Future.delayed(Duration.zero); // Đợi frame hiện tại kết thúc

    if (keyword.trim().isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    try {
      final groupProvider = context.read<GroupsProvider>();
      final results = await groupProvider.searchGroups(keyword);
      if (mounted) setState(() => _searchResults = results);
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
          final adminName =
              group.owner.isNotEmpty ? group.owner : 'Unknown Admin';

          return ListTile(
            title: Text(group.name),
            subtitle: Text('Admin: $adminName'),
            onTap: () {
              context.read<GroupsProvider>().setCurrent(group);
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
      ),
    );
  }
}
