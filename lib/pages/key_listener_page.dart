import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../db/database_helper.dart';
import '../db/key_model.dart';
import '../ffi/key_listener_service.dart';

// ---------------------------------------------------------------------------
// Key definition for keyboard layout
// ---------------------------------------------------------------------------

class _KeyDef {
  final String label;
  final String dbName;
  final double units;
  const _KeyDef(this.label, this.dbName, [this.units = 1.0]);
}

const double _kUnit = 40.0;
const double _kHeight = 34.0;
const double _kMargin = 2.0;

const _kRow0 = <_KeyDef>[
  _KeyDef('Esc', 'Escape', 1.5),
  _KeyDef('F1', 'F1'), _KeyDef('F2', 'F2'), _KeyDef('F3', 'F3'), _KeyDef('F4', 'F4'),
  _KeyDef('F5', 'F5'), _KeyDef('F6', 'F6'), _KeyDef('F7', 'F7'), _KeyDef('F8', 'F8'),
  _KeyDef('F9', 'F9'), _KeyDef('F10', 'F10'), _KeyDef('F11', 'F11'), _KeyDef('F12', 'F12'),
];

const _kRow1 = <_KeyDef>[
  _KeyDef('`', '`'), _KeyDef('1', '1'), _KeyDef('2', '2'), _KeyDef('3', '3'),
  _KeyDef('4', '4'), _KeyDef('5', '5'), _KeyDef('6', '6'), _KeyDef('7', '7'),
  _KeyDef('8', '8'), _KeyDef('9', '9'), _KeyDef('0', '0'),
  _KeyDef('-', '-'), _KeyDef('=', '='), _KeyDef('⌫', 'Backspace', 2.0),
];

const _kRow2 = <_KeyDef>[
  _KeyDef('Tab', 'Tab', 1.5),
  _KeyDef('Q', 'Q'), _KeyDef('W', 'W'), _KeyDef('E', 'E'), _KeyDef('R', 'R'),
  _KeyDef('T', 'T'), _KeyDef('Y', 'Y'), _KeyDef('U', 'U'), _KeyDef('I', 'I'),
  _KeyDef('O', 'O'), _KeyDef('P', 'P'), _KeyDef('[', '['), _KeyDef(']', ']'),
  _KeyDef('\\', '\\', 1.5),
];

const _kRow3 = <_KeyDef>[
  _KeyDef('Caps', 'CapsLock', 1.75),
  _KeyDef('A', 'A'), _KeyDef('S', 'S'), _KeyDef('D', 'D'), _KeyDef('F', 'F'),
  _KeyDef('G', 'G'), _KeyDef('H', 'H'), _KeyDef('J', 'J'), _KeyDef('K', 'K'),
  _KeyDef('L', 'L'), _KeyDef(';', ';'), _KeyDef("'", "'"),
  _KeyDef('Enter', 'Enter', 2.25),
];

const _kRow4 = <_KeyDef>[
  _KeyDef('Shift', 'Shift', 2.25),
  _KeyDef('Z', 'Z'), _KeyDef('X', 'X'), _KeyDef('C', 'C'), _KeyDef('V', 'V'),
  _KeyDef('B', 'B'), _KeyDef('N', 'N'), _KeyDef('M', 'M'),
  _KeyDef(',', ','), _KeyDef('.', '.'), _KeyDef('/', '/'),
  _KeyDef('Shift', 'Shift', 2.75),
];

const _kRow5 = <_KeyDef>[
  _KeyDef('Ctrl', 'Ctrl', 1.25), _KeyDef('Win', 'Win', 1.25),
  _KeyDef('Alt', 'Alt', 1.25), _KeyDef('Space', 'Space', 6.25),
  _KeyDef('Alt', 'Alt', 1.25), _KeyDef('Win', 'Win', 1.25),
  _KeyDef('Menu', 'Menu', 1.25), _KeyDef('Ctrl', 'Ctrl', 1.25),
];

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class KeyListenerPage extends StatefulWidget {
  const KeyListenerPage({super.key});

  @override
  State<KeyListenerPage> createState() => _KeyListenerPageState();
}

