import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../db/database_helper.dart';
import '../db/mouse_model.dart';
import '../ffi/mouse_listener_service.dart';

class MouseStatsPage extends StatefulWidget {
  const MouseStatsPage({super.key});

  @override
  State<MouseStatsPage> createState() => _MouseStatsPageState();
}

class _MouseStatsPageState extends State<MouseStatsPage> {
  StreamSubscription<String>? _sub;
  List<MouseMinuteStat> _chartHistory = [];
  DateTime _selectedDate = DateTime.now();
  int _lastMinuteTs = 0;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    _loadChart();
    _sub = mouseListenerService.mouseEvents.listen((_) {
      _maybeRefreshChart();
      setState(() {});
    });
  }

  Future<void> _loadChart() async {
    final rows = await DatabaseHelper().getMouseStatsByDate(_selectedDate);
    setState(() => _chartHistory = rows);
  }

  void _maybeRefreshChart() {
    if (!_isToday) return;
    final nowMinuteTs =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ 60 * 60;
    if (nowMinuteTs != _lastMinuteTs) {
      _lastMinuteTs = nowMinuteTs;
      _loadChart();
    }
  }

  void _goToPrevDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _chartHistory = [];
    });
    _loadChart();
  }

  void _goToNextDay() {
    if (_isToday) return;
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _chartHistory = [];
    });
    _loadChart();
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _chartHistory = [];
    });
    _loadChart();
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '今天';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return '昨天';
    }
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = mouseListenerService.sessionTotal;
    final left = mouseListenerService.leftCount;
    final right = mouseListenerService.rightCount;
    final middle = mouseListenerService.middleCount;
    final dayTotal =
        _chartHistory.fold<int>(0, (sum, s) => sum + s.clickCount);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('鼠标点击统计').h2(),
              const Spacer(),
            ],
          ),
          const Gap(8),
          Text(
            '全局鼠标点击事件监听，应用启动即开始统计',
            style: TextStyle(color: theme.colorScheme.mutedForeground),
          ),
          const Gap(24),
          Row(
            children: [
              _StatChip(
                label: '本次会话',
                value: '$total 次',
                color: theme.colorScheme.primary,
              ),
              const Gap(12),
              _StatChip(
                label: '左键',
                value: '$left 次',
                color: const Color(0xFF4ADE80),
              ),
              const Gap(12),
              _StatChip(
                label: '右键',
                value: '$right 次',
                color: const Color(0xFFFBBF24),
              ),
              const Gap(12),
              _StatChip(
                label: '中键',
                value: '$middle 次',
                color: const Color(0xFF60A5FA),
              ),
            ],
          ),
          const Gap(24),
          Row(
            children: [
              OutlineButton(
                onPressed: _goToPrevDay,
                density: ButtonDensity.compact,
                child: const Icon(Icons.chevron_left, size: 18),
              ),
              const Gap(8),
              Text(
                _formatDate(_selectedDate),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Gap(8),
              OutlineButton(
                onPressed: _isToday ? null : _goToNextDay,
                density: ButtonDensity.compact,
                child: const Icon(Icons.chevron_right, size: 18),
              ),
              if (!_isToday) ...[
                const Gap(8),
                OutlineButton(
                  onPressed: _goToToday,
                  density: ButtonDensity.compact,
                  child: const Text('今天'),
                ),
              ],
              const Spacer(),
              _StatChip(
                label: '当日合计',
                value: '$dayTotal 次',
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const Gap(12),
          Text(
            '点击趋势（${_formatDate(_selectedDate)}）',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ).muted(),
          const Gap(8),
          Expanded(
            child: _MouseChart(data: _chartHistory),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.mutedForeground,
              ),
            ),
            const Gap(8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MouseChart extends StatelessWidget {
  final List<MouseMinuteStat> data;

  const _MouseChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Center(
        child: Text(
          '暂无统计数据，点击鼠标后将自动记录',
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
      );
    }

    final barGroups = data.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.clickCount.toDouble(),
            color: theme.colorScheme.primary,
            width: data.length > 30 ? 6 : 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

    final interval =
        data.length > 12 ? (data.length / 6).ceilToDouble() : 1.0;

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: interval,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final ts = data[idx].minuteTs;
                final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                return Text(
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.mutedForeground,
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final ts = data[group.x].minuteTs;
              final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
              final time =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              return BarTooltipItem(
                '$time\n${rod.toY.toInt()} 次',
                TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
