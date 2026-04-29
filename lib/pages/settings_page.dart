import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../app_usage/app_usage_service.dart';
import '../clipboard/clipboard_service.dart';
import '../db/database_helper.dart';
import '../ffi/key_listener_service.dart';
import '../ffi/mouse_listener_service.dart';
import '../ffi/network_service.dart';
import '../widgets/page_wrapper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _keyListener = false;
  bool _mouseListener = false;
  bool _network = false;
  bool _clipboard = false;
  bool _appUsage = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = DatabaseHelper();
    final vals = await Future.wait([
      db.getSetting('key_listener_enabled'),
      db.getSetting('mouse_listener_enabled'),
      db.getSetting('network_enabled'),
      db.getSetting('clipboard_enabled'),
      db.getSetting('app_usage_enabled'),
    ]);
    if (mounted) {
      setState(() {
        _keyListener = vals[0] == 'true';
        _mouseListener = vals[1] != 'false';
        _network = vals[2] != 'false';
        _clipboard = vals[3] != 'false';
        _appUsage = vals[4] != 'false';
        _loading = false;
      });
    }
  }

  Future<void> _toggle(
    String key,
    bool value,
    void Function(bool) setter,
    VoidCallback? onStart,
    VoidCallback? onStop,
  ) async {
    setState(() => setter(value));
    await DatabaseHelper().setSetting(key, value ? 'true' : 'false');
    if (value) {
      onStart?.call();
    } else {
      onStop?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return PageWrapper(
      title: '应用设置',
      subtitle: '控制应用启动时自动开启的功能，更改后立即生效',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingSwitch(
            icon: Icons.keyboard,
            title: '键盘监听',
            subtitle: '全局键盘事件监听与统计',
            value: _keyListener,
            onChanged: (v) => _toggle(
              'key_listener_enabled',
              v,
              (val) => _keyListener = val,
              () => keyListenerService.start(),
              () => keyListenerService.stop(),
            ),
          ),
          _SettingSwitch(
            icon: Icons.mouse,
            title: '鼠标监听',
            subtitle: '全局鼠标点击事件监听与统计',
            value: _mouseListener,
            onChanged: (v) => _toggle(
              'mouse_listener_enabled',
              v,
              (val) => _mouseListener = val,
              () => mouseListenerService.start(),
              () => mouseListenerService.stop(),
            ),
          ),
          _SettingSwitch(
            icon: Icons.network_check,
            title: '流量监控',
            subtitle: '实时网速与流量统计',
            value: _network,
            onChanged: (v) => _toggle(
              'network_enabled',
              v,
              (val) => _network = val,
              () => networkService.start(),
              () => networkService.stop(),
            ),
          ),
          _SettingSwitch(
            icon: Icons.content_paste,
            title: '剪贴板监听',
            subtitle: '自动记录剪贴板内容',
            value: _clipboard,
            onChanged: (v) => _toggle(
              'clipboard_enabled',
              v,
              (val) => _clipboard = val,
              () => clipboardService.start(),
              () => clipboardService.stop(),
            ),
          ),
          _SettingSwitch(
            icon: Icons.bar_chart,
            title: '应用使用统计',
            subtitle: '追踪前台应用使用时长',
            value: _appUsage,
            onChanged: (v) => _toggle(
              'app_usage_enabled',
              v,
              (val) => _appUsage = val,
              () => appUsageService.start(),
              () => appUsageService.stop(),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      surfaceBlur: 6,
      surfaceOpacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
