import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Tasks/tasks_manager.dart';

class TodayTaskCard extends StatelessWidget {
  final TasksProvider taskProvider;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const TodayTaskCard({
    Key? key,
    required this.taskProvider,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  List<DateTime> get weekDates {
    final base = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    return List.generate(7, (i) => base.add(Duration(days: i - 3)));
  }

  @override
  Widget build(BuildContext context) {
    final total = taskProvider.tasks.length;
    final done =
        taskProvider.tasks.where((t) => t['status'] == 'completed').length;
    final percent = total == 0 ? 0 : ((done / total) * 100).round();

    return Column(
      children: [
        SizedBox(
          height: 80,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: weekDates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final date = weekDates[i];
              final sel = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Container(
                  width: 48,
                  decoration: BoxDecoration(
                    color: sel ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: sel ? Colors.black : Colors.grey.shade400,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          color: sel ? Colors.black : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          color: sel ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${DateFormat('MMM dd').format(selectedDate)}: $done/$total tasks done",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/tasks',
                          arguments: selectedDate,
                        ),
                        child: const Text("View Tasks"),
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: percent / 100,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                        strokeWidth: 6,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
