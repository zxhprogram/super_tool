import 'dart:io';

final _logFile = File('super_tool.log');

void logInfo(String message) => _write('INFO', message);
void logError(String tag, Object error, [StackTrace? st]) {
  _write('ERROR', '[$tag] $error');
  if (st != null) _write('STACK', st.toString());
}

void _write(String level, String message) {
  try {
    _logFile.writeAsStringSync(
      '[${DateTime.now()}] $level: $message\n',
      mode: FileMode.append,
    );
  } catch (_) {}
}
