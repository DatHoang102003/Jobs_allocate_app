import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../Tasks/tasks_manager.dart';
import '../schedule.dart';

class TodayTaskCard extends StatefulWidget {
  final TasksProvider taskProvider;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const TodayTaskCard({
    Key? key,
    required this.taskProvider,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  _TodayTaskCardState createState() => _TodayTaskCardState();
}

class _TodayTaskCardState extends State<TodayTaskCard> {
  late ValueNotifier<DateTime> _firstDayOfWeek;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _firstDayOfWeek = ValueNotifier(_calculateFirstDayOfWeek());
  }

  DateTime _calculateFirstDayOfWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  }

  List<DateTime> get weekDates =>
      List.generate(7, (i) => _firstDayOfWeek.value.add(Duration(days: i)));

  void _showCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SchedulePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.taskProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Sử dụng todayTasks thay vì tasks
    final total = widget.taskProvider.todayTasks.length;
    final done = widget.taskProvider.todayTasks
        .where((t) => t['status'] == 'completed')
        .length;
    final percent = total == 0 ? 0 : ((done / total) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: month year and calendar icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  DateFormat('MMM, yyyy').format(widget.selectedDate),
                  key: ValueKey(widget.selectedDate),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showCalendar(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purpleAccent, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Week navigation
        SizedBox(
          height: 70,
          child: ValueListenableBuilder<DateTime>(
            valueListenable: _firstDayOfWeek,
            builder: (context, firstDay, _) => Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      size: 28, color: Colors.deepPurple),
                  onPressed: () => _firstDayOfWeek.value =
                      _firstDayOfWeek.value.subtract(const Duration(days: 7)),
                ),
                Expanded(
                  child: Row(
                    children: weekDates.map((date) {
                      final sel = isSameDay(date, widget.selectedDate);
                      final dayName =
                          DateFormat('EEE').format(date).substring(0, 2);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (_isSelecting) return;
                            _isSelecting = true;
                            widget.onDateSelected(date);
                            await Future.delayed(
                                const Duration(milliseconds: 200));
                            _isSelecting = false;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              gradient: sel
                                  ? const LinearGradient(
                                      colors: [
                                        Colors.purpleAccent,
                                        Colors.deepPurple
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    )
                                  : null,
                              color: sel ? null : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color:
                                            Colors.deepPurple.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: sel ? Colors.white : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: sel ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      size: 28, color: Colors.deepPurple),
                  onPressed: () => _firstDayOfWeek.value =
                      _firstDayOfWeek.value.add(const Duration(days: 7)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Progress card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Container(
              key: ValueKey(widget.selectedDate),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purpleAccent, Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${DateFormat('MMM dd').format(widget.selectedDate)}: $done/$total tasks done",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                const Color.fromARGB(255, 86, 20, 200),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/today_tasks',
                            arguments: widget.selectedDate,
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
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: percent / 100),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) =>
                              CircularProgressIndicator(
                            value: value,
                            color: Colors.white,
                            backgroundColor: Colors.white24,
                            strokeWidth: 6,
                          ),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: percent.toDouble()),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Text(
                          '${value.round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstDayOfWeek.dispose();
    super.dispose();
  }
}