class _KeyListenerPageState extends State<KeyListenerPage> {
  StreamSubscription<String>? _subscription;

  String _currentKey = '';
  DateTime _selectedDate = DateTime.now();

  // Pure DB counts for selected date (without current partial minute)
  Map<String, int> _dbKeyCounts = {};
  List<KeyMinuteStat> _trendData = [];

  int _lastMinuteTs = 0;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // Merged view: session data for today (resets each launch), DB data for past dates
  Map<String, int> get _effectiveCounts {
    if (!_isToday) return _dbKeyCounts;
    return keyListenerService.sessionKeyCounts;
  }

  @override
  void initState() {
    super.initState();
    _subscription = keyListenerService.keyEvents.listen((event) {
      final parts = event.split(':');
      if (parts.length >= 2) {
        setState(() => _currentKey = parts.sublist(1).join(':'));
      } else {
        setState(() => _currentKey = event);
      }
      if (_isToday) {
        setState(() {}); // rebuild to reflect updated currentMinuteKeyCounts
        _maybeRefreshTrend();
      }
    });
    _loadDateData();
  }

  Future<void> _loadDateData() async {
    final counts = await DatabaseHelper().getKeyCountsByDate(_selectedDate);
    final trend = await DatabaseHelper().getKeyStatsByDate(_selectedDate);
    setState(() {
      _dbKeyCounts = counts;
      _trendData = trend;
    });
  }

  void _maybeRefreshTrend() {
    final nowMinuteTs =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ 60 * 60;
    if (nowMinuteTs != _lastMinuteTs) {
      _lastMinuteTs = nowMinuteTs;
      _loadDateData();
    }
  }

  void _goToPrevDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _dbKeyCounts = {};
      _trendData = [];
    });
    _loadDateData();
  }

  void _goToNextDay() {
    if (_isToday) return;
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _dbKeyCounts = {};
      _trendData = [];
    });
    _loadDateData();
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _dbKeyCounts = {};
      _trendData = [];
    });
    _loadDateData();
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
    final isListening = keyListenerService.isListening;
    final counts = _effectiveCounts;
    final totalCount = counts.values.fold(0, (s, v) => s + v);
    final topEntry = counts.isEmpty
        ? null
        : counts.entries.reduce((a, b) => a.value > b.value ? a : b);
    final maxCount = counts.isEmpty ? 0 : topEntry!.value;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('按键监听').h2(),
              const Spacer(),
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
            ],
          ),
          const Gap(6),
          Text(
            '全局键盘事件监听，按键释放时记录',
            style: TextStyle(color: theme.colorScheme.mutedForeground),
          ),
          const Gap(20),
          // Date nav + stats
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
              const Gap(16),
              _StatChip(
                label: _isToday ? '本次' : '总按键',
                value: _isToday
                    ? '${keyListenerService.sessionCount} 次'
                    : '$totalCount 次',
                color: theme.colorScheme.primary,
              ),
              const Gap(8),
              _StatChip(
                label: '最高频',
                value: topEntry == null ? '-' : topEntry.key,
                color: const Color(0xFFFFD700),
              ),
              if (_isToday) ...[
                const Gap(8),
                _StatChip(
                  label: '当前键',
                  value: _currentKey.isEmpty ? '-' : _currentKey,
                  color: const Color(0xFF60A5FA),
                ),
                const Gap(8),
                _StatChip(
                  label: '状态',
                  value: isListening ? '运行中' : '已停止',
                  color: isListening
                      ? const Color(0xFF4ADE80)
                      : theme.colorScheme.mutedForeground,
                ),
              ],
            ],
          ),
          const Gap(20),
          // Keyboard heatmap
          const Text('键盘热力图').semiBold(),
          const Gap(8),
          SizedBox(
            height: (_kHeight + _kMargin * 2) * 6 + 8,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _KeyboardHeatmap(counts: counts, maxCount: maxCount),
            ),
          ),
          const Gap(16),
          // Bottom: Top 10 + Trend chart
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _TopKeysList(counts: counts),
                ),
                const Gap(16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('按键趋势（分钟）').semiBold(),
                      const Gap(8),
                      Expanded(child: _KeyTrendChart(data: _trendData)),
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

// ---------------------------------------------------------------------------
// _StatChip
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.mutedForeground)),
            const Gap(6),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _KeyboardHeatmap
