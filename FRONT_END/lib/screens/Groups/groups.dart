import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Groups/groups_manager.dart';
import 'package:task_manager_app/screens/home.dart' show CustomDrawer;
import '../../models/groups.dart';
import '../../services/invite_service.dart';
import '../../services/task_service.dart';
import 'Group_detail/group_detail.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class GroupScreen extends StatefulWidget {
  static const routeName = '/groups';
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedRole = 'all';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupsProvider>();

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text("Groups"),
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
    List<Group> groupsToShow;
    switch (_selectedRole) {
      case 'admin':
        groupsToShow = provider.adminGroups;
        break;
      case 'member':
        groupsToShow = provider.memberGroups;
        break;
      default:
        groupsToShow = [...provider.adminGroups, ...provider.memberGroups];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DropdownButton<String>(
            value: _selectedRole,
            items: const [
              DropdownMenuItem(value: 'all', child: Text("All")),
              DropdownMenuItem(value: 'admin', child: Text("Admin")),
              DropdownMenuItem(value: 'member', child: Text("Member")),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedRole = value;
                });
              }
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: groupsToShow.length,
            itemBuilder: (context, index) {
              final group = groupsToShow[index];
              return _buildGroupCard(context, group, provider);
            },
          ),
        ),
      ],
    );
  }
}

Widget _buildGroupCard(
    BuildContext context, Group group, GroupsProvider provider) {
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.deepPurple.shade50,
            child: const Icon(Icons.folder, color: Colors.deepPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(group.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                FutureBuilder<List<int>>(
                  future: _getTaskCounts(group.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Text("Đang tải...",
                          style: TextStyle(fontSize: 12, color: Colors.grey));
                    } else {
                      final total = snapshot.data![0];
                      return Text(
                        "$total Tasks",
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FutureBuilder<List<int>>(
            future: _getTaskCounts(group.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done ||
                  snapshot.hasError) {
                return CircularPercentIndicator(
                  radius: 28.0,
                  lineWidth: 5.0,
                  percent: 0.0,
                  center: const Text("0%"),
                  progressColor: Colors.grey,
                );
              } else {
                final total = snapshot.data![0];
                final todo = snapshot.data![1];
                final percent = total == 0 ? 0 : (todo / total).clamp(0.0, 1.0);
                final percentText = "${(percent * 100).round()}%";

                return CircularPercentIndicator(
                  radius: 28.0,
                  lineWidth: 5.0,
                  percent: percent.toDouble(),
                  center: Text(percentText,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  progressColor: Colors.deepPurple,
                  backgroundColor: Colors.deepPurple.shade100,
                  animation: true,
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}

/// Helper để fetch cả 2 count: tổng số task và số task có status 'done'
Future<List<int>> _getTaskCounts(String groupId) async {
  final total = await TaskService.countTasks(groupId);
  final todo = await TaskService.countTasks(groupId, status: 'done');
  return [total, todo];
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

      // Lọc lời mời có trạng thái là 'pending' (chưa xử lý)
      final pendingInvites =
          inviteRes.where((inv) => inv['status'] == 'pending').toList();

      setState(() {
        _invites = pendingInvites;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching requests/invites: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptInvite(String id) async {
    try {
      await InviteService.acceptInvite(id);

      // Cập nhật danh sách lời mời
      setState(() {
        _invites.removeWhere((inv) => inv['id'] == id);
      });

      // Gọi lại fetchGroups để cập nhật danh sách nhóm
      await Provider.of<GroupsProvider>(context, listen: false).fetchGroups();

      _showSnackBar("Bạn đã tham gia nhóm thành công");
    } catch (e) {
      debugPrint('Error accepting invite: $e');
      _showSnackBar("Đã xảy ra lỗi khi tham gia nhóm");
    }
  }

  Future<void> _rejectInvite(String id) async {
    try {
      await InviteService.rejectInvite(id);
      setState(() {
        _invites.removeWhere((inv) => inv['id'] == id);
      });
      _showSnackBar("Bạn đã từ chối lời mời tham gia nhóm");
    } catch (e) {
      debugPrint('Error rejecting invite: $e');
      _showSnackBar("Đã xảy ra lỗi khi từ chối lời mời");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                const Text("Invites",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_invites.isEmpty) const Text("Không có lời mời nào."),
                ..._invites.map((inv) {
                  final group = inv['expand']?['group'];
                  final groupName =
                      group is Map ? group['name'] : 'Unknown Group';
                  return Card(
                    child: ListTile(
                      title: Text(groupName),
                      subtitle: const Text("Bạn đã được mời tham gia"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _acceptInvite(inv['id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _rejectInvite(inv['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
  }
}
