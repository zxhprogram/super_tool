import 'dart:async';
import 'dart:convert';

import '../db/database_helper.dart';
import '../ffi/app_usage_bindings.dart';
import '../utils/app_logger.dart';

final appUsageService = AppUsageService();

class AppUsageService {
  Timer? _timer;
  bool _busy = false;
  AppUsageBindings? _bindings;

  String _currentProcess = '';
  int _currentMinuteTs = 0;
  int _totalSeconds = 0;
  int _persistedSeconds = 0;

  void start() {
    if (_timer != null) return;
    try {
      _bindings = AppUsageBindings();
    } catch (e, st) {
      logError('AppUsageService.start', e, st);
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    logInfo('AppUsageService started');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      final json = _bindings?.getActiveWindowInfo();
      if (json == null) return;
      final data = jsonDecode(json) as Map<String, dynamic>;
      final processName = (data['processName'] as String? ?? '').trim();
      if (processName.isEmpty) return;

      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final minuteTs = (nowSec ~/ 60) * 60;

      if (processName == _currentProcess && minuteTs == _currentMinuteTs) {
        _totalSeconds++;
        if (_totalSeconds % 30 == 0) await _flush();
      } else {
        await _flush();
        _currentProcess = processName;
        _currentMinuteTs = minuteTs;
        _totalSeconds = 1;
        _persistedSeconds = 0;
      }
    } catch (e, st) {
      logError('AppUsageService._tick', e, st);
    } finally {
      _busy = false;
    }
  }

  Future<void> _flush() async {
    if (_currentProcess.isEmpty) return;
    final delta = _totalSeconds - _persistedSeconds;
    if (delta <= 0) return;
    await DatabaseHelper().addAppUsageSeconds(
      processName: _currentProcess,
      minuteTs: _currentMinuteTs,
      seconds: delta,
    );
    _persistedSeconds = _totalSeconds;
  }

  void dispose() => stop();
}
