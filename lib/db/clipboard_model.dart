class ClipboardRecord {
  final int? id;
  final String type;
  final String? content;
  final String? preview;
  final String hash;
  final int createdAt;

  const ClipboardRecord({
    this.id,
    required this.type,
    this.content,
    this.preview,
    required this.hash,
    required this.createdAt,
  });

  factory ClipboardRecord.fromMap(Map<String, dynamic> m) => ClipboardRecord(
        id: m['id'] as int?,
        type: m['type'] as String,
        content: m['content'] as String?,
        preview: m['preview'] as String?,
        hash: m['hash'] as String,
        createdAt: m['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'content': content,
        'preview': preview,
        'hash': hash,
        'created_at': createdAt,
      };

  ClipboardRecord copyWith({int? id}) => ClipboardRecord(
        id: id ?? this.id,
        type: type,
        content: content,
        preview: preview,
        hash: hash,
        createdAt: createdAt,
      );
}
