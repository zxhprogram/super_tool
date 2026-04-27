class MouseMinuteStat {
  final int id;
  final int minuteTs;
  final int clickCount;

  MouseMinuteStat({
    required this.id,
    required this.minuteTs,
    required this.clickCount,
  });

  factory MouseMinuteStat.fromMap(Map<String, dynamic> m) => MouseMinuteStat(
        id: m['id'] as int,
        minuteTs: m['minute_ts'] as int,
        clickCount: m['click_count'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'minute_ts': minuteTs,
        'click_count': clickCount,
      };
}
