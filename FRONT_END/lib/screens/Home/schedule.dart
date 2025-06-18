import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import '../Tasks/tasks_manager.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int _selectedMonth = DateTime.now().month;
  int _selectedDay = DateTime.now().day;
  DateTime _lastCheckedDate = DateTime.now();

  final List<Color> _cardColors = [
    Colors.blue[100]!,
    Colors.green[100]!,
    Colors.purple[100]!,
    Colors.orange[100]!,
    Colors.red[100]!,
    Colors.teal[100]!,
    Colors.pink[100]!,
    Colors.cyan[100]!,
  ];

  @override
  void initState() {
    super.initState();
    _updateDateAndTasks();
  }

  void _updateDateAndTasks() {
    final now = DateTime.now();
    if (now.day != _lastCheckedDate.day ||
        now.month != _lastCheckedDate.month ||
        now.year != _lastCheckedDate.year) {
      setState(() {
        _selectedMonth = now.month;
        _selectedDay = now.day;
        _lastCheckedDate = now;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TasksProvider>().loadTasks(date: now, byDeadline: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateDateAndTasks();
    final taskMgr = context.watch<TasksProvider>();
    final year = DateTime.now().year;
    final daysInMonth = DateUtils.getDaysInMonth(year, _selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat.MMMM().format(DateTime(year, _selectedMonth))} $year',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have ${taskMgr.deadlineTasks.length} tasks to complete',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 12,
                    itemBuilder: (ctx, i) {
                      final m = i + 1;
                      final isSelected = m == _selectedMonth;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMonth = m;
                            _selectedDay = 1;
                          });
                          context.read<TasksProvider>().loadTasks(
                                date: DateTime(
                                    year, _selectedMonth, _selectedDay),
                                byDeadline: true,
                              );
                        },
                        child: Container(
                          width: 70,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            DateFormat.MMM().format(DateTime(year, m)),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Deadline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: ListView.builder(
                    itemCount: daysInMonth,
                    itemBuilder: (ctx, idx) {
                      final day = idx + 1;
                      final isSelected = day == _selectedDay;
                      final date = DateTime(year, _selectedMonth, day);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedDay = day);
                          context.read<TasksProvider>().loadTasks(
                                date: date,
                                byDeadline: true,
                              );
                        },
                        child: Container(
                          height: 70,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat.E().format(date).substring(0, 3),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                day.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: taskMgr.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : taskMgr.deadlineTasks.isEmpty
                          ? Center(
                              child: Text(
                                "No tasks for $_selectedDay/${_selectedMonth.toString().padLeft(2, '0')}/$year",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: taskMgr.deadlineTasks.length,
                              itemBuilder: (ctx, i) {
                                final t = taskMgr.deadlineTasks[i];
                                final taskId = t['id'] as String? ?? '';
                                final title = t['title'] ?? 'Untitled';
                                final description =
                                    t['description'] as String? ??
                                        'No description';
                                final assignees = t['assignee'] != null
                                    ? List<String>.from(t['assignee'])
                                    : <String>[];

                                final assigneeInfos =
                                    taskMgr.getCachedAssigneeInfo(taskId) ??
                                        assignees
                                            .map((id) => {
                                                  'id': id,
                                                  'avatarUrl': '',
                                                  'name': 'Unknown'
                                                })
                                            .toList();

                                List<Widget> avatars = assigneeInfos
                                    .asMap()
                                    .entries
                                    .take(3)
                                    .map((entry) {
                                  final idx = entry.key;
                                  final info = entry.value;
                                  return Positioned(
                                    left: idx * 24.0,
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          info['avatarUrl'] != null &&
                                                  info['avatarUrl']!.isNotEmpty
                                              ? NetworkImage(info['avatarUrl']!)
                                              : null,
                                      child: info['avatarUrl'] == null ||
                                              info['avatarUrl']!.isEmpty
                                          ? Text(
                                              (info['name'] as String)
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.white),
                                            )
                                          : null,
                                    ),
                                  );
                                }).toList();
                                if (assigneeInfos.length > 3) {
                                  avatars.add(
                                    Positioned(
                                      left: 3 * 24.0,
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.grey[300],
                                        child: Text(
                                          '+${assigneeInfos.length - 3}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final bg = _cardColors[
                                    Random().nextInt(_cardColors.length)];

                                return Container(
                                  height: 80,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(30)),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                          width: 60,
                                          child: Stack(
                                              clipBehavior: Clip.none,
                                              children: avatars)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Colors.black87),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              description,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[800]),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
