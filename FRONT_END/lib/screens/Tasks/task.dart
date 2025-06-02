import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tasks_manager.dart'; // Ensure correct path to TasksProvider

class TaskScreen extends StatefulWidget {
  static const routeName = '/tasks';
  const TaskScreen({super.key});

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
      taskProvider.loadTasksForToday(date: DateTime.now());
    });
  }

  List<Map<String, dynamic>> _filterTasks(
      List<Map<String, dynamic>> tasks, String filter) {
    if (filter == 'All') return tasks;
    return tasks.where((task) {
      if (filter == 'In Progress') return task['status'] == 'doing';
      if (filter == 'Completed') return task['status'] == 'done';
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TasksProvider>(context);
    final filteredTasks = _filterTasks(taskProvider.tasks, _selectedFilter);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Today\'s Tasks',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
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
          Expanded(
            child: taskProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? Center(
                        child: Text(
                          _selectedFilter == 'All'
                              ? 'No tasks for today'
                              : 'No $_selectedFilter tasks',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          final statusColor = task['status'] == 'done'
                              ? Colors.green
                              : task['status'] == 'doing'
                                  ? Colors.orange
                                  : Colors.grey;

                          String createdDate = 'N/A';
                          try {
                            if (task['created'] != null) {
                              final parsedDate =
                                  DateTime.parse(task['created']);
                              createdDate =
                                  parsedDate.toLocal().toString().split(' ')[0];
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
                                createdDate,
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
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: Colors.deepPurple.withOpacity(0.2),
      backgroundColor: Colors.grey.shade200,
    );
  }
}
