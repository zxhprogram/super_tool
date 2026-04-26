import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    appUsageService.start();
    _loadSummary();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _loadSummary());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final summaries = await DatabaseHelper().getAppUsageSummary();
    if (mounted) {
      setState(() {
        _summaries = summaries;
        _loading = false;
      });
    }
  }

  Future<void> _loadDetail(String processName) async {
    final sinceTs =
        DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch ~/
            1000;
    final data = await DatabaseHelper()
        .getAppUsageByProcess(processName: processName, sinceTs: sinceTs);
    if (mounted) {
      setState(() {
        _detailData = data;
      });
    }
  }

  void _selectProcess(String name) {
    setState(() => _selectedProcess = name);
    _loadDetail(name);
  }

  String _fmtDuration(int seconds) {
    if (seconds >= 3600) {
      return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
    }
    if (seconds >= 60) return '${seconds ~/ 60}m';
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('应用使用统计').h2(),
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
                            child: ListView.separated(
                              itemCount: _summaries.length,
                              separatorBuilder: (context, i) => const Gap(6),
                              itemBuilder: (context, index) {
                                final s = _summaries[index];
                                final selected =
                                    s.processName == _selectedProcess;
                                return GestureDetector(
                                  onTap: () => _selectProcess(s.processName),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.apps,
                                            size: 16,
                                            color: selected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme
                                                    .mutedForeground,
                                          ),
                                          const Gap(8),
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
                                            _fmtDuration(s.totalSeconds),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .colorScheme.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            flex: 2,
                            child: _selectedProcess == null
                                ? Center(
                                    child: Text(
                                      '选择一个应用查看详情',
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
                                        '过去 24 小时活跃分钟数（按小时）',
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.border,
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
