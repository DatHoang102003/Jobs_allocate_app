import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'Auth/account.dart';
import 'Auth/login.dart';
import 'Groups/create_dialog.dart';
import 'Groups/group_search.dart';
import 'Groups/groups_manager.dart';
import 'Members/membership_manager.dart';
import 'Tasks/task.dart';
import 'Tasks/tasks_manager.dart';

enum UserGroupStatus { admin, member, notJoined }

Future<UserGroupStatus> checkUserGroupStatus({
  required String groupId,
  required String userId,
  required GroupsProvider groupsProvider,
  required MemberManager memberManager,
}) async {
  // Kiểm tra xem nhóm có trong adminGroups không
  if (groupsProvider.adminGroups.any((group) => group.id == groupId)) {
    return UserGroupStatus.admin;
  }

  // Kiểm tra xem nhóm có trong memberGroups không
  if (groupsProvider.memberGroups.any((group) => group.id == groupId)) {
    return UserGroupStatus.member;
  }

  // Nếu không có trong adminGroups hoặc memberGroups, kiểm tra thêm qua MemberManager
  await memberManager.fetchMembers(groupId, myUserId: userId);
  if (memberManager.isUserMember(userId)) {
    return UserGroupStatus.member;
  }

  // Nếu không phải admin hoặc member, người dùng chưa tham gia
  return UserGroupStatus.notJoined;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TasksProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupsProvider>(context, listen: false);
      taskProvider.loadTasksForToday(date: DateTime.now());
      groupProvider.fetchGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupsProvider>(context);
    final taskProvider = Provider.of<TasksProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEDE8E6),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: taskProvider.isLoading || groupProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GroupSearch(),
                  _buildTodayTaskCard(taskProvider),
                  const SizedBox(height: 24),
                  _buildInProgressSection(taskProvider),
                  const SizedBox(height: 24),
                  _buildGroupProgressSection(groupProvider, taskProvider),
                ],
              ),
            ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const CreateGroupDialog(),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add group", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7A86F8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 6,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTodayTaskCard(TasksProvider provider) {
    final tasks = provider.tasks;
    final total = tasks.length;
    final done = tasks.where((t) => t['status'] == 'done').length;
    final percent = total == 0 ? 0 : ((done / total) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your today's task\nalmost done!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Chuyển tới trang danh sách task hôm nay
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TaskScreen()),
                    );
                  },
                  child: const Text("View Task"),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: percent / 100,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                  strokeWidth: 6,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressSection(TasksProvider provider) {
    final inProgress =
        provider.tasks.where((t) => t['status'] == 'todo').take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "In Progress",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: inProgress.map((task) => _buildTaskCard(task)).toList(),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final title = task['title'] ?? 'Untitled';
    final groupName = task['groupName'] ?? 'Unknown';
    final progress = task['progress'] ?? 0.5;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupName,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupProgressSection(
      GroupsProvider groupProvider, TasksProvider taskProvider) {
    final groups = [
      ...groupProvider.adminGroups,
      ...groupProvider.memberGroups
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Task Groups",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...groups.map((group) {
          final groupTasks = taskProvider.tasks
              .where((t) => t['groupId'] == group.id)
              .toList();
          final done = groupTasks.where((t) => t['status'] == 'done').length;
          final percent = groupTasks.isEmpty
              ? 0
              : ((done / groupTasks.length) * 100).round();

          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 6), // 👈 Thêm khoảng cách
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              tileColor: Colors.grey.shade100,
              leading: const Icon(Icons.folder, color: Colors.pink),
              title: Text(group.name),
              subtitle: Text('${groupTasks.length} Tasks'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.pink.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.deepPurple.shade100.withOpacity(0.9),
      child: Column(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _drawerProfile(), // backend helper
            builder: (context, snap) {
              // while loading
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // if fetch failed -> fallback to old dummy
              final data = snap.data;
              final avatarUrl = data?['avatarUrl'] as String?;
              final name = data?['name'] as String? ?? 'Mr. Jack';
              final username = data?['username'] as String? ?? 'jacksparrow009';

              return Column(
                children: [
                  const SizedBox(height: 50),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountScreen()),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : const AssetImage('assets/images/blueavatar.jpg')
                              as ImageProvider,
                      child: avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '$username',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Edit Profile'),
                  ),
                  const Divider(),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Groups'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/groups');
            },
          ),
          ListTile(
            leading: const Icon(Icons.task),
            title: const Text('Tasks'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/task');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Information'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              await AuthService.logoutUser();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _drawerProfile() async {
    final data = await UserService.getDrawerProfile();
    return data;
  }
}
