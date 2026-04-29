import 'dart:io';

import 'package:shadcn_flutter/shadcn_flutter.dart' hide MenuItem;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'app_usage/app_usage_service.dart';
import 'clipboard/clipboard_service.dart';
import 'db/database_helper.dart';
import 'ffi/key_listener_service.dart';
import 'ffi/mouse_listener_service.dart';
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

    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitle('Super Tool');
      await windowManager.setPreventClose(true);
      await windowManager.show();
    });

    networkService.start();
    sleep(.new(seconds: 1));
    logInfo('networkService started');
    clipboardService.start();
    sleep(.new(seconds: 1));
    logInfo('clipboardService started');
    appUsageService.start();
    sleep(.new(seconds: 1));
    logInfo('appUsageService started');
    mouseListenerService.start();
    sleep(.new(seconds: 1));
    logInfo('mouseListenerService started');

    final enabled = await DatabaseHelper().getSetting('key_listener_enabled');
    if (enabled == 'true') {
      keyListenerService.start();
      logInfo('keyListenerService started');
    }

    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/app_icon.ico'
          : 'assets/app_icon.png',
    );
    await trayManager.setToolTip('Super Tool');
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show_window', label: '显示窗口'),
      MenuItem.separator(),
      MenuItem(key: 'exit_app', label: '退出程序'),
    ]));

    logInfo('calling runApp');
    runApp(const MyApp());
  } catch (e, st) {
    logError('main', e, st);
    rethrow;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener, TrayListener {
  @override
  void initState() {
    windowManager.addListener(this);
    trayManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        await windowManager.show();
        await windowManager.focus();
      case 'exit_app':
        await windowManager.destroy();
    }
  }

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
