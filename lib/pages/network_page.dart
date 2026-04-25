import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../db/database_helper.dart';
import '../db/network_model.dart';
import '../ffi/network_service.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  StreamSubscription<NetworkSnapshot>? _sub;

  NetworkSnapshot _snapshot = const NetworkSnapshot(
      uploadBps: 0, downloadBps: 0, totalSent: 0, totalRecv: 0);
  List<NetworkMinuteStat> _history = [];
  int _lastMinuteTs = 0;

  @override
  void initState() {
    super.initState();
    _sub = networkService.snapshots.listen((snap) {
      setState(() => _snapshot = snap);
      _maybeRefreshHistory();
    });
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final rows = await DatabaseHelper().getRecentNetStats(limit: 30);
    setState(() => _history = rows.reversed.toList());
  }

  void _maybeRefreshHistory() {
    final nowMinuteTs =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ 60 * 60;
    if (nowMinuteTs != _lastMinuteTs) {
      _lastMinuteTs = nowMinuteTs;
      _loadHistory();
    }
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('网络监控').h2(),
          const Gap(8),
          Text(
            '实时网速 · 流量统计 · 趋势图表',
            style: TextStyle(
                color: Theme.of(context).colorScheme.mutedForeground),
          ),
          const Gap(24),
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
            ],
          ),
          const Gap(16),
          Row(
            children: [
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
          const Text('流量趋势（最近30分钟）').semiBold(),
          const Gap(12),
          Expanded(
            child: _TrafficChart(data: _history),
          ),
        ],
      ),
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
    return Card(
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
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
