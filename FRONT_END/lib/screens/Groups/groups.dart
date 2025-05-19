import 'package:flutter/material.dart';

class GroupScreen extends StatelessWidget {
  static const routeName = '/groups';

  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm'),
        centerTitle: true,
        backgroundColor: const Color(0xFFA3DAD6),
      ),
      body: const Center(
        child: Text(
          'Trang Nhóm',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
