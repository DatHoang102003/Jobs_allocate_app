import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/models/groups.dart';
import 'package:task_manager_app/screens/Groups/groups_manager.dart';
import 'package:task_manager_app/screens/Tasks/tasks_manager.dart';
import '../../models/tasks.dart'; // keep your model

class TaskScreen extends StatefulWidget {
  static const routeName = '/task';
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // fetch once (if not yet loaded)
    final tp = context.read<TasksProvider>();
    if (tp.tasks.isEmpty) tp.fetchRecent();

    final gp = context.read<GroupsProvider>();
    if (gp.groups.isEmpty) gp.fetchGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /* ---------------- filter helpers ---------------- */
  List<Map<String, dynamic>> _filter(
      List<Map<String, dynamic>> all, String status) {
    if (status == 'all') return all;
    return all.where((t) => t['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasksProv = context.watch<TasksProvider>();
    final groupsProv = context.watch<GroupsProvider>();

    final loading = tasksProv.isLoading || groupsProv.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tasks', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.deepPurple),
            insets: EdgeInsets.symmetric(horizontal: 16.0),
          ),
          tabs: const [
            Tab(text: 'All tasks'),
            Tab(text: 'In progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(_filter(tasksProv.tasks, 'all'), groupsProv),
                _buildTaskList(
                    _filter(tasksProv.tasks, 'in_progress'), groupsProv),
                _buildTaskList(
                    _filter(tasksProv.tasks, 'completed'), groupsProv),
              ],
            ),
    );
  }

  /* ---------- list builder ---------- */
  Widget _buildTaskList(
      List<Map<String, dynamic>> tasks, GroupsProvider groupsProv) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final t = tasks[index];

        // safely look up the group (never returns null)
        final groupModel = groupsProv.groups.firstWhere(
          (gr) => gr.id == t['group'],
          orElse: () => Group(
            id: '',
            name: 'Unknown',
            description: '',
            owner: '',
            created: DateTime.now(),
            updated: DateTime.now(),
          ),
        );
        final groupName = groupModel.name;

        return TaskCardUI(
          title: t['title'],
          description: t['description'] ?? '',
          groupName: groupName,
          deadline: DateTime.tryParse(t['deadline'] ?? ''),
          status: t['status'],
        );
      },
    );
  }
}

/* ------------------------------------------------------------------
   The TaskCardUI widget is identical to your original implementation
------------------------------------------------------------------- */
class TaskCardUI extends StatelessWidget {
  final String title;
  final String description;
  final String groupName;
  final DateTime? deadline;
  final String status;

  const TaskCardUI({
    super.key,
    required this.title,
    required this.description,
    required this.groupName,
    this.deadline,
    required this.status,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.blue.shade100;
      case 'completed':
        return Colors.green.shade100;
      case 'pending':
      default:
        return Colors.purple.shade100;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'On going';
      case 'completed':
        return 'Completed';
      case 'pending':
      default:
        return 'New task';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.folder_copy_outlined,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(groupName, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                deadline != null
                    ? "${deadline!.toLocal().toString().split(' ')[0]}"
                    : "No deadline",
                style: const TextStyle(fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(status),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
