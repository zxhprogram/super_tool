class BookmarkGroup {
  int? id;
  String name;
  int sortOrder;

  BookmarkGroup({this.id, required this.name, this.sortOrder = 0});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'sort_order': sortOrder,
      };

  factory BookmarkGroup.fromMap(Map<String, dynamic> map) => BookmarkGroup(
        id: map['id'] as int,
        name: map['name'] as String,
        sortOrder: map['sort_order'] as int? ?? 0,
      );
}

class Bookmark {
  int? id;
  int groupId;
  String name;
  String url;
  String? iconUrl;
  int sortOrder;

  Bookmark({
    this.id,
    required this.groupId,
    required this.name,
    required this.url,
    this.iconUrl,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'group_id': groupId,
        'name': name,
        'url': url,
        'icon_url': iconUrl,
        'sort_order': sortOrder,
      };

  factory Bookmark.fromMap(Map<String, dynamic> map) => Bookmark(
        id: map['id'] as int,
        groupId: map['group_id'] as int,
        name: map['name'] as String,
        url: map['url'] as String,
        iconUrl: map['icon_url'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
      );
}
