import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db/database_helper.dart';
import 'ffi/key_listener_service.dart';
import 'ffi/network_service.dart';
import 'router.dart';
import 'utils/app_logger.dart';

void main() async {
  logInfo('main() start');
  try {
    WidgetsFlutterBinding.ensureInitialized();
    logInfo('WidgetsFlutterBinding initialized');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    logInfo('sqflite initialized');
    networkService.start();
    logInfo('networkService started');

    final enabled = await DatabaseHelper().getSetting('key_listener_enabled');
    if (enabled == 'true') {
      keyListenerService.start();
      logInfo('keyListenerService started');
    }

    logInfo('calling runApp');
    runApp(const MyApp());
  } catch (e, st) {
    logError('main', e, st);
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp.router(
      title: 'Super Tool',
      theme: ThemeData(
        colorScheme: ColorSchemes.darkZinc,
        radius: 0.5,
        typography: .geist(sans: .new(fontFamily: 'Microsoft YaHei')),
      ),
      routerConfig: router,
    );
  }
}
