import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef _GetNetStatsNative = Pointer<Utf8> Function();
typedef _GetNetStatsDart = Pointer<Utf8> Function();

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class NetworkBindings {
  late final _GetNetStatsDart _getNetStats;
  late final _FreeStringDart _freeString;

  NetworkBindings() {
    final dylib = DynamicLibrary.open('assets/dylib/super_tool_plugin.dll');
    _getNetStats = dylib.lookupFunction<_GetNetStatsNative, _GetNetStatsDart>(
      'GetNetStats',
    );
    _freeString = dylib.lookupFunction<_FreeStringNative, _FreeStringDart>(
      'FreeString',
    );
  }

  String getNetStats() {
    final ptr = _getNetStats();
    if (ptr == nullptr) return '{"bytes_sent":0,"bytes_recv":0}';
    final json = ptr.toDartString();
    _freeString(ptr);
    return json;
  }
}
