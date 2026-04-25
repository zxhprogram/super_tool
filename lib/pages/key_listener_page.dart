import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../db/database_helper.dart';
import '../db/key_model.dart';
import '../ffi/key_listener_service.dart';

class KeyListenerPage extends StatefulWidget {
  const KeyListenerPage({super.key});

  @override
  State<KeyListenerPage> createState() => _KeyListenerPageState();
}

class _KeyListenerPageState extends State<KeyListenerPage> {
  StreamSubscription<String>? _subscription;

  String _currentKey = '';
  final List<String> _history = [];
  static const int _maxHistory = 50;

  List<KeyMinuteStat> _chartHistory = [];
  int _lastMinuteTs = 0;

  @override
  void initState() {
    super.initState();
    _subscription = keyListenerService.keyEvents.listen((event) {
      setState(() {
        _history.insert(0, event);
        final parts = event.split(':');
        if (parts.length >= 2) {
          _currentKey = parts.sublist(1).join(':');
        }
        if (_history.length > _maxHistory) {
          _history.removeRange(_maxHistory, _history.length);
        }
      });
      _maybeRefreshHistory();
    });
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final rows = await DatabaseHelper().getRecentKeyStats(limit: 30);
    setState(() => _chartHistory = rows.reversed.toList());
  }

  void _maybeRefreshHistory() {
    final nowMinuteTs =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ 60 * 60;
    if (nowMinuteTs != _lastMinuteTs) {
      _lastMinuteTs = nowMinuteTs;
      _loadHistory();
    }
  }

  void _startListening() {
    keyListenerService.start();
    DatabaseHelper().setSetting('key_listener_enabled', 'true');
    setState(() {});
  }

  void _stopListening() {
    keyListenerService.stop();
    DatabaseHelper().setSetting('key_listener_enabled', 'false');
    setState(() {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isListening = keyListenerService.isListening;
    final sessionCount = keyListenerService.sessionCount;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('按键监听').h2(),
          const Gap(8),
          Text(
            '全局键盘事件监听，按键释放时记录',
            style: TextStyle(color: theme.colorScheme.mutedForeground),
          ),
          const Gap(24),
          Card(
            child: SizedBox(
              width: double.infinity,
              height: 120,
              child: Center(
                child: Text(
                  _currentKey.isEmpty ? '等待按键...' : _currentKey,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _currentKey.isEmpty
                        ? theme.colorScheme.mutedForeground
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const Gap(16),
          Row(
            children: [
              PrimaryButton(
                onPressed: isListening ? null : _startListening,
                leading: const Icon(Icons.play_arrow),
                child: const Text('开始监听'),
              ),
              const Gap(8),
              SecondaryButton(
                onPressed: isListening ? _stopListening : null,
                leading: const Icon(Icons.stop),
                child: const Text('停止监听'),
              ),
              const Gap(8),
              DestructiveButton(
                onPressed: _history.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _history.clear();
                          _currentKey = '';
                        });
                      },
                leading: const Icon(Icons.clear_all),
                child: const Text('清空'),
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              _StatChip(
                label: '本次按键',
                value: '$sessionCount 次',
                color: theme.colorScheme.primary,
              ),
              const Gap(12),
              _StatChip(
                label: '监听状态',
                value: isListening ? '运行中' : '已停止',
                color: isListening
                    ? const Color(0xFF4ADE80)
                    : theme.colorScheme.mutedForeground,
              ),
            ],
          ),
          const Gap(16),
          const Text('按键频率（最近30分钟）').semiBold(),
          const Gap(8),
          SizedBox(
            height: 160,
            child: _KeyChart(data: _chartHistory),
          ),
          const Gap(16),
          const Text('按键历史').semiBold(),
          const Gap(8),
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Text(
                      '暂无记录',
                      style: TextStyle(
                          color: theme.colorScheme.mutedForeground),
                    ),
                  )
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final event = _history[index];
                      final parts = event.split(':');
                      final key = parts.length >= 2
                          ? parts.sublist(1).join(':')
                          : '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up,
                              size: 16,
                              color: theme.colorScheme.mutedForeground,
                            ),
                            const Gap(8),
                            Text(
                              key,
                              style:
                                  const TextStyle(fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      );
                    },
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

class _KeyChart extends StatelessWidget {
  final List<KeyMinuteStat> data;

  const _KeyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Center(
        child: Text(
          '暂无统计数据，按键后将自动记录',
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
      );
    }

    final barGroups = data.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.keyCount.toDouble(),
            color: theme.colorScheme.primary,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

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
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
              '${rod.toY.toInt()} 次',
              TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
