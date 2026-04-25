import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db/database_helper.dart';
import 'ffi/key_listener_service.dart';
import 'ffi/network_service.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  networkService.start();

  final enabled = await DatabaseHelper().getSetting('key_listener_enabled');
  if (enabled == 'true') {
    keyListenerService.start();
  }

  runApp(const MyApp());
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
