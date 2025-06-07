import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../Groups/groups_manager.dart';
import 'tasks_manager.dart'; // đường dẫn đúng tới TasksProvider của bạn

class TaskScreen extends StatefulWidget {
  static const routeName = '/tasks';
  final DateTime initialDate;
  const TaskScreen({Key? key, required this.initialDate}) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TasksProvider>(context, listen: false);
      // nạp tasks cho ngày ban đầu
      taskProvider.loadTasksForToday(date: widget.initialDate);
      // và cũng nạp luôn groups (nếu bạn chưa fetch ở nơi khác)
      Provider.of<GroupsProvider>(context, listen: false).fetchGroups();
    });
  }

  List<Map<String, dynamic>> _filterTasks(
      List<Map<String, dynamic>> tasks, String filter) {
    if (filter == 'All') return tasks;
    return tasks.where((task) {
      if (filter == 'In Progress') return task['status'] == 'in_progress';
      if (filter == 'Completed') return task['status'] == 'completed';
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TasksProvider>(context);
    final groupsProvider = Provider.of<GroupsProvider>(context);

    // gom cả admin + member groups
    final allGroups = [
      ...groupsProvider.adminGroups,
      ...groupsProvider.memberGroups,
    ];

    // lọc tasks theo filter
    final filteredTasks = _filterTasks(taskProvider.tasks, _selectedFilter);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tasks for Today',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // các ChoiceChip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChoiceChip('All'),
                _buildChoiceChip('In Progress'),
                _buildChoiceChip('Completed'),
              ],
            ),
          ),
          // danh sách task
          Expanded(
            child: taskProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? Center(
                        child: Text(
                          _selectedFilter == 'All'
                              ? 'No tasks for ${DateFormat('MMM dd').format(widget.initialDate)}'
                              : 'No $_selectedFilter tasks',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];

                          // lookup groupName
                          final groupId = task['group'] as String? ?? '';
                          final matched =
                              allGroups.where((g) => g.id == groupId).toList();
                          final groupName = matched.isNotEmpty
                              ? matched.first.name
                              : 'Unknown';

                          // màu status
                          final statusColor = task['status'] == 'completed'
                              ? Colors.green
                              : task['status'] == 'in_progress'
                                  ? Colors.orange
                                  : Colors.grey;

                          // deadline
                          String deadline = 'N/A';
                          try {
                            if (task['deadline'] != null) {
                              final parsedDate =
                                  DateTime.parse(task['deadline']);
                              deadline = DateFormat.yMMMd().format(parsedDate);
                            }
                          } catch (_) {}

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              title: Text(
                                task['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // hiển thị tên nhóm
                                  Text(
                                    'Group: $groupName',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${task['status'] ?? 'unknown'}',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (task['description'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        task['description'],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                deadline,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == label,
      onSelected: (sel) {
        if (sel) setState(() => _selectedFilter = label);
      },
      selectedColor: Colors.deepPurple.withOpacity(0.2),
      backgroundColor: Colors.grey.shade200,
    );
  }
}
