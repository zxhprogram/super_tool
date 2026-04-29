import 'dart:async';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../db/database_helper.dart';
import '../ffi/network_service.dart';
import '../ffi/system_bindings.dart';
import '../models/system_stats_model.dart';
import '../widgets/page_wrapper.dart';

class SystemOverviewPage extends StatefulWidget {
  const SystemOverviewPage({super.key});

  @override
  State<SystemOverviewPage> createState() => _SystemOverviewPageState();
}

class _SystemOverviewPageState extends State<SystemOverviewPage> {
  final _db = DatabaseHelper();
  final _bindings = SystemBindings();

  SystemStats? _stats;
  List<EnvVar> _envVars = [];
  int _histNetSent = 0;
  int _histNetRecv = 0;
  Timer? _timer;
  StreamSubscription<NetworkSnapshot>? _netSub;
  int _sessionSent = 0;
  int _sessionRecv = 0;

  @override
  void initState() {
    super.initState();
    _loadEnvVars();
    _loadHistoryNet();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
    _sessionSent = networkService.lastSnapshot.totalSent;
    _sessionRecv = networkService.lastSnapshot.totalRecv;
    _netSub = networkService.snapshots.listen((snap) {
      if (mounted) {
        setState(() {
          _sessionSent = snap.totalSent;
          _sessionRecv = snap.totalRecv;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _netSub?.cancel();
    super.dispose();
  }

  void _refresh() {
    final json = _bindings.getSystemStats();
    if (json != null && mounted) {
      final stats = SystemStats.tryParse(json);
      if (stats != null) setState(() => _stats = stats);
    }
  }

  Future<void> _loadEnvVars() async {
    final json = await Future.microtask(() => _bindings.getEnvVars());
    if (json != null && mounted) {
      setState(() => _envVars = EnvVar.parseList(json));
    }
  }

  Future<void> _loadHistoryNet() async {
    final rows = await _db.getAllNetStats();
    if (!mounted) return;
    setState(() {
      _histNetSent = rows.fold(0, (s, r) => s + r.bytesSent);
      _histNetRecv = rows.fold(0, (s, r) => s + r.bytesRecv);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _stats;

    return PageWrapper(
      title: '系统总览',
      breadcrumbLabel: '监控',
      trailing: OutlineButton(
        onPressed: () {
          _refresh();
          _loadHistoryNet();
        },
        child: const Icon(Icons.refresh, size: 16),
      ),
      child: stats == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: uptime + OS + session network
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _InfoCard(
                                  icon: Icons.timer_outlined,
                                  title: '开机时长',
                                  value: _fmtUptime(stats.uptime),
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: _InfoCard(
                                  icon: Icons.computer,
                                  title: stats.hostname,
                                  value: stats.platform,
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: _InfoCard(
                                  icon: Icons.swap_vert,
                                  title: '本次会话网络',
                                  value:
                                      '↑ ${_fmtBytes(_sessionSent)}   ↓ ${_fmtBytes(_sessionRecv)}',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),

                        // Row 2: CPU + Memory
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _GaugeCard(
                                  title: 'CPU 使用率',
                                  percent: stats.cpuPercent,
                                  theme: theme,
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: _MemCard(
                                  total: stats.memTotal,
                                  used: stats.memUsed,
                                  percent: stats.memPercent,
                                  theme: theme,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),

                        // History network
                        _HistoryNetCard(
                          sent: _histNetSent,
                          recv: _histNetRecv,
                          theme: theme,
                        ),
                        const Gap(12),

                        // Disks
                        if (stats.disks.isNotEmpty) ...[
                          _DiskCard(disks: stats.disks, theme: theme),
                          const Gap(12),
                        ],

                        // Network interfaces
                        if (stats.netIfaces.isNotEmpty) ...[
                          _NetIfaceCard(ifaces: stats.netIfaces, theme: theme),
                          const Gap(12),
                        ],

                        // Environment variables
                        if (_envVars.isNotEmpty)
                          _EnvVarCard(vars: _envVars, theme: theme),
                      ],
                    ),
                  ),
    );
  }
}

// ── Info card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoCard(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      surfaceBlur: 6,
      surfaceOpacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: theme.colorScheme.mutedForeground),
                const Gap(6),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.mutedForeground),
                ),
              ],
            ),
            const Gap(8),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gauge card (CPU) ─────────────────────────────────────────────────────────

class _GaugeCard extends StatelessWidget {
  final String title;
  final double percent;
  final ThemeData theme;
  const _GaugeCard(
      {required this.title, required this.percent, required this.theme});

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0.0, 100.0);
    return SurfaceCard(
      surfaceBlur: 6,
      surfaceOpacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, size: 14, color: theme.colorScheme.mutedForeground),
                const Gap(6),
                Text(title,
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.mutedForeground)),
                const Spacer(),
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const Gap(10),
            LinearProgressIndicator(value: pct / 100),
          ],
        ),
      ),
    );
  }
}

// ── Memory card ──────────────────────────────────────────────────────────────

