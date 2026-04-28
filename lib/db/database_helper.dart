import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app_usage_model.dart';
import 'bookmark_model.dart';
import 'clipboard_model.dart';
import 'key_model.dart';
import 'llm_model.dart';
import 'mouse_model.dart';
import 'network_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/super_tool.db';
    return openDatabase(
      path,
      version: 9,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bookmark_groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            sort_order INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            url TEXT NOT NULL,
            icon_url TEXT,
            sort_order INTEGER DEFAULT 0,
            FOREIGN KEY (group_id) REFERENCES bookmark_groups(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE network_minute_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            minute_ts INTEGER NOT NULL UNIQUE,
            bytes_sent INTEGER NOT NULL DEFAULT 0,
            bytes_recv INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE key_minute_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            minute_ts INTEGER NOT NULL UNIQUE,
            key_count INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE clipboard_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            content TEXT,
            preview TEXT,
            hash TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_clipboard_hash ON clipboard_history(hash)');
        await db.execute(
            'CREATE INDEX idx_clipboard_created ON clipboard_history(created_at)');
        await db.execute('''
          CREATE TABLE app_usage_minutes (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            process_name TEXT    NOT NULL,
            minute_ts    INTEGER NOT NULL,
            seconds      INTEGER NOT NULL DEFAULT 0,
            UNIQUE(process_name, minute_ts)
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_app_usage_process ON app_usage_minutes(process_name)');
        await db.execute(
            'CREATE INDEX idx_app_usage_minute ON app_usage_minutes(minute_ts)');
        await db.execute('''
          CREATE TABLE llm_configs (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            name       TEXT    NOT NULL,
            base_url   TEXT    NOT NULL,
            api_key    TEXT    NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE chat_sessions (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            config_id  INTEGER NOT NULL,
            model_id   TEXT    NOT NULL,
            title      TEXT    NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (config_id) REFERENCES llm_configs(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE chat_messages (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            role       TEXT    NOT NULL,
            content    TEXT    NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE mouse_minute_stats (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            minute_ts   INTEGER NOT NULL UNIQUE,
            click_count INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE key_press_counts (
            key_name  TEXT    NOT NULL,
            minute_ts INTEGER NOT NULL,
            count     INTEGER NOT NULL DEFAULT 1,
            PRIMARY KEY (key_name, minute_ts)
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_kpc_minute ON key_press_counts(minute_ts)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS network_minute_stats (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              minute_ts INTEGER NOT NULL UNIQUE,
              bytes_sent INTEGER NOT NULL DEFAULT 0,
              bytes_recv INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS key_minute_stats (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              minute_ts INTEGER NOT NULL UNIQUE,
              key_count INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS clipboard_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type TEXT NOT NULL,
              content TEXT,
              preview TEXT,
              hash TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_clipboard_hash ON clipboard_history(hash)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_clipboard_created ON clipboard_history(created_at)');
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_usage_minutes (
              id           INTEGER PRIMARY KEY AUTOINCREMENT,
              process_name TEXT    NOT NULL,
              minute_ts    INTEGER NOT NULL,
              seconds      INTEGER NOT NULL DEFAULT 0,
              UNIQUE(process_name, minute_ts)
            )
          ''');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_app_usage_process ON app_usage_minutes(process_name)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_app_usage_minute ON app_usage_minutes(minute_ts)');
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS llm_configs (
              id         INTEGER PRIMARY KEY AUTOINCREMENT,
              name       TEXT    NOT NULL,
              base_url   TEXT    NOT NULL,
              api_key    TEXT    NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS chat_sessions (
              id         INTEGER PRIMARY KEY AUTOINCREMENT,
              config_id  INTEGER NOT NULL,
              model_id   TEXT    NOT NULL,
              title      TEXT    NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              FOREIGN KEY (config_id) REFERENCES llm_configs(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS chat_messages (
              id         INTEGER PRIMARY KEY AUTOINCREMENT,
              session_id INTEGER NOT NULL,
              role       TEXT    NOT NULL,
              content    TEXT    NOT NULL,
              created_at INTEGER NOT NULL,
              FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS mouse_minute_stats (
              id          INTEGER PRIMARY KEY AUTOINCREMENT,
              minute_ts   INTEGER NOT NULL UNIQUE,
              click_count INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS key_press_counts (
              key_name  TEXT    NOT NULL,
              minute_ts INTEGER NOT NULL,
              count     INTEGER NOT NULL DEFAULT 1,
              PRIMARY KEY (key_name, minute_ts)
            )
          ''');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_kpc_minute ON key_press_counts(minute_ts)');
        }
      },
    );
  }

  // --- Settings ---

  Future<String?> getSetting(String key) async {
    final d = await db;
    final rows =
        await d.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final d = await db;
    await d.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Bookmarks ---

  Future<List<BookmarkGroup>> getGroups() async {
    final d = await db;
    final rows = await d.query('bookmark_groups', orderBy: 'sort_order, id');
    return rows.map(BookmarkGroup.fromMap).toList();
  }

  Future<int> insertGroup(BookmarkGroup group) async {
    final d = await db;
    return d.insert('bookmark_groups', group.toMap()..remove('id'));
  }

  Future<void> deleteGroup(int id) async {
    final d = await db;
    await d.delete('bookmarks', where: 'group_id = ?', whereArgs: [id]);
    await d.delete('bookmark_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Bookmark>> getBookmarksByGroup(int groupId) async {
    final d = await db;
    final rows = await d.query('bookmarks',
        where: 'group_id = ?', whereArgs: [groupId], orderBy: 'sort_order, id');
    return rows.map(Bookmark.fromMap).toList();
  }

  Future<int> insertBookmark(Bookmark bookmark) async {
    final d = await db;
    return d.insert('bookmarks', bookmark.toMap()..remove('id'));
  }

  Future<void> updateBookmark(Bookmark bookmark) async {
    final d = await db;
    await d.update('bookmarks', bookmark.toMap(),
        where: 'id = ?', whereArgs: [bookmark.id]);
  }

  Future<void> deleteBookmark(int id) async {
    final d = await db;
    await d.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateBookmarkOrders(List<Bookmark> bookmarks) async {
    final d = await db;
    final batch = d.batch();
    for (int i = 0; i < bookmarks.length; i++) {
      batch.update(
        'bookmarks',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [bookmarks[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // --- Network stats ---

  Future<void> insertNetMinuteStat({
    required int minuteTs,
    required int bytesSent,
    required int bytesRecv,
  }) async {
    final d = await db;
    await d.insert(
      'network_minute_stats',
      {
        'minute_ts': minuteTs,
        'bytes_sent': bytesSent,
        'bytes_recv': bytesRecv,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NetworkMinuteStat>> getRecentNetStats({int limit = 30}) async {
    final d = await db;
    final rows = await d.query(
      'network_minute_stats',
      orderBy: 'minute_ts DESC',
      limit: limit,
    );
    return rows.map(NetworkMinuteStat.fromMap).toList();
  }

  Future<List<NetworkMinuteStat>> getNetStatsByDate(DateTime date) async {
    final startTs =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
            1000;
    final endTs = startTs + 86400;
    final d = await db;
    final rows = await d.query(
      'network_minute_stats',
      where: 'minute_ts >= ? AND minute_ts < ?',
      whereArgs: [startTs, endTs],
      orderBy: 'minute_ts ASC',
    );
    return rows.map(NetworkMinuteStat.fromMap).toList();
  }

  Future<List<NetworkMinuteStat>> getAllNetStats() async {
    final d = await db;
    final rows = await d.query('network_minute_stats', orderBy: 'minute_ts ASC');
    return rows.map(NetworkMinuteStat.fromMap).toList();
  }

  // --- Key stats ---

  Future<void> insertKeyMinuteStat({
    required int minuteTs,
    required int keyCount,
  }) async {
    final d = await db;
    await d.insert(
      'key_minute_stats',
      {'minute_ts': minuteTs, 'key_count': keyCount},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<KeyMinuteStat>> getRecentKeyStats({int limit = 30}) async {
    final d = await db;
    final rows = await d.query(
      'key_minute_stats',
      orderBy: 'minute_ts DESC',
      limit: limit,
    );
    return rows.map(KeyMinuteStat.fromMap).toList();
  }

  Future<List<KeyMinuteStat>> getKeyStatsByDate(DateTime date) async {
    final startTs =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
            1000;
    final endTs = startTs + 86400;
    final d = await db;
    final rows = await d.query(
      'key_minute_stats',
      where: 'minute_ts >= ? AND minute_ts < ?',
      whereArgs: [startTs, endTs],
      orderBy: 'minute_ts ASC',
    );
    return rows.map(KeyMinuteStat.fromMap).toList();
  }

  Future<void> insertKeyPressCounts(
      int minuteTs, Map<String, int> counts) async {
    final d = await db;
    final batch = d.batch();
    counts.forEach((keyName, count) {
      batch.rawInsert(
        'INSERT INTO key_press_counts (key_name, minute_ts, count) VALUES (?, ?, ?) '
        'ON CONFLICT(key_name, minute_ts) DO UPDATE SET count = count + excluded.count',
        [keyName, minuteTs, count],
      );
    });
    await batch.commit(noResult: true);
  }

  Future<Map<String, int>> getKeyCountsByDate(DateTime date) async {
    final startTs =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
            1000;
    final endTs = startTs + 86400;
    final d = await db;
    final rows = await d.rawQuery(
      'SELECT key_name, SUM(count) as total FROM key_press_counts '
      'WHERE minute_ts >= ? AND minute_ts < ? GROUP BY key_name',
      [startTs, endTs],
    );
    return {
      for (final r in rows)
        r['key_name'] as String: (r['total'] as int? ?? 0)
    };
  }

  // --- Clipboard history ---

  Future<bool> clipboardHashExists(String hash) async {
    final d = await db;
    final rows = await d.query('clipboard_history',
        where: 'hash = ?', whereArgs: [hash], limit: 1);
    return rows.isNotEmpty;
  }

  Future<int> insertClipboardRecord(ClipboardRecord r) async {
    final d = await db;
    return d.insert('clipboard_history', r.toMap()..remove('id'));
  }

  Future<List<ClipboardRecord>> getClipboardRecords({
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final d = await db;
    final rows = await d.query(
      'clipboard_history',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type] : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(ClipboardRecord.fromMap).toList();
  }

  Future<void> deleteClipboardRecord(int id) async {
    final d = await db;
    await d.delete('clipboard_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearClipboardHistory() async {
    final d = await db;
    await d.delete('clipboard_history');
  }

  // --- App usage ---

  Future<void> addAppUsageSeconds({
    required String processName,
    required int minuteTs,
    required int seconds,
  }) async {
    final d = await db;
    await d.rawInsert('''
      INSERT INTO app_usage_minutes (process_name, minute_ts, seconds)
      VALUES (?, ?, ?)
      ON CONFLICT(process_name, minute_ts)
      DO UPDATE SET seconds = seconds + excluded.seconds
    ''', [processName, minuteTs, seconds]);
  }

  Future<List<AppUsageSummary>> getAppUsageSummary() async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT process_name, SUM(seconds) as total_seconds
      FROM app_usage_minutes
      GROUP BY process_name
      ORDER BY total_seconds DESC
    ''');
    return rows.map(AppUsageSummary.fromMap).toList();
  }

  Future<List<AppUsageMinute>> getAppUsageByProcess({
    required String processName,
    required int sinceTs,
  }) async {
    final d = await db;
    final rows = await d.query(
      'app_usage_minutes',
      where: 'process_name = ? AND minute_ts >= ?',
      whereArgs: [processName, sinceTs],
      orderBy: 'minute_ts ASC',
    );
    return rows.map(AppUsageMinute.fromMap).toList();
  }

  // --- LLM configs ---

  Future<List<LlmConfig>> getLlmConfigs() async {
    final d = await db;
    final rows = await d.query('llm_configs', orderBy: 'created_at ASC');
    return rows.map(LlmConfig.fromMap).toList();
  }

  Future<int> insertLlmConfig(LlmConfig c) async {
    final d = await db;
    return d.insert('llm_configs', c.toMap()..remove('id'));
  }

  Future<void> deleteLlmConfig(int id) async {
    final d = await db;
    await d.delete('llm_configs', where: 'id = ?', whereArgs: [id]);
  }

  // --- Chat sessions ---

  Future<List<ChatSession>> getChatSessions() async {
    final d = await db;
    final rows =
        await d.query('chat_sessions', orderBy: 'updated_at DESC');
    return rows.map(ChatSession.fromMap).toList();
  }

  Future<int> insertChatSession(ChatSession s) async {
    final d = await db;
    return d.insert('chat_sessions', s.toMap()..remove('id'));
  }

  Future<void> updateChatSessionTitle(int id, String title) async {
    final d = await db;
    await d.update('chat_sessions', {'title': title},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> touchChatSession(int id, int updatedAt) async {
    final d = await db;
    await d.update('chat_sessions', {'updated_at': updatedAt},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteChatSession(int id) async {
    final d = await db;
    await d.delete('chat_messages', where: 'session_id = ?', whereArgs: [id]);
    await d.delete('chat_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Chat messages ---

  Future<List<ChatMessage>> getMessages(int sessionId) async {
    final d = await db;
    final rows = await d.query('chat_messages',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'created_at ASC');
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<int> insertMessage(ChatMessage m) async {
    final d = await db;
    return d.insert('chat_messages', m.toMap()..remove('id'));
  }

  // --- Mouse stats ---

  Future<void> insertMouseMinuteStat({
    required int minuteTs,
    required int clickCount,
  }) async {
    final d = await db;
    await d.insert(
      'mouse_minute_stats',
      {'minute_ts': minuteTs, 'click_count': clickCount},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MouseMinuteStat>> getRecentMouseStats({int limit = 30}) async {
    final d = await db;
    final rows = await d.query(
      'mouse_minute_stats',
      orderBy: 'minute_ts DESC',
      limit: limit,
    );
    return rows.map(MouseMinuteStat.fromMap).toList();
  }
}
