class KeyMinuteStat {
  final int? id;
  final int minuteTs;
  final int keyCount;

  const KeyMinuteStat({
    this.id,
    required this.minuteTs,
    required this.keyCount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'minute_ts': minuteTs,
        'key_count': keyCount,
      };

  factory KeyMinuteStat.fromMap(Map<String, dynamic> map) => KeyMinuteStat(
        id: map['id'] as int?,
        minuteTs: map['minute_ts'] as int,
        keyCount: map['key_count'] as int,
      );
}
