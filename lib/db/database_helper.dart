import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'bookmark_model.dart';
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
      version: 2,
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
      },
    );
  }

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
}
