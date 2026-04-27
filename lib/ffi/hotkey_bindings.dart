import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../utils/app_logger.dart';
import 'dll.dart';

typedef RegisterHotkeyCallbackNative = Void Function(
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);
typedef RegisterHotkeyCallbackDart = void Function(
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);

typedef StartHotkeyListenerNative = Void Function();
typedef StartHotkeyListenerDart = void Function();

typedef StopHotkeyListenerNative = Void Function();
typedef StopHotkeyListenerDart = void Function();

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class HotkeyBindings {
  late final RegisterHotkeyCallbackDart registerHotkeyCallback;
  late final StartHotkeyListenerDart startHotkeyListener;
  late final StopHotkeyListenerDart stopHotkeyListener;
  late final _FreeStringDart _freeString;

  HotkeyBindings() {
    try {
      registerHotkeyCallback = dylib
          .lookupFunction<RegisterHotkeyCallbackNative,
              RegisterHotkeyCallbackDart>('RegisterHotkeyCallback');
      startHotkeyListener = dylib.lookupFunction<StartHotkeyListenerNative,
          StartHotkeyListenerDart>('StartHotkeyListener');
      stopHotkeyListener = dylib.lookupFunction<StopHotkeyListenerNative,
          StopHotkeyListenerDart>('StopHotkeyListener');
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
