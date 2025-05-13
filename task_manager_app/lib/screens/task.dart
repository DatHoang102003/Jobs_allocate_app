import 'package:flutter/material.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhiệm vụ'),
        centerTitle: true,
        backgroundColor: const Color(0xFFA3DAD6),
      ),
      body: const Center(
        child: Text(
          'Trang Nhiệm vụ',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
