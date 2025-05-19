import 'package:flutter/material.dart';
import 'package:task_manager_app/screens/Groups/create_dialog.dart';

import '../models/groups.dart';
import 'Auth/account_manager.dart';
import 'Groups/groups_manager.dart';
import 'Tasks/tasks_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentGroup = mockGroups.first;
    final currentTasks = mockTasks;
    final assignedUser = (String id) => mockUsers
        .firstWhere((u) => u.username == id, orElse: () => mockUsers[0]);

    return Scaffold(
      backgroundColor: const Color(0xFFEDE8E6),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: "Search",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.tune),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your project',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ProjectCard(group: currentGroup),
              const SizedBox(height: 20),
              const Text(
                'Your recent tasks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              // Bọc bằng Expanded để tránh tràn và bị che
              Expanded(
                child: ListView.builder(
                  itemCount: currentTasks.length,
                  itemBuilder: (context, index) {
                    final task = currentTasks[index];
                    final user = assignedUser(task.assignUserId);
                    return TaskCard(
                      title: task.title,
                      deadline: task.deadline,
                      assignee: user.fullName,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateGroupDialog(),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add group", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7A86F8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 6,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Group group;

  const ProjectCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Created: ${group.created.toLocal().toString().split(' ')[0]}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                const Icon(Icons.update, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Updated: ${group.updated.toLocal().toString().split(' ')[0]}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              group.description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final DateTime? deadline;
  final String assignee;

  const TaskCard({
    super.key,
    required this.title,
    this.deadline,
    required this.assignee,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.task_outlined, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            "Deadline: ${deadline?.toLocal().toString().split(' ')[0]} • Assigned to: $assignee"),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {},
      ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.deepPurple.shade100.withOpacity(0.9),
      child: Column(
        children: [
          const SizedBox(height: 50),
          const CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/avatar.png'), // Thay avatar
          ),
          const SizedBox(height: 10),
          const Text('@jacksparrow009',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(onPressed: () {}, child: const Text('Edit Profile')),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Groups'),
            onTap: () => {Navigator.pushNamed(context, '/groups')},
          ),
          ListTile(
            leading: const Icon(Icons.task),
            title: const Text('Tasks'),
            onTap: () => {Navigator.pushNamed(context, '/task')},
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Information'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {},
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
