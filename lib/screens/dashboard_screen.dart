import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _dailyFocus = [];
  List<Map<String, dynamic>> _listStats = [];
  Map<int, int> _streaks = {1: 0, 2: 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final completed = await _db.getTotalCompletedTasks();
    final totalSeconds = await _db.getTotalFocusSeconds();
    final totalSessions = await _db.getTotalSessions();
    final todaySeconds = await _db.getTodayFocusSeconds();
    final daily = await _db.getFocusByDay(14);
    final listStats = await _db.getTaskCompletionByList();
    final streaks = await _db.getStreaks();

    setState(() {
      _stats = {
        'completed_tasks': completed,
        'total_seconds': totalSeconds,
        'total_sessions': totalSessions,
        'today_seconds': todaySeconds,
      };
      _dailyFocus = daily;
      _listStats = listStats;
      _streaks = streaks;
      _isLoading = false;
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.surface,
              colors.primaryContainer.withValues(alpha: 0.25),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStats,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Current Streak',
                            value: '${_streaks[1]} days',
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.emoji_events_rounded,
                            label: 'Longest Streak',
                            value: '${_streaks[2]} days',
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.check_circle_rounded,
                            label: 'Tasks Done',
                            value: '${_stats['completed_tasks']}',
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.timer_rounded,
                            label: 'Today',
                            value: _formatDuration(_stats['today_seconds'] as int),
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.play_circle_rounded,
                            label: 'Sessions',
                            value: '${_stats['total_sessions']}',
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.schedule_rounded,
                            label: 'Total Focus',
                            value: _formatDuration(_stats['total_seconds'] as int),
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Focus Time (Last 14 Days)',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: _dailyFocus.isEmpty
                          ? Center(
                              child: Text('No data yet',
                                  style: TextStyle(
                                      color: colors.outline)))
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _dailyFocus
                                        .map((d) => (d['total_seconds'] as num).toDouble())
                                        .reduce((a, b) => a > b ? a : b) *
                                    1.2,
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final day = _dailyFocus[group.x.toInt()];
                                      return BarTooltipItem(
                                        '${day['day']}\n${_formatDuration((day['total_seconds'] as num).toInt())}',
                                        const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= _dailyFocus.length) {
                                          return const SizedBox.shrink();
                                        }
                                        final day = _dailyFocus[value.toInt()]['day'] as String;
                                        final date = DateTime.tryParse(day);
                                        if (date == null) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            DateFormat('M/d').format(date),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                      reservedSize: 22,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          _formatDuration(value.toInt()),
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _dailyFocus.asMap().entries.map((entry) {
                                  final seconds = (entry.value['total_seconds'] as num).toDouble();
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: seconds,
                                        color: colors.tertiary,
                                        width: 12,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                    if (_listStats.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Tasks by List',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ...(_listStats.map((stat) {
                        final total = stat['total'] as int? ?? 0;
                        final completed = stat['completed'] as int? ?? 0;
                        final color = Color(stat['color'] as int? ?? 0xFF2196F3);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(stat['name'] as String,
                                    style: theme.textTheme.bodyMedium),
                              ),
                              Text('$completed/$total',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList()),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
