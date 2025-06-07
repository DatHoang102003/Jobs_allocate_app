import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Groups/groups_manager.dart';
import 'package:task_manager_app/screens/Home/home.dart' show CustomDrawer;
import '../../models/groups.dart';
import '../../services/invite_service.dart';
import '../Home/Widgets/group_card.dart';
import '../Members/membership_manager.dart';
import '../Tasks/tasks_manager.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
              ],
            ),
    );
  }

  Widget _buildOverviewTab(GroupsProvider provider) {
    // Lấy danh sách admin và member
    final admin = provider.adminGroups;
    final member = provider.memberGroups;

    // Tạo list kết quả
    late final List<Group> groupsToShow;
    switch (_selectedRole) {
      case 'admin':
        groupsToShow = admin;
        break;
      case 'member':
        groupsToShow = member;
        break;
      default:
        // Kết hợp mà không trùng: dùng Map theo id
        final Map<String, Group> uniq = {
          for (var g in admin) g.id: g,
          for (var g in member) g.id: g,
        };
        groupsToShow = uniq.values.toList();
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
                setState(() => _selectedRole = value);
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
              return GroupCard(
                group: group,
                groupProvider: context.watch<GroupsProvider>(),
                taskProvider: context.watch<TasksProvider>(),
                memberProvider: context.watch<MemberManager>(),
              );
            },
          ),
        ),
      ],
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
