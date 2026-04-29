import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../db/database_helper.dart';
import '../db/network_model.dart';
import '../ffi/network_service.dart';
import '../widgets/page_wrapper.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  StreamSubscription<NetworkSnapshot>? _sub;

  NetworkSnapshot _snapshot = const NetworkSnapshot(
      uploadBps: 0, downloadBps: 0, totalSent: 0, totalRecv: 0);

  DateTime _selectedDate = DateTime.now();
  List<NetworkMinuteStat> _dateHistory = [];
  int _lastMinuteTs = 0;

  @override
  void initState() {
    super.initState();
    _sub = networkService.snapshots.listen((snap) {
      setState(() => _snapshot = snap);
      _maybeRefreshHistory();
    });
    _loadDateHistory();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Future<void> _loadDateHistory() async {
    final rows = await DatabaseHelper().getNetStatsByDate(_selectedDate);
    setState(() => _dateHistory = rows);
  }

  void _maybeRefreshHistory() {
    if (!_isToday) return;
    final nowMinuteTs =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ 60 * 60;
    if (nowMinuteTs != _lastMinuteTs) {
      _lastMinuteTs = nowMinuteTs;
      _loadDateHistory();
    }
  }

  void _goToPrevDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _dateHistory = [];
    });
    _loadDateHistory();
  }

  void _goToNextDay() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final next = _selectedDate.add(const Duration(days: 1));
    if (next.isAfter(tomorrow)) return;
    setState(() {
      _selectedDate = next;
      _dateHistory = [];
    });
    _loadDateHistory();
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _dateHistory = [];
    });
    _loadDateHistory();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _formatSpeed(int bps) {
    if (bps >= 1024 * 1024) {
      return '${(bps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }
    return '${(bps / 1024).toStringAsFixed(1)} KB/s';
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalSent =
        _dateHistory.fold<int>(0, (sum, s) => sum + s.bytesSent);
    final totalRecv =
        _dateHistory.fold<int>(0, (sum, s) => sum + s.bytesRecv);

    final isNextDisabled = _isToday;

    return PageWrapper(
      title: '网络监控',
      subtitle: '实时网速 · 流量统计 · 趋势图表',
      breadcrumbLabel: '监控',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.upload,
                  label: '上传速度',
                  value: _formatSpeed(_snapshot.uploadBps),
                ),
              ),
              const Gap(16),
              Expanded(
                child: _StatCard(
                  icon: Icons.download,
                  label: '下载速度',
                  value: _formatSpeed(_snapshot.downloadBps),
                ),
              ),
              const Gap(16),
              Expanded(
                child: _StatCard(
                  icon: Icons.cloud_upload,
                  label: '本次上传',
                  value: _formatBytes(_snapshot.totalSent),
                ),
              ),
              const Gap(16),
              Expanded(
                child: _StatCard(
                  icon: Icons.cloud_download,
                  label: '本次下载',
                  value: _formatBytes(_snapshot.totalRecv),
                ),
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
                onPressed: isNextDisabled ? null : _goToNextDay,
                density: ButtonDensity.compact,
                child: const Icon(Icons.chevron_right, size: 18),
              ),
              const Gap(8),
              if (!_isToday)
                OutlineButton(
                  onPressed: _goToToday,
                  density: ButtonDensity.compact,
                  child: const Text('今天'),
                ),
              const Spacer(),
              _DateSumChip(
                icon: Icons.cloud_upload,
                label: '上传',
                value: _formatBytes(totalSent),
                color: theme.colorScheme.primary,
              ),
              const Gap(12),
              _DateSumChip(
                icon: Icons.cloud_download,
                label: '下载',
                value: _formatBytes(totalRecv),
                color: const Color(0xFF60A5FA),
              ),
            ],
          ),
          const Gap(12),
          Text(
            '流量趋势（${_formatDate(_selectedDate)}）',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ).muted(),
          const Gap(8),
          Expanded(
            child: _TrafficChart(data: _dateHistory),
          ),
        ],
      ),
    );
  }
}

class _DateSumChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DateSumChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const Gap(4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.mutedForeground,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      surfaceBlur: 6,
      surfaceOpacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const Gap(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                const Gap(4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficChart extends StatelessWidget {
  final List<NetworkMinuteStat> data;

  const _TrafficChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Center(
        child: Text(
          '暂无数据，流量数据将在每分钟结束后记录',
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
      );
    }

    final sentSpots = <FlSpot>[];
    final recvSpots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final mbSent = data[i].bytesSent / (1024 * 1024);
      final mbRecv = data[i].bytesRecv / (1024 * 1024);
      sentSpots.add(FlSpot(i.toDouble(), mbSent));
      recvSpots.add(FlSpot(i.toDouble(), mbRecv));
    }

    final primaryColor = theme.colorScheme.primary;

    return LineChart(
      LineChartData(
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: sentSpots,
            isCurved: true,
            color: primaryColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withValues(alpha: 0.15),
            ),
          ),
          LineChartBarData(
            spots: recvSpots,
            isCurved: true,
            color: const Color(0xFF60A5FA),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF60A5FA).withValues(alpha: 0.10),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              'MB',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
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
              interval: data.length > 12 ? (data.length / 6).ceilToDouble() : 1,
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
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final label = spot.barIndex == 0 ? '↑' : '↓';
              return LineTooltipItem(
                '$label ${spot.y.toStringAsFixed(2)} MB',
                TextStyle(
                  color: spot.barIndex == 0
                      ? primaryColor
                      : const Color(0xFF60A5FA),
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
