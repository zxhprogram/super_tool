import 'dart:convert';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';

enum FormatType { json, yaml }

class FormatterPage extends StatefulWidget {
  const FormatterPage({super.key});

  @override
  State<FormatterPage> createState() => _FormatterPageState();
}

class _FormatterPageState extends State<FormatterPage> {
  final CodeLineEditingController _controller = CodeLineEditingController();
  FormatType _formatType = FormatType.json;
  String? _error;

  CodeHighlightTheme get _highlightTheme => CodeHighlightTheme(
        languages: {
          'json': CodeHighlightThemeMode(mode: langJson),
          'yaml': CodeHighlightThemeMode(mode: langYaml),
        },
        theme: atomOneDarkTheme,
      );

  void _format() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    setState(() => _error = null);

    try {
      if (_formatType == FormatType.json) {
        final decoded = jsonDecode(text);
        final formatted =
            const JsonEncoder.withIndent('  ').convert(decoded);
        _controller.text = formatted;
      } else {
        _controller.text = _formatYaml(text);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  String _formatYaml(String input) {
    final lines = input.split('\n');
    final buffer = StringBuffer();
    for (final line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.isNotEmpty) {
        buffer.writeln(trimmed);
      } else {
        buffer.writeln();
      }
    }
    return buffer.toString().trimRight();
  }

  void _clear() {
    _controller.text = '';
    setState(() => _error = null);
  }

  @override
  void dispose() {
    _controller.dispose();
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('配置格式化').h2(),
                    const Gap(4),
                    Text(
                      '粘贴 JSON 或 YAML 内容，一键格式化提升可读性',
                      style: TextStyle(
                          color: theme.colorScheme.mutedForeground),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Toggle(
                    value: _formatType == FormatType.json,
                    onChanged: (v) {
                      if (v) setState(() => _formatType = FormatType.json);
                    },
                    child: const Text('JSON'),
                  ),
                  const Gap(4),
                  Toggle(
                    value: _formatType == FormatType.yaml,
                    onChanged: (v) {
                      if (v) setState(() => _formatType = FormatType.yaml);
                    },
                    child: const Text('YAML'),
                  ),
                ],
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              PrimaryButton(
                onPressed: _format,
                leading: const Icon(Icons.auto_fix_high),
                child: const Text('格式化'),
              ),
              const Gap(8),
              SecondaryButton(
                onPressed: _clear,
                leading: const Icon(Icons.clear_all),
                child: const Text('清空'),
              ),
            ],
          ),
          if (_error != null) ...[
            const Gap(8),
            Text(
              _error!,
              style: TextStyle(
                color: theme.colorScheme.destructive,
                fontSize: 12,
              ),
            ),
          ],
          const Gap(16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CodeEditor(
                controller: _controller,
                wordWrap: true,
                style: CodeEditorStyle(
                  fontSize: 14,
                  codeTheme: _highlightTheme,
                ),
                indicatorBuilder:
                    (context, editingController, chunkController, notifier) {
                  return Row(
                    children: [
                      DefaultCodeLineNumber(
                        controller: editingController,
                        notifier: notifier,
                      ),
                      DefaultCodeChunkIndicator(
                        width: 20,
                        controller: chunkController,
                        notifier: notifier,
                      ),
                    ],
                  );
                },
                sperator: Container(width: 1, color: theme.colorScheme.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
