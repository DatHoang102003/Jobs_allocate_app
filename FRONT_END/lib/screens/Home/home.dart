import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../Auth/account.dart';
import '../Auth/login.dart';
import '../Groups/create_dialog.dart';
import '../Groups/group_search.dart';
import '../Groups/groups_manager.dart';
import '../Members/membership_manager.dart';
import '../Tasks/tasks_manager.dart';
import 'widgets/group_card.dart';
import 'widgets/in_progress_section.dart';
import 'widgets/today_task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final gp = context.read<GroupsProvider>();
    final tp = context.read<TasksProvider>();
    await gp.fetchGroups();
    await tp.loadTasksForToday(date: selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GroupsProvider>();
    final tp = context.watch<TasksProvider>();
    final mp = context.watch<MemberManager>();

    // chỉ dùng loading của groups + members cho spinner toàn màn hình
    final isBusy = gp.isLoading || mp.isLoading;

    // tạo list nhóm duy nhất
    final groups = {
      for (var g in gp.adminGroups) g.id: g,
      for (var g in gp.memberGroups) g.id: g,
    }.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEDE8E6),
      drawer: const CustomDrawer(),
      appBar: const _HomeAppBar(),
      body: isBusy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GroupSearch(),
                  const SizedBox(height: 24),

                  // chỉ TodayTaskCard được rebuild khi TasksProvider thay đổi
                  TodayTaskCard(
                    taskProvider: tp,
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      setState(() => selectedDate = date);
                      tp.loadTasksForToday(date: date);
                    },
                  ),

                  const SizedBox(height: 24),
                  const InProgressSection(),
                  const SizedBox(height: 24),

                  const Text(
                    "Task Groups",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...groups.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GroupCard(
                          key: ValueKey(g.id),
                          groupProvider: gp,
                          taskProvider: tp,
                          memberProvider: mp,
                          group: g,
                        ),
                      )),
                ],
              ),
            ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const CreateGroupDialog(),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add group", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7A86F8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 6,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        "Dashboard",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> _drawerProfile() =>
      UserService.getDrawerProfile();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.deepPurple.shade100.withOpacity(0.9),
      child: Column(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _drawerProfile(),
            builder: (c, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snap.data;
              final avatar = data?['avatarUrl'] as String?;
              final name = data?['name'] as String? ?? 'Mr. Jack';
              final user = data?['username'] as String? ?? 'jacksparrow009';
              return Column(
                children: [
                  const SizedBox(height: 50),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountScreen(),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: avatar != null
                          ? NetworkImage(avatar)
                          : const AssetImage('assets/images/blueavatar.jpg')
                              as ImageProvider,
                      child: avatar == null
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  Text('@$user', style: const TextStyle(color: Colors.black54)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Edit Profile'),
                  ),
                  const Divider(),
                ],
              );
            },
          ),
          _DrawerItem(icon: Icons.home, title: 'Home', route: '/home'),
          _DrawerItem(icon: Icons.group, title: 'Groups', route: '/groups'),
          _DrawerItem(icon: Icons.task, title: 'Tasks', route: '/task'),
          _DrawerItem(icon: Icons.info, title: 'Information', route: null),
          _DrawerItem(icon: Icons.settings, title: 'Settings', route: null),
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
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? route;
  const _DrawerItem(
      {required this.icon, required this.title, this.route, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: route == null
          ? null
          : () {
              Navigator.pop(context);
              Navigator.pushNamed(context, route!);
            },
    );
  }
}
