import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Auth/account.dart';
import 'package:task_manager_app/screens/Groups/groups_manager.dart';
import 'package:task_manager_app/screens/Tasks/tasks_manager.dart';
import 'package:task_manager_app/screens/home.dart';

import 'package:task_manager_app/services/user_service.dart';
import 'package:task_manager_app/navigation_manager.dart';
import 'package:task_manager_app/navigation.dart'; // BottomNavScreen
import 'package:task_manager_app/screens/Auth/login.dart';
import 'package:task_manager_app/screens/Auth/register.dart';
import 'package:task_manager_app/screens/Groups/groups.dart';
import 'package:task_manager_app/screens/Tasks/task.dart';

void main() {
  runApp(const MyApp());
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserService.isTokenValid(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final loggedIn = snap.data!;
        return loggedIn ? const BottomNavScreen() : const LoginScreen();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationManager()),
        ChangeNotifierProvider(create: (_) => GroupsProvider()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        navigatorKey: NavigationManager.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          RegisterScreen.routeName: (_) => const RegisterScreen(),
          BottomNavScreen.routeName: (_) => const BottomNavScreen(),
          TaskScreen.routeName: (_) => const TaskScreen(),
          GroupScreen.routeName: (_) => const GroupScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/account': (_) => const AccountScreen(),
        },
      ),
    );
  }
}
