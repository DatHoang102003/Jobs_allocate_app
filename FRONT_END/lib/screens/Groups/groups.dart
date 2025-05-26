import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Groups/groups_manager.dart';
import 'package:task_manager_app/screens/home.dart' show CustomDrawer;
import '../../models/groups.dart';
import '../../services/invite_service.dart';
import 'edit_dialog.dart';
import 'group_detail.dart';

class GroupScreen extends StatefulWidget {
  static const routeName = '/groups';
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsProvider>().fetchGroups();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onGroupEdited(Group updated) =>
      context.read<GroupsProvider>().updateGroup(updated);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupsProvider>();

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text("Groups"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: provider.currentGroup == null
                ? null
                : () {
                    showEditGroupDialog(
                      context,
                      provider.currentGroup!,
                      _onGroupEdited,
                    );
                  },
          ),
        ],
        automaticallyImplyLeading: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.deepPurple),
            insets: EdgeInsets.symmetric(horizontal: 16.0),
          ),
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Requests"),
            Tab(text: "Tasks"),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(provider),
                const InviteRequestsTab(),
                const Center(child: Text("Tasks tab content")),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(GroupsProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: provider.groups.length,
      itemBuilder: (context, index) {
        final group = provider.groups[index];

        return GestureDetector(
          onTap: () {
            provider.setCurrent(group);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailScreen(groupId: group.id),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EDFF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(group.description,
                    style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                        "Created: ${group.created.toLocal().toIso8601String().split('T').first}"),
                    const SizedBox(width: 16),
                    const Icon(Icons.update, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                        "Updated: ${group.updated.toLocal().toIso8601String().split('T').first}"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class InviteRequestsTab extends StatefulWidget {
  const InviteRequestsTab({super.key});

  @override
  State<InviteRequestsTab> createState() => _InviteRequestsTabState();
}

class _InviteRequestsTabState extends State<InviteRequestsTab> {
  List<dynamic> _invites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final inviteRes = await InviteService.listMyInvites();
      print('Fetched invites: $inviteRes'); // ✅ Kiểm tra dữ liệu
      setState(() {
        _invites = inviteRes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching requests/invites: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptInvite(String id) async {
    await InviteService.acceptInvite(id);
    _fetchData();
  }

  Future<void> _rejectInvite(String id) async {
    await InviteService.rejectInvite(id);
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Join Requests",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                const Text("Invites",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._invites.map((inv) {
                  final group = inv['expand']?['group'];
                  final groupName =
                      group is Map ? group['name'] : 'Unknown Group';
                  return Card(
                    child: ListTile(
                      title: Text(groupName),
                      subtitle: const Text("You’ve been invited to join"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _acceptInvite(inv['id'])),
                          IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectInvite(inv['id'])),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
  }
}
