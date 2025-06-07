import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Home/Widgets/group_card.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../Auth/account.dart';
import '../Auth/login.dart';
import '../Groups/group_search.dart';
import '../Groups/groups_manager.dart';
import '../Members/membership_manager.dart';
import '../Tasks/tasks_manager.dart';
import 'Widgets/in_progress_section.dart';
import 'Widgets/today_task_card.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gp = context.read<GroupsProvider>();
      final tp = context.read<TasksProvider>();
      final mp = context.read<MemberManager>();

      // load nhóm rồi load tasks và members cho mỗi nhóm
      await gp.fetchGroups();
      final allGroups = {
        for (var g in gp.adminGroups) g.id: g,
        for (var g in gp.memberGroups) g.id: g,
      }.values.toList();

      for (var g in allGroups) {
        await tp.loadTasksByGroup(g.id);
        await mp.fetchMembers(g.id);
      }

      // load today's tasks
      tp.loadTasksForToday(date: selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GroupsProvider>();
    final tp = context.watch<TasksProvider>();
    final mp = context.watch<MemberManager>();

    final isBusy = gp.isLoading || tp.isLoading || mp.isLoading;

    // Tạo list nhóm duy nhất để render
    final groups = {
      for (var g in gp.adminGroups) g.id: g,
      for (var g in gp.memberGroups) g.id: g,
    }.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEDE8E6),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: isBusy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GroupSearch(),
                  const SizedBox(height: 24),
                  TodayTaskCard(
                    taskProvider: tp,
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      setState(() => selectedDate = date);
                      context
                          .read<TasksProvider>()
                          .loadTasksForToday(date: date);
                    },
                  ),
                  const SizedBox(height: 24),
                  InProgressSection(),
                  const SizedBox(height: 24),
                  const Text(
                    "Task Groups",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // render từng group
                  ...groups.map((g) => GroupCard(
                        key: ValueKey(g.id),
                        group: g,
                        groupProvider: gp,
                        taskProvider: tp,
                        memberProvider: mp,
                      )),
                ],
              ),
            ),
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
