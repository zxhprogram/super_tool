import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../db/clipboard_model.dart';
import '../db/database_helper.dart';
import '../utils/app_logger.dart';

final clipboardService = ClipboardService();

class ClipboardService {
  Timer? _timer;
  bool _busy = false;
  String _lastHash = '';
  final _controller = StreamController<ClipboardRecord>.broadcast();

  Stream<ClipboardRecord> get newItems => _controller.stream;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    logInfo('ClipboardService started');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      final record = await _readClipboard();
      if (record == null) return;
      if (record.hash == _lastHash) return;
      _lastHash = record.hash;
      if (await DatabaseHelper().clipboardHashExists(record.hash)) return;
      final id = await DatabaseHelper().insertClipboardRecord(record);
      _controller.add(record.copyWith(id: id));
    } catch (e, st) {
      logError('ClipboardService._tick', e, st);
    } finally {
      _busy = false;
    }
  }

  Future<ClipboardRecord?> _readClipboard() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return null;

    final reader = await clipboard.read();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Image (png > jpeg > gif)
    for (final fmt in [Formats.png, Formats.jpeg, Formats.gif]) {
      if (reader.canProvide(fmt)) {
        final bytes = await _readFileFormat(reader, fmt);
        if (bytes == null || bytes.isEmpty) continue;
        final hash = _sha256Bytes(bytes);
        final dir = await _attachmentsDir();
        final ext = fmt == Formats.png
            ? 'png'
            : fmt == Formats.jpeg
                ? 'jpg'
                : 'gif';
        final filePath = p.join(dir, '$hash.$ext');
        if (!File(filePath).existsSync()) {
          File(filePath).writeAsBytesSync(bytes);
        }
        return ClipboardRecord(
          type: 'image',
          content: filePath,
          preview: p.basename(filePath),
          hash: hash,
          createdAt: now,
        );
      }
    }

    // 2. File
    if (reader.canProvide(Formats.fileUri)) {
      final uri = await reader.readValue(Formats.fileUri);
      if (uri != null) {
        final filePath = uri.toFilePath();
        final hash = _sha256String(filePath);
        return ClipboardRecord(
          type: 'file',
          content: filePath,
          preview: p.basename(filePath),
          hash: hash,
          createdAt: now,
        );
      }
    }

    // 3. HTML
    if (reader.canProvide(Formats.htmlText)) {
      final html = await reader.readValue(Formats.htmlText);
      if (html != null && html.isNotEmpty) {
        final hash = _sha256String(html);
        final stripped =
            html.replaceAll(RegExp(r'<[^>]+>'), '').trim();
        final preview =
            stripped.length > 100 ? '${stripped.substring(0, 100)}...' : stripped;
        return ClipboardRecord(
          type: 'html',
          content: html,
          preview: preview,
          hash: hash,
          createdAt: now,
        );
      }
    }

    // 4. Plain text
    if (reader.canProvide(Formats.plainText)) {
      final text = await reader.readValue(Formats.plainText);
      if (text != null && text.isNotEmpty) {
        final hash = _sha256String(text);
        final preview =
            text.length > 100 ? '${text.substring(0, 100)}...' : text;
        return ClipboardRecord(
          type: 'text',
          content: text,
          preview: preview,
          hash: hash,
          createdAt: now,
        );
      }
    }

    return null;
  }

  Future<Uint8List?> _readFileFormat(
      ClipboardReader reader, FileFormat fmt) async {
    final c = Completer<Uint8List?>();
    final progress = reader.getFile(fmt, (file) async {
      try {
        c.complete(await file.readAll());
      } catch (_) {
        c.complete(null);
      }
    });
    if (progress == null) {
      c.complete(null);
    }
    return c.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => null,
    );
  }

  Future<void> restore(ClipboardRecord record) async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return;
    final item = DataWriterItem();
    switch (record.type) {
      case 'text':
        item.add(Formats.plainText(record.content!));
      case 'html':
        item.add(Formats.htmlText(record.content!));
        item.add(Formats.plainText(
            record.content!.replaceAll(RegExp(r'<[^>]+>'), '')));
      case 'image':
        final bytes = File(record.content!).readAsBytesSync();
        final ext = p.extension(record.content!).toLowerCase();
        if (ext == '.jpg' || ext == '.jpeg') {
          item.add(Formats.jpeg(bytes));
        } else {
          item.add(Formats.png(bytes));
        }
      case 'file':
        item.add(Formats.fileUri(Uri.file(record.content!)));
    }
    // Temporarily ignore self-triggered clipboard change
    _lastHash = record.hash;
    await clipboard.write([item]);
  }

  String _sha256Bytes(List<int> bytes) => sha256.convert(bytes).toString();
  String _sha256String(String s) => sha256.convert(utf8.encode(s)).toString();

  String? _attachmentsDirCache;

  Future<String> _attachmentsDir() async {
    if (_attachmentsDirCache != null) return _attachmentsDirCache!;
    final base = await getDatabasesPath();
    final dir = Directory(p.join(base, 'clipboard_attachments'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _attachmentsDirCache = dir.path;
    return dir.path;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
