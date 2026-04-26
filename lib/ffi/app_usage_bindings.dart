import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../utils/app_logger.dart';
import 'dll.dart';

typedef _GetActiveWindowInfoNative = Pointer<Utf8> Function();
typedef _GetActiveWindowInfoDart = Pointer<Utf8> Function();

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class AppUsageBindings {
  late final _GetActiveWindowInfoDart _getActiveWindowInfo;
  late final _FreeStringDart _freeString;

  AppUsageBindings() {
    try {
      _getActiveWindowInfo =
          dylib.lookupFunction<_GetActiveWindowInfoNative, _GetActiveWindowInfoDart>(
        'GetActiveWindowInfo',
      );
      _freeString = dylib.lookupFunction<_FreeStringNative, _FreeStringDart>(
        'FreeString',
      );
      logInfo('AppUsageBindings initialized');
    } catch (e, st) {
      logError('AppUsageBindings.init', e, st);
      rethrow;
    }
  }

  String? getActiveWindowInfo() {
    try {
      final ptr = _getActiveWindowInfo();
      if (ptr == nullptr) return null;
      final result = ptr.toDartString();
      _freeString(ptr);
      return result;
    } catch (e, st) {
      logError('AppUsageBindings.getActiveWindowInfo', e, st);
      return null;
    }
  }
}
