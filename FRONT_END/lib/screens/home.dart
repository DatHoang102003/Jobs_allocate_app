import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/models/groups.dart';
import 'package:task_manager_app/screens/Groups/groups_manager.dart';
import 'package:task_manager_app/screens/Tasks/tasks_manager.dart';
import 'Auth/account.dart';
import 'Auth/login.dart';
import 'Groups/create_dialog.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // kick off both loads once
    final gp = context.read<GroupsProvider>();
    final tp = context.read<TasksProvider>();
    if (gp.groups.isEmpty) gp.fetchGroups();
    if (tp.tasks.isEmpty) tp.fetchRecent();
  }

  @override
  Widget build(BuildContext context) {
    final groupsProv = context.watch<GroupsProvider>();
    final tasksProv = context.watch<TasksProvider>();

    final loading = groupsProv.isLoading || tasksProv.isLoading;

    /* ------------ UI ------------ */
    return Scaffold(
      backgroundColor: const Color(0xFFEDE8E6),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Home',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchBox(),
                    const SizedBox(height: 20),
                    const Text('Your project',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    groupsProv.groups.isEmpty
                        ? const Text('Bạn chưa có nhóm nào')
                        : ProjectCard(group: groupsProv.groups.first),
                    const SizedBox(height: 20),
                    const Text('Your recent tasks',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: tasksProv.tasks.isEmpty
                          ? const Center(child: Text('Không có task gần đây'))
                          : ListView.builder(
                              itemCount: tasksProv.tasks.length,
                              itemBuilder: (ctx, i) {
                                final t = tasksProv.tasks[i];
                                return TaskCard(
                                  title: t['title'],
                                  deadline:
                                      DateTime.tryParse(t['deadline'] ?? ''),
                                );
                              },
                            ),
                    ),
                  ],
                ),
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

  /* --- small extract for clarity --- */
  Widget _searchBox() => TextField(
        decoration: InputDecoration(
          hintText: "Search",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.tune),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          fillColor: Colors.white,
          filled: true,
        ),
      );
}

class ProjectCard extends StatelessWidget {
  final Group group;

  const ProjectCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Created: ${group.created.toLocal().toString().split(' ')[0]}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                const Icon(Icons.update, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Updated: ${group.updated.toLocal().toString().split(' ')[0]}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              group.description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final DateTime? deadline;

  const TaskCard({
    super.key,
    required this.title,
    this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.task_outlined, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            Text("Deadline: ${deadline?.toLocal().toString().split(' ')[0]} "),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {},
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
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                  Text('$username',
                      style: const TextStyle(color: Colors.black54)),
                  TextButton(
                      onPressed: () {}, child: const Text('Edit Profile')),
                  const Divider(),
                ],
              );
            },
          ),

          /* ------------- items below untouched ------------- */
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
            onTap: () => {
              Navigator.pop(context),
              Navigator.pushNamed(context, '/groups')
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

  /* ---- helper returns {name, username, avatarUrl} or null on error ---- */
  Future<Map<String, dynamic>?> _drawerProfile() async {
    final data = await UserService.getDrawerProfile();
    return data;
  }
}
