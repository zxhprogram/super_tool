import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../widgets/page_wrapper.dart';

import '../app_usage/app_usage_service.dart';
import '../db/app_usage_model.dart';
import '../db/database_helper.dart';

class AppUsagePage extends StatefulWidget {
  const AppUsagePage({super.key});

  @override
  State<AppUsagePage> createState() => _AppUsagePageState();
}

class _AppUsagePageState extends State<AppUsagePage> {
  List<AppUsageSummary> _summaries = [];
  String? _selectedProcess;
  List<AppUsageMinute> _detailData = [];
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  Timer? _refreshTimer;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    appUsageService.start();
    _loadSummary();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _maybeRefresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _maybeRefresh() {
    if (_isToday) _loadSummary();
  }

  Future<void> _loadSummary() async {
    final summaries =
        await DatabaseHelper().getAppUsageSummaryByDate(_selectedDate);
    if (mounted) {
      setState(() {
        _summaries = summaries;
        _loading = false;
      });
    }
  }

  Future<void> _loadDetail(String processName) async {
    final data = await DatabaseHelper().getAppUsageByProcessAndDate(
      processName: processName,
      date: _selectedDate,
    );
    if (mounted) {
      setState(() => _detailData = data);
    }
  }

  void _selectProcess(String name) {
    setState(() => _selectedProcess = name);
    _loadDetail(name);
  }

  void _goToPrevDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _summaries = [];
      _detailData = [];
      _selectedProcess = null;
    });
    _loadSummary();
  }

  void _goToNextDay() {
    if (_isToday) return;
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _summaries = [];
      _detailData = [];
      _selectedProcess = null;
    });
    _loadSummary();
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _summaries = [];
      _detailData = [];
      _selectedProcess = null;
    });
    _loadSummary();
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

  String _fmtDuration(int seconds) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    if (seconds >= 60) return '${seconds ~/ 60}m';
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayTotal =
        _summaries.fold<int>(0, (sum, s) => sum + s.totalSeconds);
    final maxSeconds =
        _summaries.isEmpty ? 0 : _summaries.first.totalSeconds;

    return PageWrapper(
      title: '应用使用统计',
      subtitle: '追踪前台应用使用时长，按天查看使用分布',
      breadcrumbLabel: '统计',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                value: _fmtDuration(dayTotal),
                color: theme.colorScheme.primary,
              ),
              const Gap(8),
              _StatChip(
                label: '应用数',
                value: '${_summaries.length}',
                color: const Color(0xFF60A5FA),
              ),
            ],
          ),
          const Gap(16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _summaries.isEmpty
                    ? Center(
                        child: Text(
                          '暂无使用记录',
                          style: TextStyle(
                              color: theme.colorScheme.mutedForeground),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _AppList(
                              summaries: _summaries,
                              maxSeconds: maxSeconds,
                              selectedProcess: _selectedProcess,
                              onSelect: _selectProcess,
                              fmtDuration: _fmtDuration,
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            flex: 2,
                            child: _selectedProcess == null
                                ? Center(
                                    child: Text(
                                      '选择一个应用查看活跃时段',
                                      style: TextStyle(
                                          color: theme
                                              .colorScheme.mutedForeground),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedProcess!)
                                          .semiBold()
                                          .base(),
                                      const Gap(4),
                                      Text(
                                        '每小时活跃分钟数（${_formatDate(_selectedDate)}）',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme.mutedForeground,
                                        ),
                                      ),
                                      const Gap(16),
                                      Expanded(
                                        child: _ActivityChart(
                                            detailData: _detailData),
                                      ),
                                    ],
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
    return SurfaceCard(
      surfaceBlur: 6,
      surfaceOpacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.mutedForeground,
              ),
            ),
            const Gap(6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
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

class _AppList extends StatelessWidget {
  final List<AppUsageSummary> summaries;
  final int maxSeconds;
  final String? selectedProcess;
  final ValueChanged<String> onSelect;
  final String Function(int) fmtDuration;

  const _AppList({
    required this.summaries,
    required this.maxSeconds,
    required this.selectedProcess,
    required this.onSelect,
    required this.fmtDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      itemCount: summaries.length,
      separatorBuilder: (_, __) => const Gap(4),
      itemBuilder: (context, index) {
        final s = summaries[index];
        final selected = s.processName == selectedProcess;
        final fraction =
            maxSeconds > 0 ? s.totalSeconds / maxSeconds : 0.0;
        final rankColor = index == 0
            ? const Color(0xFFFFD700)
            : index == 1
                ? const Color(0xFFC0C0C0)
                : index == 2
                    ? const Color(0xFFCD7F32)
                    : theme.colorScheme.mutedForeground;

        return GestureDetector(
          onTap: () => onSelect(s.processName),
          child: Card(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: rankColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Gap(6),
                      Icon(
                        Icons.apps,
                        size: 14,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.mutedForeground,
                      ),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          s.processName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        fmtDuration(s.totalSeconds),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const Gap(6),
                  Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final List<AppUsageMinute> detailData;

  const _ActivityChart({required this.detailData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hourBuckets = List<double>.filled(24, 0);
    for (final m in detailData) {
      final dt = DateTime.fromMillisecondsSinceEpoch(m.minuteTs * 1000);
      hourBuckets[dt.hour] += m.seconds / 60.0;
    }

    final bars = List.generate(
      24,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: hourBuckets[i],
            color: theme.colorScheme.primary,
            width: 10,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      ),
    );

    return BarChart(
      BarChartData(
        barGroups: bars,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
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
              interval: 3,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}h',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
              '${group.x}h\n${rod.toY.toStringAsFixed(1)}m',
              TextStyle(
                color: theme.colorScheme.primaryForeground,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
