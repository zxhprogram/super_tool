import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'key_listener_bindings.dart';

class KeyListenerService {
  final KeyListenerBindings _bindings;
  final _controller = StreamController<String>.broadcast();
  NativeCallable<Void Function(Pointer<Utf8>)>? _nativeCallable;
  bool _listening = false;

  KeyListenerService() : _bindings = KeyListenerBindings();

  Stream<String> get keyEvents => _controller.stream;
  bool get isListening => _listening;

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
    _controller.add(event);
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
