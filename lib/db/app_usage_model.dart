class AppUsageMinute {
  final int? id;
  final String processName;
  final int minuteTs;
  final int seconds;

  const AppUsageMinute({
    this.id,
    required this.processName,
    required this.minuteTs,
    required this.seconds,
  });

  factory AppUsageMinute.fromMap(Map<String, dynamic> m) => AppUsageMinute(
        id: m['id'] as int?,
        processName: m['process_name'] as String,
        minuteTs: m['minute_ts'] as int,
        seconds: m['seconds'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'process_name': processName,
        'minute_ts': minuteTs,
        'seconds': seconds,
      };
}

class AppUsageSummary {
  final String processName;
  final int totalSeconds;

  const AppUsageSummary({
    required this.processName,
    required this.totalSeconds,
  });

  factory AppUsageSummary.fromMap(Map<String, dynamic> m) => AppUsageSummary(
        processName: m['process_name'] as String,
        totalSeconds: (m['total_seconds'] as num).toInt(),
      );
}
