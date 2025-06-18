import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Auth/account.dart';
import 'package:task_manager_app/screens/Auth/auth_manager.dart';
import 'package:task_manager_app/screens/Comments/comments_manager.dart';
import 'package:task_manager_app/screens/Groups/groups_manager.dart';
import 'package:task_manager_app/screens/Home/analysis.dart';
import 'package:task_manager_app/screens/Home/schedule.dart';
import 'package:task_manager_app/screens/Members/invites_manager.dart';
import 'package:task_manager_app/screens/Members/join_manager.dart';
import 'package:task_manager_app/screens/Members/membership_manager.dart';
import 'package:task_manager_app/screens/Tasks/task.dart';
import 'package:task_manager_app/screens/Tasks/tasks_manager.dart';
import 'package:task_manager_app/screens/Home/home.dart';
import 'package:task_manager_app/services/user_service.dart';
import 'package:task_manager_app/screens/Auth/login.dart';
import 'package:task_manager_app/screens/Auth/register.dart';
import 'package:task_manager_app/screens/Groups/Overview/overview.dart';
import 'package:task_manager_app/screens/Tasks/today_task.dart';

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
        return loggedIn ? const HomeScreen() : const LoginScreen();
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
        ChangeNotifierProvider(create: (_) => GroupsProvider()..fetchGroups()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
        ChangeNotifierProvider(create: (_) => AuthManager()..init()),
        ChangeNotifierProvider(create: (_) => MemberManager()),
        ChangeNotifierProvider(create: (_) => JoinManager()),
        ChangeNotifierProvider(create: (_) => InviteManager()),
        ChangeNotifierProvider(create: (_) => CommentsProvider()),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          RegisterScreen.routeName: (_) => const RegisterScreen(),
          GroupScreen.routeName: (_) => const GroupScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/account': (_) => const AccountScreen(),
          '/schedule': (_) => const SchedulePage(),
          '/tasks': (_) => const TaskScreen(),
          '/analysis': (_) => const AnalysisScreen(),

          // Updated TaskScreen route to pass initialDate argument
          TodayTaskScreen.routeName: (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments;
            final initialDate = args is DateTime ? args : DateTime.now();
            return ChangeNotifierProvider.value(
              value: Provider.of<TasksProvider>(ctx, listen: false)
                ..loadTasks(date: initialDate),
              child: TodayTaskScreen(initialDate: initialDate),
            );
          },
        },
      ),
    );
  }
}
