import 'dart:convert';

class DiskStat {
  final String path;
  final int total;
  final int used;
  final int free;
  final double usedPercent;
  final String fstype;

  const DiskStat({
    required this.path,
    required this.total,
    required this.used,
    required this.free,
    required this.usedPercent,
    required this.fstype,
  });

  factory DiskStat.fromJson(Map<String, dynamic> j) => DiskStat(
        path: j['path'] as String? ?? '',
        total: (j['total'] as num?)?.toInt() ?? 0,
        used: (j['used'] as num?)?.toInt() ?? 0,
        free: (j['free'] as num?)?.toInt() ?? 0,
        usedPercent: (j['usedPercent'] as num?)?.toDouble() ?? 0,
        fstype: j['fstype'] as String? ?? '',
      );
}

class NetIface {
  final String name;
  final List<String> addrs;
  final List<String> flags;

  const NetIface({
    required this.name,
    required this.addrs,
    required this.flags,
  });

  factory NetIface.fromJson(Map<String, dynamic> j) => NetIface(
        name: j['name'] as String? ?? '',
        addrs: (j['addrs'] as List<dynamic>?)?.cast<String>() ?? [],
        flags: (j['flags'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}

class SystemStats {
  final int uptime;
  final String platform;
  final String hostname;
  final int memTotal;
  final int memUsed;
  final double memPercent;
  final double cpuPercent;
  final List<DiskStat> disks;
  final List<NetIface> netIfaces;

  const SystemStats({
    required this.uptime,
    required this.platform,
    required this.hostname,
    required this.memTotal,
    required this.memUsed,
    required this.memPercent,
    required this.cpuPercent,
    required this.disks,
    required this.netIfaces,
  });

  factory SystemStats.fromJson(Map<String, dynamic> j) => SystemStats(
        uptime: (j['uptime'] as num?)?.toInt() ?? 0,
        platform: j['platform'] as String? ?? '',
        hostname: j['hostname'] as String? ?? '',
        memTotal: (j['memTotal'] as num?)?.toInt() ?? 0,
        memUsed: (j['memUsed'] as num?)?.toInt() ?? 0,
        memPercent: (j['memPercent'] as num?)?.toDouble() ?? 0,
        cpuPercent: (j['cpuPercent'] as num?)?.toDouble() ?? 0,
        disks: (j['disks'] as List<dynamic>? ?? [])
            .map((e) => DiskStat.fromJson(e as Map<String, dynamic>))
            .toList(),
        netIfaces: (j['netIfaces'] as List<dynamic>? ?? [])
            .map((e) => NetIface.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static SystemStats? tryParse(String jsonStr) {
    try {
      return SystemStats.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

class EnvVar {
  final String key;
  final String value;

  const EnvVar({required this.key, required this.value});

  factory EnvVar.fromJson(Map<String, dynamic> j) => EnvVar(
        key: j['key'] as String? ?? '',
        value: j['value'] as String? ?? '',
      );

  static List<EnvVar> parseList(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => EnvVar.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
