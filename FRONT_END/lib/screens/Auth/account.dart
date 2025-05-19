import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        centerTitle: true,
        backgroundColor: const Color(0xFFA3DAD6),
      ),
      body: const Center(
        child: Text(
          'Trang tài khoản',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
