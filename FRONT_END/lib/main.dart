import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Auth/account.dart';
import 'package:task_manager_app/screens/Auth/auth_manager.dart';
import 'package:task_manager_app/screens/Groups/groups_manager.dart';
import 'package:task_manager_app/screens/Members/join_manager.dart';
import 'package:task_manager_app/screens/Members/membership_manager.dart';
import 'package:task_manager_app/screens/Tasks/tasks_manager.dart';
import 'package:task_manager_app/screens/Home/home.dart';
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
        ChangeNotifierProvider(create: (_) => GroupsProvider()..fetchGroups()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
        ChangeNotifierProvider(create: (_) => AuthManager()..init()),
        ChangeNotifierProvider(create: (_) => MemberManager()),
        ChangeNotifierProvider(create: (_) => JoinManager()),
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
          GroupScreen.routeName: (_) => const GroupScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/account': (_) => const AccountScreen(),

          // Updated TaskScreen route to pass initialDate argument
          TaskScreen.routeName: (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments;
            final initialDate = args is DateTime ? args : DateTime.now();
            return ChangeNotifierProvider.value(
              value: Provider.of<TasksProvider>(ctx, listen: false)
                ..loadTasksForToday(date: initialDate),
              child: TaskScreen(initialDate: initialDate),
            );
          },
        },
      ),
    );
  }
}
