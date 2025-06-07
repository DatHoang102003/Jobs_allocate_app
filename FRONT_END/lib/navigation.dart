import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation_manager.dart';
import 'screens/Groups/groups.dart';
import 'screens/Home/home.dart';
import 'screens/Tasks/task.dart';
import 'package:task_manager_app/services/user_service.dart';
import 'package:task_manager_app/services/auth_service.dart';

class BottomNavScreen extends StatelessWidget {
  static const routeName = '/bottom_nav';
  const BottomNavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationManager = context.watch<NavigationManager>();
    final selectedIndex = navigationManager.selectedIndex;

    final screens = [
      const HomeScreen(),
      const GroupScreen(),
      TaskScreen(initialDate: DateTime.now()),
    ];

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            // ⬇️  REPLACE the old const DrawerHeader … with this line:
            _buildDrawerHeader(), // <-- loads name & avatar from backend

            // leave the rest unchanged
            _buildDrawerItem(context, Icons.home, 'Home', 0, navigationManager),
            _buildDrawerItem(
                context, Icons.group, 'Groups', 1, navigationManager),
            _buildDrawerItem(
                context, Icons.task, 'Tasks', 2, navigationManager),
            _buildDrawerItem(
                context, Icons.person, 'Account', 3, navigationManager),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () async {
                await AuthService.logoutUser();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (_) => false);
                }
              },
            ),
          ],
        ),
      ),
      body: screens[selectedIndex],
    );
  }

  /* ---------- Drawer header with live profile ---------- */
  Widget _buildDrawerHeader() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService.getDrawerProfile(), // service call
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child:
                Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final data = snap.data;
        if (data == null) {
          return const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Center(
              child: Text('Failed to load user',
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final avatarUrl = data['avatarUrl'] as String?;
        final name = data['name'] as String? ?? '';
        final username = data['username'] as String? ?? '';

        return DrawerHeader(
          decoration: const BoxDecoration(color: Colors.deepPurple),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white70)
                    : null,
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
              Text('Hello, $name',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              Text('@$username', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
    );
  }

  /* ---------- Drawer item ---------- */
  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    int index,
    NavigationManager navigationManager,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: navigationManager.selectedIndex == index,
      selectedTileColor: Colors.deepPurple.withOpacity(0.1),
      onTap: () {
        navigationManager.setSelectedIndex(index);
        Navigator.pop(context); // close drawer
      },
    );
  }
}
