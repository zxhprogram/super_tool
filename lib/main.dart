import 'dart:async';

import 'package:flutter/material.dart';

import 'ffi/key_listener_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '全局按键监听',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const KeyListenerPage(),
    );
  }
}

class KeyListenerPage extends StatefulWidget {
  const KeyListenerPage({super.key});

  @override
  State<KeyListenerPage> createState() => _KeyListenerPageState();
}

class _KeyListenerPageState extends State<KeyListenerPage> {
  late final KeyListenerService _service;
  StreamSubscription<String>? _subscription;

  String _currentKey = '';
  String _currentAction = '';
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
          _currentAction = parts[0];
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
    final isDown = _currentAction == 'down';

    return Scaffold(
      appBar: AppBar(
        title: const Text('全局按键监听'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            color: _currentKey.isEmpty
                ? null
                : (isDown ? Colors.green.shade50 : Colors.grey.shade100),
            child: SizedBox(
              width: double.infinity,
              height: 160,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentKey.isEmpty ? '等待按键...' : _currentKey,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _currentKey.isEmpty
                          ? Colors.grey
                          : (isDown
                              ? Colors.green.shade700
                              : Colors.grey.shade600),
                    ),
                  ),
                  if (_currentKey.isNotEmpty)
                    Text(
                      isDown ? '按下' : '释放',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDown ? Colors.green : Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _service.isListening
                    ? null
                    : () {
                        _service.start();
                        setState(() {});
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始监听'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _service.isListening
                    ? () {
                        _service.stop();
                        setState(() {});
                      }
                    : null,
                icon: const Icon(Icons.stop),
                label: const Text('停止监听'),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: _history.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _history.clear();
                          _currentKey = '';
                          _currentAction = '';
                        });
                      },
                icon: const Icon(Icons.clear_all),
                label: const Text('清空'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('按键历史',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          const Divider(indent: 32, endIndent: 32),
          Expanded(
            child: _history.isEmpty
                ? const Center(
                    child:
                        Text('暂无记录', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final event = _history[index];
                      final parts = event.split(':');
                      final action = parts[0];
                      final key = parts.length >= 2
                          ? parts.sublist(1).join(':')
                          : '';
                      final isKeyDown = action == 'down';
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isKeyDown
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: isKeyDown ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        title: Text(key,
                            style: const TextStyle(fontFamily: 'monospace')),
                        trailing: Text(
                          isKeyDown ? '按下' : '释放',
                          style: TextStyle(
                            fontSize: 12,
                            color: isKeyDown ? Colors.green : Colors.grey,
                          ),
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