class _MemCard extends StatelessWidget {
  final int total;
  final int used;
  final double percent;
  final ThemeData theme;
  const _MemCard(
      {required this.total,
      required this.used,
      required this.percent,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0.0, 100.0);
    return SurfaceCard(
      surfaceBlur: 6,
      surfaceOpacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, size: 14,
                    color: theme.colorScheme.mutedForeground),
                const Gap(6),
                Text('内存使用',
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.mutedForeground)),
                const Spacer(),
                Text(
                  '${_fmtBytes(used)} / ${_fmtBytes(total)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const Gap(10),
            LinearProgressIndicator(value: pct / 100),
            const Gap(6),
            Text(
              '${pct.toStringAsFixed(1)}%  可用 ${_fmtBytes(total - used)}',
              style: TextStyle(
                  fontSize: 11, color: theme.colorScheme.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History network card ─────────────────────────────────────────────────────

class _HistoryNetCard extends StatelessWidget {
  final int sent;
  final int recv;
  final ThemeData theme;
  const _HistoryNetCard(
      {required this.sent, required this.recv, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      surfaceBlur: 6,
      surfaceOpacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 14,
                    color: theme.colorScheme.mutedForeground),
                const Gap(6),
                Text('历史网络总使用量',
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.mutedForeground)),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: _NetStat(
                      label: '总上传',
                      value: _fmtBytes(sent),
                      icon: Icons.upload,
                      theme: theme),
                ),
                Expanded(
                  child: _NetStat(
                      label: '总下载',
                      value: _fmtBytes(recv),
                      icon: Icons.download,
                      theme: theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;
  const _NetStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const Gap(8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: theme.colorScheme.mutedForeground)),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

// ── Disk card ────────────────────────────────────────────────────────────────

class _DiskCard extends StatelessWidget {
  final List<DiskStat> disks;
  final ThemeData theme;
  const _DiskCard({required this.disks, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      surfaceBlur: 6,
      surfaceOpacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.disc_full_outlined, size: 14,
                    color: theme.colorScheme.mutedForeground),
                const Gap(6),
                Text('磁盘使用量',
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.mutedForeground)),
              ],
            ),
            const Gap(12),
            ...disks.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(d.path,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const Gap(8),
                          Text(d.fstype,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.mutedForeground)),
                          const Spacer(),
                          Text(
                            '${_fmtBytes(d.used)} / ${_fmtBytes(d.total)}  ${d.usedPercent.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const Gap(4),
                      LinearProgressIndicator(
                          value: (d.usedPercent / 100).clamp(0.0, 1.0)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Network interfaces card ───────────────────────────────────────────────────

class _NetIfaceCard extends StatelessWidget {
  final List<NetIface> ifaces;
  final ThemeData theme;
  const _NetIfaceCard({required this.ifaces, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      surfaceBlur: 6,
      surfaceOpacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lan_outlined, size: 14,
                    color: theme.colorScheme.mutedForeground),
                const Gap(6),
                Text('当前网络连接',
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.mutedForeground)),
              ],
            ),
            const Gap(12),
            ...ifaces.map((iface) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(iface.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const Gap(8),
                          Text(iface.flags.join(', '),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.mutedForeground)),
                        ],
                      ),
                      if (iface.addrs.isNotEmpty) ...[
                        const Gap(2),
                        Text(iface.addrs.join('   '),
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.mutedForeground)),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Env vars card ────────────────────────────────────────────────────────────

class _EnvVarCard extends StatefulWidget {
  final List<EnvVar> vars;
  final ThemeData theme;
  const _EnvVarCard({required this.vars, required this.theme});

  @override
  State<_EnvVarCard> createState() => _EnvVarCardState();
}

class _EnvVarCardState extends State<_EnvVarCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visible = _expanded ? widget.vars : widget.vars.take(8).toList();
    return SurfaceCard(
      surfaceBlur: 6,
      surfaceOpacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_applications_outlined,
                    size: 14, color: widget.theme.colorScheme.mutedForeground),
                const Gap(6),
                Text('系统环境变量 (${widget.vars.length})',
                    style: TextStyle(
                        fontSize: 12,
                        color: widget.theme.colorScheme.mutedForeground)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? '收起' : '展开全部',
                    style: TextStyle(
                        fontSize: 12,
                        color: widget.theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
            const Gap(8),
            ...visible.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 200,
                        child: Text(
                          e.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                              fontSize: 12,
                              color: widget.theme.colorScheme.mutedForeground),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                )),
            if (!_expanded && widget.vars.length > 8) ...[
              const Gap(4),
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Text(
                  '… 还有 ${widget.vars.length - 8} 个变量',
                  style: TextStyle(
                      fontSize: 12, color: widget.theme.colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _fmtBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes >= 1 << 30) return '${(bytes / (1 << 30)).toStringAsFixed(2)} GB';
  if (bytes >= 1 << 20) return '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
  if (bytes >= 1 << 10) return '${(bytes / (1 << 10)).toStringAsFixed(1)} KB';
  return '$bytes B';
}

String _fmtUptime(int seconds) {
  final d = seconds ~/ 86400;
  final h = (seconds % 86400) ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (d > 0) return '$d 天 $h 时 $m 分';
  return '$h 时 $m 分';
}
