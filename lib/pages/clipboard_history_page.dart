import 'dart:async';
import 'dart:io';

import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../widgets/page_wrapper.dart';

import '../clipboard/clipboard_service.dart';
import '../db/clipboard_model.dart';
import '../db/database_helper.dart';

class ClipboardHistoryPage extends StatefulWidget {
  const ClipboardHistoryPage({super.key});

  @override
  State<ClipboardHistoryPage> createState() => _ClipboardHistoryPageState();
}

class _ClipboardHistoryPageState extends State<ClipboardHistoryPage> {
  List<ClipboardRecord> _records = [];
  String? _filterType;
  bool _loading = true;
  StreamSubscription<ClipboardRecord>? _sub;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _sub = clipboardService.newItems.listen((_) => _loadRecords());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final records =
        await DatabaseHelper().getClipboardRecords(type: _filterType);
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
      });
    }
  }

  void _setFilter(String? type) {
    setState(() {
      _filterType = type;
      _loading = true;
    });
    _loadRecords();
  }

  Future<void> _restore(ClipboardRecord record) async {
    await clipboardService.restore(record);
  }

  Future<void> _delete(ClipboardRecord record) async {
    if (record.id != null) {
      await DatabaseHelper().deleteClipboardRecord(record.id!);
      // Delete attachment if image
      if (record.type == 'image' && record.content != null) {
        final file = File(record.content!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
      _loadRecords();
    }
  }

  Future<void> _clearAll() async {
    await DatabaseHelper().clearClipboardHistory();
    _loadRecords();
  }

  String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${dt.month}-${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageWrapper(
      title: '剪贴板历史',
      breadcrumbLabel: '工具',
      trailing: OutlineButton(
        onPressed: _clearAll,
        density: ButtonDensity.compact,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, size: 16),
            Gap(4),
            Text('清空'),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(12),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: '全部',
                selected: _filterType == null,
                onTap: () => _setFilter(null),
              ),
              _FilterChip(
                label: '文本',
                selected: _filterType == 'text',
                onTap: () => _setFilter('text'),
              ),
              _FilterChip(
                label: 'HTML',
                selected: _filterType == 'html',
                onTap: () => _setFilter('html'),
              ),
              _FilterChip(
                label: '图片',
                selected: _filterType == 'image',
                onTap: () => _setFilter('image'),
              ),
              _FilterChip(
                label: '文件',
                selected: _filterType == 'file',
                onTap: () => _setFilter('file'),
              ),
            ],
          ),
          const Gap(16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? Center(
                        child: Text(
                          '暂无剪贴板记录',
                          style: TextStyle(
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _records.length,
                        separatorBuilder: (context, index) => const Gap(8),
                        itemBuilder: (context, index) {
                          final record = _records[index];
                          return _ClipboardCard(
                            record: record,
                            formattedTime: _formatTime(record.createdAt),
                            onRestore: () => _restore(record),
                            onDelete: () => _delete(record),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return selected
        ? PrimaryButton(
            onPressed: onTap,
            density: ButtonDensity.compact,
            child: Text(label),
          )
        : SecondaryButton(
            onPressed: onTap,
            density: ButtonDensity.compact,
            child: Text(label),
          );
  }
}

class _ClipboardCard extends StatelessWidget {
  final ClipboardRecord record;
  final String formattedTime;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _ClipboardCard({
    required this.record,
    required this.formattedTime,
    required this.onRestore,
    required this.onDelete,
  });

  IconData get _typeIcon => switch (record.type) {
        'text' => Icons.text_fields,
        'html' => Icons.code,
        'image' => Icons.image,
        'file' => Icons.insert_drive_file,
        _ => Icons.content_paste,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _typeIcon,
              size: 24,
              color: theme.colorScheme.mutedForeground,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.type == 'image' && record.content != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(record.content!),
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          '图片加载失败',
                          style: TextStyle(
                            color: theme.colorScheme.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  if (record.type == 'image') const Gap(4),
                  Text(
                    record.preview ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlineButton(
                  onPressed: onRestore,
                  density: ButtonDensity.compact,
                  size: ButtonSize.small,
                  child:
                      const Icon(Icons.content_paste, size: 14),
                ),
                const Gap(4),
                OutlineButton(
                  onPressed: onDelete,
                  density: ButtonDensity.compact,
                  size: ButtonSize.small,
                  child:
                      const Icon(Icons.delete_outline, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
