import 'dart:async';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../ffi/key_listener_service.dart';

class KeyListenerPage extends StatefulWidget {
  const KeyListenerPage({super.key});

  @override
  State<KeyListenerPage> createState() => _KeyListenerPageState();
}

class _KeyListenerPageState extends State<KeyListenerPage> {
  late final KeyListenerService _service;
  StreamSubscription<String>? _subscription;

  String _currentKey = '';
  final List<String> _history = [];
  static const int _maxHistory = 50;

  @override
  void initState() {
    super.initState();
    _service = KeyListenerService();
    _subscription = _service.keyEvents.listen((event) {
      setState(() {
        _history.insert(0, event);
        final parts = event.split(':');
        if (parts.length >= 2) {
          _currentKey = parts.sublist(1).join(':');
        }
        if (_history.length > _maxHistory) {
          _history.removeRange(_maxHistory, _history.length);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('按键监听').h2(),
          const Gap(8),
          Text(
            '全局键盘事件监听，按键释放时记录',
            style: TextStyle(color: theme.colorScheme.mutedForeground),
          ),
          const Gap(24),
          Card(
            child: SizedBox(
              width: double.infinity,
              height: 140,
              child: Center(
                child: Text(
                  _currentKey.isEmpty ? '等待按键...' : _currentKey,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _currentKey.isEmpty
                        ? theme.colorScheme.mutedForeground
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const Gap(16),
          Row(
            children: [
              PrimaryButton(
                onPressed: _service.isListening
                    ? null
                    : () {
                        _service.start();
                        setState(() {});
                      },
                leading: const Icon(Icons.play_arrow),
                child: const Text('开始监听'),
              ),
              const Gap(8),
              SecondaryButton(
                onPressed: _service.isListening
                    ? () {
                        _service.stop();
                        setState(() {});
                      }
                    : null,
                leading: const Icon(Icons.stop),
                child: const Text('停止监听'),
              ),
              const Gap(8),
              DestructiveButton(
                onPressed: _history.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _history.clear();
                          _currentKey = '';
                        });
                      },
                leading: const Icon(Icons.clear_all),
                child: const Text('清空'),
              ),
            ],
          ),
          const Gap(24),
          const Text('按键历史').semiBold(),
          const Gap(8),
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Text(
                      '暂无记录',
                      style: TextStyle(
                          color: theme.colorScheme.mutedForeground),
                    ),
                  )
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final event = _history[index];
                      final parts = event.split(':');
                      final key =
                          parts.length >= 2 ? parts.sublist(1).join(':') : '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up,
                              size: 16,
                              color: theme.colorScheme.mutedForeground,
                            ),
                            const Gap(8),
                            Text(
                              key,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
