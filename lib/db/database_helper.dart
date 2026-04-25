import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'bookmark_model.dart';

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
      version: 1,
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
}
