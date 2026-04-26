import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../utils/app_logger.dart';
import 'dll.dart';

typedef _GetSystemStatsNative = Pointer<Utf8> Function();
typedef _GetSystemStatsDart = Pointer<Utf8> Function();

typedef _GetEnvVarsNative = Pointer<Utf8> Function();
typedef _GetEnvVarsDart = Pointer<Utf8> Function();

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class SystemBindings {
  static final SystemBindings _instance = SystemBindings._();

  factory SystemBindings() => _instance;

  SystemBindings._() {
    try {
      _dylib = dylib;
      _getSystemStats = _dylib.lookupFunction<_GetSystemStatsNative, _GetSystemStatsDart>(
        'GetSystemStats',
      );
      _getEnvVars = _dylib.lookupFunction<_GetEnvVarsNative, _GetEnvVarsDart>(
        'GetEnvVars',
      );
      _freeString = _dylib.lookupFunction<_FreeStringNative, _FreeStringDart>(
        'FreeString',
      );
      logInfo('SystemBindings initialized');
    } catch (e, st) {
      logError('SystemBindings.init', e, st);
      rethrow;
    }
  }

  late final DynamicLibrary _dylib;
  late final _GetSystemStatsDart _getSystemStats;
  late final _GetEnvVarsDart _getEnvVars;
  late final _FreeStringDart _freeString;

  String? getSystemStats() {
    try {
      final ptr = _getSystemStats();
      if (ptr == nullptr) return null;
      final result = ptr.toDartString();
      _freeString(ptr);
      return result;
    } catch (e, st) {
      logError('SystemBindings.getSystemStats', e, st);
      return null;
    }
  }

  String? getEnvVars() {
    try {
      final ptr = _getEnvVars();
      if (ptr == nullptr) return null;
      final result = ptr.toDartString();
      _freeString(ptr);
      return result;
    } catch (e, st) {
      logError('SystemBindings.getEnvVars', e, st);
      return null;
    }
  }
}
