import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide MenuItem;
import 'package:tray_manager/tray_manager.dart';
import '../app_usage/app_usage_service.dart';
import '../clipboard/clipboard_service.dart';
import '../db/database_helper.dart';
import '../ffi/key_listener_service.dart';
import '../ffi/mouse_listener_service.dart';
import '../ffi/network_service.dart';
import '../utils/app_logger.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  String _status = '正在初始化...';
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _initialize();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _status = msg);
  }

  Future<void> _initialize() async {
    try {
      final db = DatabaseHelper();

      _setStatus('正在启动网络监控...');
      if ((await db.getSetting('network_enabled')) != 'false') {
        networkService.start();
        logInfo('networkService started');
      }

      _setStatus('正在启动剪贴板监控...');
      if ((await db.getSetting('clipboard_enabled')) != 'false') {
        clipboardService.start();
        logInfo('clipboardService started');
      }

      _setStatus('正在启动应用统计...');
      if ((await db.getSetting('app_usage_enabled')) != 'false') {
        appUsageService.start();
        logInfo('appUsageService started');
      }

      _setStatus('正在启动鼠标监控...');
      if ((await db.getSetting('mouse_listener_enabled')) != 'false') {
        mouseListenerService.start();
        logInfo('mouseListenerService started');
      }

      _setStatus('正在启动按键监听...');
      if ((await db.getSetting('key_listener_enabled')) == 'true') {
        keyListenerService.start();
        logInfo('keyListenerService started');
      }

      _setStatus('正在初始化系统托盘...');
      await trayManager.setIcon(
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
      );
      await trayManager.setToolTip('Super Tool');
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(key: 'show_window', label: '显示窗口'),
            MenuItem.separator(),
            MenuItem(key: 'exit_app', label: '退出程序'),
          ],
        ),
      );
      logInfo('tray initialized');

      _setStatus('启动完成');
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e, st) {
      logError('SplashPage._initialize', e, st);
    }

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      child: Container(
        color: theme.colorScheme.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const Gap(24),
              const Text('Super Tool').h1(),
              const Gap(8),
              Text(
                '一站式桌面工具集',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              const Gap(48),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    backgroundColor: theme.colorScheme.muted.withValues(
                      alpha: 0.3,
                    ),
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Gap(16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _status,
                  key: ValueKey(_status),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
