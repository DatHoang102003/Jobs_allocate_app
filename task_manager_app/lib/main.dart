import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/screens/Auth/login.dart';
import 'package:task_manager_app/screens/Auth/register.dart';
import 'bottom_nav.dart';
import 'navigation_manager.dart';

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
        home: const LoginScreen(),
        routes: {
          RegisterScreen.routeName: (context) => const RegisterScreen(),
          BottomNavScreen.routeName: (context) => const BottomNavScreen(),
        },
      ),
    );
  }
}
