import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../Auth/auth_manager.dart';
import '../Groups/groups_manager.dart';
import 'tasks_manager.dart';

class TaskScreen extends StatefulWidget {
  static const routeName = '/tasks';
  const TaskScreen({Key? key}) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String _selectedFilter = 'all';
  String? _previousUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TasksProvider>(context, listen: false);
      final groupsProvider =
          Provider.of<GroupsProvider>(context, listen: false);
      // Fetch tasks based on initial filter
      taskProvider.fetchAssignedTasks(
        status: _selectedFilter,
      );
      groupsProvider.fetchGroups();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = context.watch<AuthManager>().userId;
    // Reload tasks if userId changes
    if (_previousUserId != currentUserId) {
      Provider.of<TasksProvider>(context, listen: false).fetchAssignedTasks(
        status: _selectedFilter,
      );
      _previousUserId = currentUserId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TasksProvider>(context);
    final groupsProvider = Provider.of<GroupsProvider>(context);

    // Combine admin and member groups
    final allGroups = [
      ...groupsProvider.adminGroups,
      ...groupsProvider.memberGroups,
    ];

    // Use the assignedTasks directly (already filtered by status in fetchAssignedTasks)
    final filteredTasks = taskProvider.assignedTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Tasks',
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
          // ChoiceChips for filtering
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChoiceChip('all', 'All'),
                _buildChoiceChip('in_progress', 'In Progress'),
                _buildChoiceChip('completed', 'Completed'),
              ],
            ),
          ),
          // Task list
          Expanded(
            child: taskProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? Center(
                        child: Text(
                          'No ${_selectedFilter.replaceAll('_', ' ').toLowerCase().replaceFirstMapped(
                                RegExp(r'^\w'),
                                (Match match) => match.group(0)!.toUpperCase(),
                              )} tasks',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];

                          // Lookup groupName
                          final groupId = task['group'] as String? ?? '';
                          final matched =
                              allGroups.where((g) => g.id == groupId).toList();
                          final groupName = matched.isNotEmpty
                              ? matched.first.name
                              : 'Unknown';

                          // Status color
                          final statusColor = task['status'] == 'completed'
                              ? Colors.green
                              : task['status'] == 'in_progress'
                                  ? Colors.orange
                                  : Colors.grey;

                          // Deadline
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
                                  // Display group name
                                  Text(
                                    'Group: $groupName',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${task['status'] != null ? task['status'].replaceAll('_', ' ').toLowerCase().replaceFirstMapped(
                                          RegExp(r'^\w'),
                                          (Match match) =>
                                              match.group(0)!.toUpperCase(),
                                        ) : 'unknown'}',
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

  Widget _buildChoiceChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (sel) {
        if (sel) {
          setState(() {
            _selectedFilter = value;
            // Fetch tasks with the selected status filter
            Provider.of<TasksProvider>(context, listen: false)
                .fetchAssignedTasks(
              status: value,
            );
          });
        }
      },
      selectedColor: Colors.deepPurple.withOpacity(0.2),
      backgroundColor: Colors.grey.shade200,
    );
  }
}
