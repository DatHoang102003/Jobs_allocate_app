import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation_manager.dart';
import 'screens/Auth/account.dart';
import 'screens/Groups/groups.dart';
import 'screens/home.dart';
import 'screens/Tasks/task.dart';

class BottomNavScreen extends StatelessWidget {
  static const routeName = '/bottom_nav';
  const BottomNavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationManager = context.watch<NavigationManager>();
    final pageController = PageController(
      initialPage: navigationManager.selectedIndex,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          navigationManager.setSelectedIndex(index);
        },
        children: const [
          HomeScreen(),
          GroupScreen(),
          TaskScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
          currentIndex: navigationManager.selectedIndex,
          onTap: (index) {
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            navigationManager.setSelectedIndex(index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Group',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.task),
              label: 'Task',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
