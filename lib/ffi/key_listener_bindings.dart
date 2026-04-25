import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef _StartKeyListenerNative = Void Function();
typedef _StopKeyListenerNative = Void Function();

typedef _RegisterKeyCallbackNative = Void Function(
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);
typedef _RegisterKeyCallbackDart = void Function(
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class KeyListenerBindings {
  late final void Function() startKeyListener;
  late final void Function() stopKeyListener;
  late final void Function(
      Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>) registerKeyCallback;
  late final _FreeStringDart _freeString;

  KeyListenerBindings() {
    final dylib = DynamicLibrary.open('super_tool_plugin.dll');

    startKeyListener = dylib
        .lookupFunction<_StartKeyListenerNative, void Function()>(
            'StartKeyListener');

    stopKeyListener = dylib
        .lookupFunction<_StopKeyListenerNative, void Function()>(
            'StopKeyListener');

    registerKeyCallback = dylib
        .lookupFunction<_RegisterKeyCallbackNative, _RegisterKeyCallbackDart>(
            'RegisterKeyCallback');

    _freeString = dylib
        .lookupFunction<_FreeStringNative, _FreeStringDart>('FreeString');
  }

  void freeString(Pointer<Utf8> ptr) => _freeString(ptr);
}
