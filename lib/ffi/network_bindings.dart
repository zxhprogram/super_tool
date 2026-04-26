import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../utils/app_logger.dart';
import 'dll.dart';

typedef _GetNetStatsNative = Pointer<Utf8> Function();
typedef _GetNetStatsDart = Pointer<Utf8> Function();

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class NetworkBindings {
  late final _GetNetStatsDart _getNetStats;
  late final _FreeStringDart _freeString;

  NetworkBindings() {
    try {
      _getNetStats = dylib.lookupFunction<_GetNetStatsNative, _GetNetStatsDart>(
        'GetNetStats',
      );
      _freeString = dylib.lookupFunction<_FreeStringNative, _FreeStringDart>(
        'FreeString',
      );
      logInfo('NetworkBindings initialized');
    } catch (e, st) {
      logError('NetworkBindings.init', e, st);
      rethrow;
    }
  }

  String getNetStats() {
    try {
      final ptr = _getNetStats();
      if (ptr == nullptr) return '{"bytes_sent":0,"bytes_recv":0}';
      final json = ptr.toDartString();
      _freeString(ptr);
      return json;
    } catch (e, st) {
      logError('NetworkBindings.getNetStats', e, st);
      return '{"bytes_sent":0,"bytes_recv":0}';
    }
  }
}
