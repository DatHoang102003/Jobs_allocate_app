import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'screens/Auth/account.dart';
import 'screens/Auth/login.dart';

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
                  Text('$user', style: const TextStyle(color: Colors.black54)),
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
