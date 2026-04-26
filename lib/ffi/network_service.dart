import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import 'network_bindings.dart';

final networkService = NetworkService();

@immutable
class NetworkSnapshot {
  final int uploadBps;
  final int downloadBps;
  final int totalSent;
  final int totalRecv;

  const NetworkSnapshot({
    required this.uploadBps,
    required this.downloadBps,
    required this.totalSent,
    required this.totalRecv,
  });
}

class NetworkService {
  final _bindings = NetworkBindings();
  final _controller = StreamController<NetworkSnapshot>.broadcast();

  int? _prevSent;
  int? _prevRecv;

  int _sessionSent = 0;
  int _sessionRecv = 0;

  int _minuteBucketSent = 0;
  int _minuteBucketRecv = 0;
  int? _currentMinuteTs;

  Timer? _timer;
  bool _running = false;

  Stream<NetworkSnapshot> get snapshots => _controller.stream;

  NetworkSnapshot get lastSnapshot => NetworkSnapshot(
        uploadBps: 0,
        downloadBps: 0,
        totalSent: _sessionSent,
        totalRecv: _sessionRecv,
      );

  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  void _tick() {
    final raw = _bindings.getNetStats();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final sent = (map['bytes_sent'] as num).toInt();
    final recv = (map['bytes_recv'] as num).toInt();

    int deltaSent = 0;
    int deltaRecv = 0;

    if (_prevSent != null && _prevRecv != null) {
      deltaSent = sent >= _prevSent! ? sent - _prevSent! : sent;
      deltaRecv = recv >= _prevRecv! ? recv - _prevRecv! : recv;
    }

    _prevSent = sent;
    _prevRecv = recv;

    _sessionSent += deltaSent;
    _sessionRecv += deltaRecv;

    _accumulateMinute(deltaSent, deltaRecv);

    _controller.add(NetworkSnapshot(
      uploadBps: deltaSent,
      downloadBps: deltaRecv,
      totalSent: _sessionSent,
      totalRecv: _sessionRecv,
    ));
  }

  void _accumulateMinute(int dSent, int dRecv) {
    final nowMinuteTs =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ 60 * 60;

    _currentMinuteTs ??= nowMinuteTs;

    if (nowMinuteTs == _currentMinuteTs) {
      _minuteBucketSent += dSent;
      _minuteBucketRecv += dRecv;
    } else {
      _persistMinute(_currentMinuteTs!, _minuteBucketSent, _minuteBucketRecv);
      _currentMinuteTs = nowMinuteTs;
      _minuteBucketSent = dSent;
      _minuteBucketRecv = dRecv;
    }
  }

  void _persistMinute(int ts, int sent, int recv) {
    DatabaseHelper().insertNetMinuteStat(
      minuteTs: ts,
      bytesSent: sent,
      bytesRecv: recv,
    );
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
