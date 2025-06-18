import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../Tasks/tasks_manager.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TasksProvider>();
    final weekly = provider.weeklyAnalytics;
    final monthly = provider.monthlyAnalytics;

    // Đếm riêng các task In Progress và Completed
    final in_progressTasks =
        provider.tasks.where((t) => t['status'] == 'in_progress').length;
    final completedTasks =
        provider.tasks.where((t) => t['status'] == 'completed').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Productivity'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề 7 ngày
            const Text(
              'Tasks in 7 days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // Bar chart
            SizedBox(height: 200, child: _buildWeeklyChart(weekly)),

            // Thống kê bên dưới
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendDot(
                  color: Colors.orange,
                  label: '$in_progressTasks Progress',
                ),
                const SizedBox(width: 24),
                _LegendDot(
                  color: const Color(0xFF7A86F8),
                  label: '$completedTasks Completed',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Tiêu đề tháng
            const Text(
              'Tasks in this month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // Line chart
            SizedBox(
              height: 200,
              child: _buildMonthlyChart(monthly),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<DayAnalytics> data) {
    final maxY = data
            .map((d) => (d.inProgress + d.completed).toDouble())
            .fold<double>(0.0, (a, b) => b > a ? b : a) +
        5;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barGroups: data.asMap().entries.map((e) {
          final idx = e.key;
          final day = e.value;
          final completed = day.completed.toDouble();
          final inProgress = day.inProgress.toDouble();
          final total = completed + inProgress;

          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: total,
                width: 16,
                rodStackItems: [
                  BarChartRodStackItem(0, completed, const Color(0xFF7A86F8)),
                  BarChartRodStackItem(completed, total, Colors.orange),
                ],
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = data[value.toInt()].date;
                return Text(
                  DateFormat.E().format(date),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildMonthlyChart(List<DayAnalytics> data) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final date = data[spot.x.toInt()].date;
                final count = spot.y.toInt();
                return LineTooltipItem(
                  '$count tasks\n${DateFormat.MMMd().format(date)}',
                  const TextStyle(color: Colors.black87),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          // Completed (tím)
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(
                      e.key.toDouble(),
                      e.value.completed.toDouble(),
                    ))
                .toList(),
            isCurved: true,
            color: const Color(0xFF7A86F8),
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF7A86F8).withOpacity(0.2),
            ),
          ),
          // In Progress (cam)
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) => FlSpot(
                      e.key.toDouble(),
                      e.value.inProgress.toDouble(),
                    ))
                .toList(),
            isCurved: true,
            color: Colors.orange,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.2),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (data.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final day = data[value.toInt()].date.day;
                return Text(
                  '$day',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
