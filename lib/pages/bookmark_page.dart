import 'dart:async';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sortable_wrap/flutter_sortable_wrap.dart';
import '../db/database_helper.dart';
import '../db/bookmark_model.dart';
import 'bookmark_dialogs.dart';

const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

const _engines = {
  'Google': 'https://www.google.com/search?q=',
  'Bing': 'https://www.bing.com/search?q=',
  'Github': 'https://github.com/search?q=',
};

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final _db = DatabaseHelper();
  final _searchCtrl = TextEditingController();

  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  String _engine = 'Google';

  List<BookmarkGroup> _groups = [];
  List<Bookmark> _bookmarks = [];
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _loadGroups();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final groups = await _db.getGroups();
    setState(() {
      _groups = groups;
      if (_selectedGroupId == null && groups.isNotEmpty) {
        _selectedGroupId = groups.first.id;
      }
    });
    if (_selectedGroupId != null) _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    if (_selectedGroupId == null) {
      setState(() => _bookmarks = []);
      return;
    }
    final bookmarks = await _db.getBookmarksByGroup(_selectedGroupId!);
    setState(() => _bookmarks = bookmarks);
  }

  void _search() {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    final url = '${_engines[_engine]}${Uri.encodeComponent(query)}';
    launchUrl(Uri.parse(url));
  }

  Future<void> _addGroup() async {
    final name = await showAddGroupDialog(context);
    if (name != null && name.trim().isNotEmpty) {
      final id = await _db.insertGroup(BookmarkGroup(name: name.trim()));
      _selectedGroupId = id;
      await _loadGroups();
    }
  }

  Future<void> _deleteGroup(BookmarkGroup group) async {
    final confirmed =
        await showDeleteConfirmDialog(context, '确定删除分组「${group.name}」及其所有书签？');
    if (confirmed == true) {
      await _db.deleteGroup(group.id!);
      if (_selectedGroupId == group.id) _selectedGroupId = null;
      await _loadGroups();
    }
  }

  Future<void> _addBookmark() async {
    final data = await showAddBookmarkDialog(context);
    if (data != null) {
      await _db.insertBookmark(Bookmark(
        groupId: _selectedGroupId!,
        name: data.name,
        url: data.url,
        iconUrl: data.iconUrl,
      ));
      await _loadBookmarks();
    }
  }

  Future<void> _deleteBookmark(Bookmark bm) async {
    final confirmed =
        await showDeleteConfirmDialog(context, '确定删除书签「${bm.name}」？');
    if (confirmed == true) {
      await _db.deleteBookmark(bm.id!);
      await _loadBookmarks();
    }
  }

  void _reorderBookmarks(int oldIndex, int newIndex) {
    final updated = List<Bookmark>.from(_bookmarks);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    setState(() => _bookmarks = updated);
    _db.updateBookmarkOrders(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';
    final dateStr =
        '${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}  星期${_weekdays[_now.weekday - 1]}';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Time display
          SizedBox(
            height: 140,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(16),

          // Search bar
          Row(
            children: [
              SizedBox(
                width: 120,
                child: Select<String>(
                  value: _engine,
                  onChanged: (v) {
                    if (v != null) setState(() => _engine = v);
                  },
                  itemBuilder: (context, value) => Text(value),
                  popup: SelectPopup(
                    items: SelectItemList(
                      children: _engines.keys
                          .map((e) =>
                              SelectItemButton(value: e, child: Text(e)))
                          .toList(),
                    ),
                  ).call,
                ),
              ),
              const Gap(8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  placeholder: const Text('搜索...'),
                  onSubmitted: (_) => _search(),
                  features: [
                    InputFeature.trailing(
                      IconButton.ghost(
                        icon: const Icon(Icons.search),
                        onPressed: _search,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(24),

          // Group tabs
          SizedBox(
            height: 36,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._groups.map((g) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onLongPress: () => _deleteGroup(g),
                          child: _selectedGroupId == g.id
                              ? PrimaryButton(
                                  size: ButtonSize.small,
                                  onPressed: () {},
                                  child: Text(g.name),
                                )
                              : SecondaryButton(
                                  size: ButtonSize.small,
                                  onPressed: () {
                                    setState(() => _selectedGroupId = g.id);
                                    _loadBookmarks();
                                  },
                                  child: Text(g.name),
                                ),
                        ),
                      )),
                  OutlineButton(
                    size: ButtonSize.small,
                    onPressed: _addGroup,
                    child: const Icon(Icons.add, size: 16),
                  ),
                ],
              ),
            ),
          ),
          const Gap(16),

          // Bookmarks grid
          Expanded(
            child: _selectedGroupId == null
                ? Center(
                    child: Text('请先创建一个分组',
                        style: TextStyle(
                            color: theme.colorScheme.mutedForeground)),
                  )
                : SingleChildScrollView(
                    child: SortableWrap(
                      spacing: 12,
                      runSpacing: 12,
                      onSorted: (oldIndex, newIndex) {
                        if (oldIndex >= _bookmarks.length ||
                            newIndex >= _bookmarks.length) {
                          return;
                        }
                        _reorderBookmarks(oldIndex, newIndex);
                      },
                      children: [
                        ..._bookmarks.map((bm) => _BookmarkCard(
                              key: ValueKey(bm.id),
                              bookmark: bm,
                              onTap: () => launchUrl(Uri.parse(bm.url)),
                              onLongPress: () => _deleteBookmark(bm),
                            )),
                        _AddBookmarkCard(
                          key: const ValueKey('add'),
                          onTap: _addBookmark,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BookmarkCard({
    super.key,
    required this.bookmark,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        child: SizedBox(
          width: 100,
          height: 90,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (bookmark.iconUrl != null && bookmark.iconUrl!.isNotEmpty)
                  Image.network(
                    bookmark.iconUrl!,
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.bookmark,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  )
                else
                  Icon(Icons.bookmark,
                      size: 32, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  bookmark.name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddBookmarkCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBookmarkCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: SizedBox(
          width: 100,
          height: 90,
          child: Center(
            child: Icon(Icons.add,
                size: 32, color: theme.colorScheme.mutedForeground),
          ),
        ),
      ),
    );
  }
}
