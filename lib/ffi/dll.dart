import 'dart:ffi';
import '../utils/app_logger.dart';

final DynamicLibrary dylib = _loadDylib();

DynamicLibrary _loadDylib() {
  const name = 'assets/dylib/super_tool_plugin.dll';
  try {
    logInfo('Loading DLL: $name');
    final lib = DynamicLibrary.open(name);
    logInfo('DLL loaded successfully');
    return lib;
  } catch (e, st) {
    logError('dll.dart', e, st);
    rethrow;
  }
}
