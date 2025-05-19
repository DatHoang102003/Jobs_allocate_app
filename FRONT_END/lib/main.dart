import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Auth/register.dart';
import 'navigation.dart';
import 'navigation_manager.dart';
import 'screens/Groups/groups.dart';
import 'screens/Tasks/task.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationManager()),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        navigatorKey: NavigationManager.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const RegisterScreen(),
        routes: {
          RegisterScreen.routeName: (context) => const RegisterScreen(),
          BottomNavScreen.routeName: (context) => const BottomNavScreen(),
          TaskScreen.routeName: (context) => const TaskScreen(),
          GroupScreen.routeName: (context) => const GroupScreen(),
        },
      ),
    );
  }
}
