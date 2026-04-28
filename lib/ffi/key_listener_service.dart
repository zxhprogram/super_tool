import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../db/database_helper.dart';
import 'key_listener_bindings.dart';

final keyListenerService = KeyListenerService();

class KeyListenerService {
  final KeyListenerBindings _bindings;
  final _controller = StreamController<String>.broadcast();
  NativeCallable<Void Function(Pointer<Utf8>)>? _nativeCallable;
  bool _listening = false;

  int _sessionCount = 0;
  int _minuteBucketCount = 0;
  int? _currentMinuteTs;

  final Map<String, int> _sessionKeyCounts = {};
  final Map<String, int> _minuteKeyCounts = {};

  KeyListenerService() : _bindings = KeyListenerBindings();

  Stream<String> get keyEvents => _controller.stream;
  bool get isListening => _listening;
  int get sessionCount => _sessionCount;
  Map<String, int> get currentMinuteKeyCounts =>
      Map.unmodifiable(_minuteKeyCounts);

  void start() {
    if (_listening) return;
    _listening = true;

    _nativeCallable = NativeCallable<Void Function(Pointer<Utf8>)>.listener(
      _onKeyEvent,
    );

    _bindings.registerKeyCallback(_nativeCallable!.nativeFunction);
    _bindings.startKeyListener();
  }

  void stop() {
    if (!_listening) return;
    _listening = false;
    _bindings.stopKeyListener();
    _nativeCallable?.close();
    _nativeCallable = null;
  }

  void _onKeyEvent(Pointer<Utf8> eventPtr) {
    if (eventPtr == nullptr) return;
    final event = eventPtr.toDartString();
    _bindings.freeString(eventPtr);

    final keyName = event.contains(':')
        ? event.split(':').sublist(1).join(':')
        : event;
    _sessionKeyCounts[keyName] = (_sessionKeyCounts[keyName] ?? 0) + 1;
    _minuteKeyCounts[keyName] = (_minuteKeyCounts[keyName] ?? 0) + 1;

    _controller.add(event);
    _accumulateMinute();
  }

  void _accumulateMinute() {
    _sessionCount++;
    final nowMinuteTs =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ 60 * 60;
    _currentMinuteTs ??= nowMinuteTs;

    if (nowMinuteTs == _currentMinuteTs) {
      _minuteBucketCount++;
    } else {
      _persistMinute(_currentMinuteTs!, _minuteBucketCount);
      _currentMinuteTs = nowMinuteTs;
      _minuteBucketCount = 1;
    }
  }

  void _persistMinute(int ts, int count) {
    DatabaseHelper().insertKeyMinuteStat(minuteTs: ts, keyCount: count);
    if (_minuteKeyCounts.isNotEmpty) {
      DatabaseHelper()
          .insertKeyPressCounts(ts, Map<String, int>.from(_minuteKeyCounts));
      _minuteKeyCounts.clear();
    }
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
