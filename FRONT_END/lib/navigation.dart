import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation_manager.dart';
import 'screens/Groups/groups.dart';
import 'screens/home.dart';
import 'screens/Tasks/task.dart';

class BottomNavScreen extends StatelessWidget {
  static const routeName = '/bottom_nav';

  const BottomNavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationManager = context.watch<NavigationManager>();
    final selectedIndex = navigationManager.selectedIndex;

    final List<Widget> screens = const [
      HomeScreen(),
      GroupScreen(),
      TaskScreen(),
    ];

    final List<String> titles = [
      'Home',
      'Groups',
      'Tasks',
      'Account',
    ];

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(
                        'assets/images/profile.png'), // thay bằng ảnh đại diện phù hợp
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hello, Mr. Jack',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text('@jacksparrow009',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
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
              onTap: () {
                // Xử lý đăng xuất nếu cần
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        backgroundColor: Colors.deepPurple,
      ),
      body: screens[selectedIndex],
    );
  }

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
        Navigator.pop(context); // đóng drawer
      },
    );
  }
}
