import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../db/database_helper.dart';
import 'mouse_listener_bindings.dart';

final mouseListenerService = MouseListenerService();

class MouseListenerService {
  final MouseListenerBindings _bindings;
  final _controller = StreamController<String>.broadcast();
  NativeCallable<Void Function(Pointer<Utf8>)>? _nativeCallable;
  bool _listening = false;

  int _leftCount = 0;
  int _rightCount = 0;
  int _middleCount = 0;

  int _minuteBucketCount = 0;
  int? _currentMinuteTs;

  MouseListenerService() : _bindings = MouseListenerBindings();

  Stream<String> get mouseEvents => _controller.stream;
  bool get isListening => _listening;
  int get sessionTotal => _leftCount + _rightCount + _middleCount;
  int get leftCount => _leftCount;
  int get rightCount => _rightCount;
  int get middleCount => _middleCount;

  void start() {
    if (_listening) return;
    _listening = true;

    _nativeCallable = NativeCallable<Void Function(Pointer<Utf8>)>.listener(
      _onMouseEvent,
    );

    _bindings.registerMouseCallback(_nativeCallable!.nativeFunction);
    _bindings.startMouseListener();
  }

  void stop() {
    if (!_listening) return;
    _listening = false;
    _bindings.stopMouseListener();
    _nativeCallable?.close();
    _nativeCallable = null;
  }

  void _onMouseEvent(Pointer<Utf8> eventPtr) {
    if (eventPtr == nullptr) return;
    final btn = eventPtr.toDartString();
    _bindings.freeString(eventPtr);

    switch (btn) {
      case 'left':
        _leftCount++;
      case 'right':
        _rightCount++;
      case 'middle':
        _middleCount++;
    }

    _controller.add(btn);
    _accumulateMinute();
  }

  void _accumulateMinute() {
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
    DatabaseHelper().insertMouseMinuteStat(minuteTs: ts, clickCount: count);
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
