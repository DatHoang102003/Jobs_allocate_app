import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE8E6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA3DAD6),
        title: const Text(
          'Trang chủ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xin chào!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Dưới đây là danh sách các nhiệm vụ hôm nay:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Danh sách nhiệm vụ mẫu
            Expanded(
              child: ListView(
                children: const [
                  TaskItem(
                    title: 'Học Flutter',
                    subtitle: 'Hoàn thành màn hình đăng nhập',
                  ),
                  TaskItem(
                    title: 'Họp nhóm',
                    subtitle: 'Thảo luận chức năng chia sẻ công việc',
                  ),
                  TaskItem(
                    title: 'Thiết kế UI',
                    subtitle: 'Tạo wireframe cho màn quản lý nhóm',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const TaskItem({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Điều hướng đến chi tiết công việc
        },
      ),
    );
  }
}
