import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../utils/app_logger.dart';
import 'dll.dart';

typedef _StartMouseListenerNative = Void Function();
typedef _StopMouseListenerNative = Void Function();

typedef _RegisterMouseCallbackNative = Void Function(
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);
typedef _RegisterMouseCallbackDart = void Function(
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class MouseListenerBindings {
  late final void Function() startMouseListener;
  late final void Function() stopMouseListener;
  late final void Function(
      Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>) registerMouseCallback;
  late final _FreeStringDart _freeString;

  MouseListenerBindings() {
    try {
      startMouseListener = dylib
          .lookupFunction<_StartMouseListenerNative, void Function()>(
              'StartMouseListener');
      stopMouseListener = dylib
          .lookupFunction<_StopMouseListenerNative, void Function()>(
              'StopMouseListener');
      registerMouseCallback = dylib.lookupFunction<
          _RegisterMouseCallbackNative,
          _RegisterMouseCallbackDart>('RegisterMouseCallback');
      _freeString = dylib
          .lookupFunction<_FreeStringNative, _FreeStringDart>('FreeString');
      logInfo('MouseListenerBindings initialized');
    } catch (e, st) {
      logError('MouseListenerBindings.init', e, st);
      rethrow;
    }
  }

  void freeString(Pointer<Utf8> ptr) {
    try {
      _freeString(ptr);
    } catch (e, st) {
      logError('MouseListenerBindings.freeString', e, st);
    }
  }
}