// ---------------------------------------------------------------------------

class _KeyboardHeatmap extends StatelessWidget {
  final Map<String, int> counts;
  final int maxCount;

  const _KeyboardHeatmap(
      {required this.counts, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final rows = [_kRow0, _kRow1, _kRow2, _kRow3, _kRow4, _kRow5];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children:
          rows.map((row) => _buildRow(context, row)).toList(),
    );
  }

  Widget _buildRow(BuildContext context, List<_KeyDef> keys) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: keys
          .map((k) => _HeatKey(
                def: k,
                count: counts[k.dbName] ?? 0,
                maxCount: maxCount,
              ))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// _HeatKey
// ---------------------------------------------------------------------------

class _HeatKey extends StatelessWidget {
  final _KeyDef def;
  final int count;
  final int maxCount;

  const _HeatKey(
      {required this.def, required this.count, required this.maxCount});

  String _formatCount(int c) {
    if (c >= 1000) return '${(c / 1000).toStringAsFixed(1)}k';
    return '$c';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intensity = (maxCount > 0 && count > 0)
        ? (count / maxCount).clamp(0.0, 1.0)
        : 0.0;

    final baseColor = Colors.white.withValues(alpha: 0.08);
    final hotColor = theme.colorScheme.primary;
    final bg = Color.lerp(baseColor, hotColor, intensity)!;
    final textColor = intensity > 0.55 ? Colors.white : theme.colorScheme.foreground;
    final borderColor = intensity > 0.3
        ? hotColor.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.12);

    final keyW = def.units * _kUnit - _kMargin * 2;

    return Container(
      width: keyW,
      height: _kHeight,
      margin: const EdgeInsets.all(_kMargin),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              def.label,
              style: TextStyle(
                fontSize: def.units >= 1.5 ? 10 : 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          if (count > 0)
            Positioned(
              right: 3,
              bottom: 2,
              child: Text(
                _formatCount(count),
                style: TextStyle(
                  fontSize: 7,
                  color: textColor.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TopKeysList
// ---------------------------------------------------------------------------

class _TopKeysList extends StatelessWidget {
  final Map<String, int> counts;

  const _TopKeysList({required this.counts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(10).toList();

    if (top.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('按键排行 Top 10').semiBold(),
          const Gap(8),
          Expanded(
            child: Center(
              child: Text('暂无按键数据',
                  style: TextStyle(
                      color: theme.colorScheme.mutedForeground)),
            ),
          ),
        ],
      );
    }

    final maxVal = top.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('按键排行 Top 10').semiBold(),
        const Gap(8),
        Expanded(
          child: ListView.builder(
            itemCount: top.length,
            itemBuilder: (context, i) {
              final entry = top[i];
              final fraction =
                  maxVal > 0 ? entry.value / maxVal : 0.0;
              final rankColor = i == 0
                  ? const Color(0xFFFFD700)
                  : i == 1
                      ? const Color(0xFFC0C0C0)
                      : i == 2
                          ? const Color(0xFFCD7F32)
                          : theme.colorScheme.mutedForeground;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: rankColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Gap(6),
                    Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: fraction,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.mutedForeground,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _KeyTrendChart
// ---------------------------------------------------------------------------

class _KeyTrendChart extends StatelessWidget {
  final List<KeyMinuteStat> data;

  const _KeyTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Center(
        child: Text(
          '暂无数据，按键后将自动记录',
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
            width: data.length > 30 ? 6 : 10,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(3)),
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
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox();
                }
                final ts = data[idx].minuteTs;
                final dt =
                    DateTime.fromMillisecondsSinceEpoch(ts * 1000);
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
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
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
              final dt =
                  DateTime.fromMillisecondsSinceEpoch(ts * 1000);
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
