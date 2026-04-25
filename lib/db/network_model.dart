class NetworkMinuteStat {
  final int? id;
  final int minuteTs;
  final int bytesSent;
  final int bytesRecv;

  const NetworkMinuteStat({
    this.id,
    required this.minuteTs,
    required this.bytesSent,
    required this.bytesRecv,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'minute_ts': minuteTs,
        'bytes_sent': bytesSent,
        'bytes_recv': bytesRecv,
      };

  factory NetworkMinuteStat.fromMap(Map<String, dynamic> map) =>
      NetworkMinuteStat(
        id: map['id'] as int?,
        minuteTs: map['minute_ts'] as int,
        bytesSent: map['bytes_sent'] as int,
        bytesRecv: map['bytes_recv'] as int,
      );
}
