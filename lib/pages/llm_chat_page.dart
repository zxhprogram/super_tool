import 'dart:async';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../db/database_helper.dart';
import '../db/llm_model.dart';
import '../services/llm_service.dart';

class LlmChatPage extends StatefulWidget {
  const LlmChatPage({super.key});

  @override
  State<LlmChatPage> createState() => _LlmChatPageState();
}

class _LlmChatPageState extends State<LlmChatPage> {
  final _db = DatabaseHelper();
  final _service = LlmService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  List<LlmConfig> _configs = [];
  LlmConfig? _selectedConfig;
  List<String> _models = [];
  String? _selectedModel;
  bool _loadingModels = false;
  String? _modelError;

  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  List<ChatMessage> _messages = [];
  bool _sending = false;
  String _streamingContent = '';
  StreamSubscription<String>? _streamSub;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    final configs = await _db.getLlmConfigs();
    if (!mounted) return;
    setState(() => _configs = configs);
    if (configs.isNotEmpty) {
      await _selectConfig(configs.first);
      await _loadSessions();
    }
  }

  Future<void> _selectConfig(LlmConfig config) async {
    setState(() {
      _selectedConfig = config;
      _models = [];
      _selectedModel = null;
      _modelError = null;
      _loadingModels = true;
    });
    try {
      final models = await _service.fetchModels(
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
      );
      if (!mounted) return;
      setState(() {
        _models = models;
        _selectedModel = models.isNotEmpty ? models.first : null;
        _loadingModels = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _modelError = '获取模型失败';
        _loadingModels = false;
      });
    }
  }

  Future<void> _loadSessions() async {
    final sessions = await _db.getChatSessions();
    if (!mounted) return;
    setState(() => _sessions = sessions);
  }

  Future<void> _selectSession(ChatSession session) async {
    final messages = await _db.getMessages(session.id!);
    if (!mounted) return;
    setState(() {
      _currentSession = session;
      _messages = messages;
      _streamingContent = '';
    });
    _scrollToBottom();
  }

  void _newSession() => setState(() {
        _currentSession = null;
        _messages = [];
        _streamingContent = '';
      });

  Future<void> _deleteSession(ChatSession session) async {
    await _db.deleteChatSession(session.id!);
    if (_currentSession?.id == session.id) {
      setState(() {
        _currentSession = null;
        _messages = [];
      });
    }
    await _loadSessions();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending || _selectedConfig == null || _selectedModel == null) return;
    _inputController.clear();

    final config = _selectedConfig!;
    final modelId = _selectedModel!;
    final now = DateTime.now().millisecondsSinceEpoch;

    ChatSession session;
    if (_currentSession == null) {
      final title = text.length > 20 ? '${text.substring(0, 20)}…' : text;
      final id = await _db.insertChatSession(ChatSession(
        configId: config.id!,
        modelId: modelId,
        title: title,
        createdAt: now,
        updatedAt: now,
      ));
      final sessions = await _db.getChatSessions();
      if (!mounted) return;
      session = sessions.firstWhere((s) => s.id == id);
      setState(() {
        _sessions = sessions;
        _currentSession = session;
      });
    } else {
      session = _currentSession!;
    }

    final userMsg = ChatMessage(
      sessionId: session.id!,
      role: 'user',
      content: text,
      createdAt: now,
    );
    await _db.insertMessage(userMsg);
    setState(() {
      _messages = [..._messages, userMsg];
      _sending = true;
      _streamingContent = '';
    });
    _scrollToBottom();

    final apiMessages = _messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    _streamSub?.cancel();
    _streamSub = _service
        .chatStream(
          baseUrl: config.baseUrl,
          apiKey: config.apiKey,
          modelId: modelId,
          messages: apiMessages,
        )
        .listen(
          (delta) {
            setState(() => _streamingContent += delta);
            _scrollToBottom();
          },
          onDone: () async {
            final content = _streamingContent;
            final doneAt = DateTime.now().millisecondsSinceEpoch;
            final assistantMsg = ChatMessage(
              sessionId: session.id!,
              role: 'assistant',
              content: content,
              createdAt: doneAt,
            );
            await _db.insertMessage(assistantMsg);
            await _db.touchChatSession(session.id!, doneAt);
            if (!mounted) return;
            setState(() {
              _messages = [..._messages, assistantMsg];
              _sending = false;
              _streamingContent = '';
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _sending = false;
              _streamingContent = '';
            });
          },
          cancelOnError: true,
        );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _ConfigDialog(
        db: _db,
        service: _service,
        configs: _configs,
        onSaved: () {
          Navigator.pop(ctx);
          _loadConfigs();
        },
        onDeleted: () {
          Navigator.pop(ctx);
          _loadConfigs();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                  right: BorderSide(color: theme.colorScheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: PrimaryButton(
                    onPressed: _newSession,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16),
                        Gap(6),
                        Text('新建对话'),
                      ],
                    ),
                  ),
                ),
                Divider(color: theme.colorScheme.border),
                Expanded(
                  child: _sessions.isEmpty
                      ? Center(
                          child: Text(
                            '暂无对话',
                            style: TextStyle(
                              color: theme.colorScheme.mutedForeground,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _sessions.length,
                          itemBuilder: (ctx, i) {
                            final s = _sessions[i];
                            final selected = _currentSession?.id == s.id;
                            return GestureDetector(
                              onTap: () => _selectSession(s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                color: selected
                                    ? theme.colorScheme.accent
                                    : Colors.transparent,
                                child: Row(
                                  children: [
                                    Icon(Icons.chat_bubble_outline,
                                        size: 14,
                                        color:
                                            theme.colorScheme.mutedForeground),
                                    const Gap(8),
                                    Expanded(
                                      child: Text(
                                        s.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _deleteSession(s),
                                      child: Icon(Icons.close,
                                          size: 14,
                                          color: theme
                                              .colorScheme.mutedForeground),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Divider(color: theme.colorScheme.border),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlineButton(
                    onPressed: _showConfigDialog,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings, size: 16),
                        Gap(6),
                        Text('管理 API'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _configs.isEmpty ? _buildNoConfig() : _buildChat(theme),
        ),
      ],
    );
  }

  Widget _buildNoConfig() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.api, size: 64),
          const Gap(16),
          const Text('还没有 API 配置').h2(),
          const Gap(8),
          const Text('请先添加一个 OpenAI 兼容 API').muted(),
          const Gap(24),
          PrimaryButton(
            onPressed: _showConfigDialog,
            child: const Text('添加 API 配置'),
          ),
        ],
      ),
    );
  }

  Widget _buildChat(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: theme.colorScheme.border)),
          ),
          child: Row(
            children: [
              if (_configs.length > 1) ...[
                SizedBox(
                  width: 150,
                  child: Select<LlmConfig>(
                    value: _selectedConfig,
                    onChanged: (v) {
                      if (v != null) _selectConfig(v);
                    },
                    itemBuilder: (ctx, item) => Text(item.name),
                    popup: SelectPopup(
                      items: SelectItemList(
                        children: _configs
                            .map((c) => SelectItemButton(
                                  value: c,
                                  child: Text(c.name),
                                ))
                            .toList(),
                      ),
                    ).call,
                  ),
                ),
                const Gap(8),
              ],
              if (_loadingModels)
                Text(
                  '获取模型中…',
                  style: TextStyle(
                      color: theme.colorScheme.mutedForeground, fontSize: 12),
                )
              else if (_modelError != null)
                Text(
                  _modelError!,
                  style: TextStyle(
                      color: theme.colorScheme.destructive, fontSize: 12),
                )
              else if (_models.isNotEmpty)
                SizedBox(
                  width: 220,
                  child: Select<String>(
                    value: _selectedModel,
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedModel = v);
                    },
                    itemBuilder: (ctx, item) =>
                        Text(item, overflow: TextOverflow.ellipsis),
                    popup: SelectPopup(
                      items: SelectItemList(
                        children: _models
                            .map((m) => SelectItemButton(
                                  value: m,
                                  child: Text(m,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                      ),
                    ).call,
                  ),
                ),
              const Spacer(),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty && _streamingContent.isEmpty
              ? Center(
                  child: Text(
                    '发送消息开始对话',
                    style: TextStyle(
                        color: theme.colorScheme.mutedForeground),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length +
                      (_streamingContent.isNotEmpty ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i < _messages.length) {
                      return _MessageBubble(message: _messages[i]);
                    }
                    return _MessageBubble(
                      message: ChatMessage(
                        sessionId: _currentSession?.id ?? 0,
                        role: 'assistant',
                        content: _streamingContent,
                        createdAt: 0,
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border:
                Border(top: BorderSide(color: theme.colorScheme.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  placeholder: const Text('发送消息… (Enter 发送)'),
                  onSubmitted: (_) => _send(),
                  maxLines: 6,
                  minLines: 1,
                ),
              ),
              const Gap(8),
              PrimaryButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const Icon(Icons.more_horiz, size: 18)
                    : const Icon(Icons.send, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == 'user';

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  message.content,
                  style:
                      TextStyle(color: theme.colorScheme.primaryForeground),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.smart_toy_outlined,
              size: 20, color: theme.colorScheme.primary),
          const Gap(8),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: message.content.isEmpty
                    ? Text('…',
                        style: TextStyle(
                            color: theme.colorScheme.mutedForeground))
                    : MarkdownBody(data: message.content),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigDialog extends StatefulWidget {
  final DatabaseHelper db;
  final LlmService service;
  final List<LlmConfig> configs;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;

  const _ConfigDialog({
    required this.db,
    required this.service,
    required this.configs,
    required this.onSaved,
    required this.onDeleted,
  });

  @override
  State<_ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<_ConfigDialog> {
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool _testing = false;
  String? _testError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _testAndSave() async {
    final name = _nameCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    if (name.isEmpty || url.isEmpty || key.isEmpty) return;

    setState(() {
      _testing = true;
      _testError = null;
    });
    try {
      await widget.service.fetchModels(baseUrl: url, apiKey: key);
      await widget.db.insertLlmConfig(LlmConfig(
        name: name,
        baseUrl: url,
        apiKey: key,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testError = '连接失败：${e.toString().split('\n').first}';
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('管理 API 配置').h2(),
                const Gap(16),
                if (widget.configs.isNotEmpty) ...[
                  const Text('已有配置').semiBold(),
                  const Gap(8),
                  ...widget.configs.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(c.name).semiBold()),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              c.baseUrl,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.mutedForeground),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          DestructiveButton(
                            onPressed: () async {
                              await widget.db.deleteLlmConfig(c.id!);
                              widget.onDeleted();
                            },
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(8),
                  const Divider(),
                  const Gap(16),
                ],
                const Text('添加新配置').semiBold(),
                const Gap(8),
                TextField(
                  controller: _nameCtrl,
                  placeholder: const Text('名称（如 OpenAI）'),
                ),
                const Gap(8),
                TextField(
                  controller: _urlCtrl,
                  placeholder:
                      const Text('Base URL（如 https://api.openai.com）'),
                ),
                const Gap(8),
                TextField(
                  controller: _keyCtrl,
                  placeholder: const Text('API Key'),
                ),
                if (_testError != null) ...[
                  const Gap(8),
                  Text(
                    _testError!,
                    style: TextStyle(
                        color: theme.colorScheme.destructive, fontSize: 12),
                  ),
                ],
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlineButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const Gap(8),
                    PrimaryButton(
                      onPressed: _testing ? null : _testAndSave,
                      child: Text(_testing ? '测试中…' : '测试并保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
