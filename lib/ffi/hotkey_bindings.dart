import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../utils/app_logger.dart';
import 'dll.dart';

typedef _RegisterHotkeyCallbackNative = Void Function(
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);
typedef _RegisterHotkeyCallbackDart = void Function(
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);

typedef _StartHotkeyListenerNative = Void Function();
typedef _StartHotkeyListenerDart = void Function();

typedef _StopHotkeyListenerNative = Void Function();
typedef _StopHotkeyListenerDart = void Function();

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class HotkeyBindings {
  late final _RegisterHotkeyCallbackDart registerHotkeyCallback;
  late final _StartHotkeyListenerDart startHotkeyListener;
  late final _StopHotkeyListenerDart stopHotkeyListener;
  late final _FreeStringDart _freeString;

  HotkeyBindings() {
    try {
      registerHotkeyCallback = dylib
          .lookupFunction<_RegisterHotkeyCallbackNative,
              _RegisterHotkeyCallbackDart>('RegisterHotkeyCallback');
      startHotkeyListener = dylib.lookupFunction<_StartHotkeyListenerNative,
          _StartHotkeyListenerDart>('StartHotkeyListener');
      stopHotkeyListener = dylib.lookupFunction<_StopHotkeyListenerNative,
          _StopHotkeyListenerDart>('StopHotkeyListener');
      _freeString =
          dylib.lookupFunction<_FreeStringNative, _FreeStringDart>('FreeString');
      logInfo('HotkeyBindings initialized');
    } catch (e, st) {
      logError('HotkeyBindings.init', e, st);
      rethrow;
    }
  }

  void freeString(Pointer<Utf8> ptr) {
    try {
      _freeString(ptr);
    } catch (e, st) {
      logError('HotkeyBindings.freeString', e, st);
    }
  }
}
