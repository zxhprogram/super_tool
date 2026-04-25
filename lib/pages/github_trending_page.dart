import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/github_trending_model.dart';
import '../services/github_trending_service.dart';

const _languages = [
  ('全部', ''),
  ('Dart', 'dart'),
  ('Python', 'python'),
  ('JavaScript', 'javascript'),
  ('TypeScript', 'typescript'),
  ('Go', 'go'),
  ('Rust', 'rust'),
  ('Java', 'java'),
  ('Kotlin', 'kotlin'),
  ('Swift', 'swift'),
  ('C++', 'c++'),
  ('C', 'c'),
  ('Ruby', 'ruby'),
  ('PHP', 'php'),
];

const _periods = [
  ('日', 'daily'),
  ('周', 'weekly'),
  ('月', 'monthly'),
];

class GitHubTrendingPage extends StatefulWidget {
  const GitHubTrendingPage({super.key});

  @override
  State<GitHubTrendingPage> createState() => _GitHubTrendingPageState();
}

class _GitHubTrendingPageState extends State<GitHubTrendingPage> {
  final _service = GitHubTrendingService();

  bool _isRepo = true;
  String _since = 'daily';
  String _language = '';
  bool _loading = false;
  String? _error;

  List<TrendingRepo> _repos = [];
  List<TrendingDeveloper> _devs = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isRepo) {
        final repos = await _service.fetchRepos(
          language: _language,
          since: _since,
        );
        setState(() => _repos = repos);
      } else {
        final devs = await _service.fetchDevelopers(
          language: _language,
          since: _since,
        );
        setState(() => _devs = devs);
      }
    } catch (e) {
      setState(() => _error = '加载失败：$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + filters
          Row(
            children: [
              const Text('GitHub 趋势').h2(),
              const Spacer(),
              SizedBox(
                width: 160,
                child: Select<String>(
                  value: _language,
                  onChanged: (v) {
                    if (v != null && v != _language) {
                      setState(() => _language = v);
                      _refresh();
                    }
                  },
                  itemBuilder: (context, value) {
                    final label = _languages
                        .firstWhere((e) => e.$2 == value,
                            orElse: () => ('全部', ''))
                        .$1;
                    return Text(label);
                  },
                  popup: SelectPopup(
                    items: SelectItemList(
                      children: _languages
                          .map((e) => SelectItemButton(
                                value: e.$2,
                                child: Text(e.$1),
                              ))
                          .toList(),
                    ),
                  ).call,
                ),
              ),
              const Gap(8),
              SizedBox(
                width: 100,
                child: Select<String>(
                  value: _since,
                  onChanged: (v) {
                    if (v != null && v != _since) {
                      setState(() => _since = v);
                      _refresh();
                    }
                  },
                  itemBuilder: (context, value) {
                    final label = _periods
                        .firstWhere((e) => e.$2 == value,
                            orElse: () => ('日', 'daily'))
                        .$1;
                    return Text(label);
                  },
                  popup: SelectPopup(
                    items: SelectItemList(
                      children: _periods
                          .map((e) => SelectItemButton(
                                value: e.$2,
                                child: Text(e.$1),
                              ))
                          .toList(),
                    ),
                  ).call,
                ),
              ),
              const Gap(8),
              OutlineButton(
                onPressed: _loading ? null : _refresh,
                child: const Icon(Icons.refresh, size: 16),
              ),
            ],
          ),
          const Gap(16),

          // Tab switcher
          Row(
            children: [
              _isRepo
                  ? PrimaryButton(
                      size: ButtonSize.small,
                      onPressed: () {},
                      leading: const Icon(Icons.folder, size: 14),
                      child: const Text('仓库趋势'),
                    )
                  : SecondaryButton(
                      size: ButtonSize.small,
                      onPressed: () {
                        setState(() => _isRepo = true);
                        _refresh();
                      },
                      leading: const Icon(Icons.folder, size: 14),
                      child: const Text('仓库趋势'),
                    ),
              const Gap(8),
              !_isRepo
                  ? PrimaryButton(
                      size: ButtonSize.small,
                      onPressed: () {},
                      leading: const Icon(Icons.person, size: 14),
                      child: const Text('开发者趋势'),
                    )
                  : SecondaryButton(
                      size: ButtonSize.small,
                      onPressed: () {
                        setState(() => _isRepo = false);
                        _refresh();
                      },
                      leading: const Icon(Icons.person, size: 14),
                      child: const Text('开发者趋势'),
                    ),
            ],
          ),
          const Gap(16),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48,
                                color: theme.colorScheme.mutedForeground),
                            const Gap(12),
                            Text(
                              _error!,
                              style: TextStyle(
                                  color: theme.colorScheme.mutedForeground),
                              textAlign: TextAlign.center,
                            ),
                            const Gap(16),
                            PrimaryButton(
                              onPressed: _refresh,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _isRepo
                        ? _repos.isEmpty
                            ? Center(
                                child: Text('暂无数据',
                                    style: TextStyle(
                                        color:
                                            theme.colorScheme.mutedForeground)))
                            : ListView.separated(
                                itemCount: _repos.length,
                                separatorBuilder: (context, index) =>
                                    const Gap(8),
                                itemBuilder: (context, i) =>
                                    _RepoCard(repo: _repos[i]),
                              )
                        : _devs.isEmpty
                            ? Center(
                                child: Text('暂无数据',
                                    style: TextStyle(
                                        color:
                                            theme.colorScheme.mutedForeground)))
                            : ListView.separated(
                                itemCount: _devs.length,
                                separatorBuilder: (context, index) =>
                                    const Gap(8),
                                itemBuilder: (context, i) =>
                                    _DeveloperCard(dev: _devs[i]),
                              ),
          ),
        ],
      ),
    );
  }
}

// ── Repo card ────────────────────────────────────────────────────────────────

class _RepoCard extends StatelessWidget {
  final TrendingRepo repo;
  const _RepoCard({required this.repo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Owner / repo name
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(repo.url)),
              child: Row(
                children: [
                  _Avatar(url: repo.avatar, radius: 14),
                  const Gap(8),
                  Text(
                    '${repo.author} / ${repo.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (repo.description.isNotEmpty) ...[
              const Gap(8),
              Text(
                repo.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
            const Gap(12),
            // Bottom info row
            Row(
              children: [
                if (repo.language.isNotEmpty) ...[
                  _LangDot(color: repo.languageColor, name: repo.language),
                  const Gap(16),
                ],
                Icon(Icons.star_outline,
                    size: 14,
                    color: theme.colorScheme.mutedForeground),
                const Gap(4),
                Text(
                  _formatNum(repo.stars),
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.mutedForeground),
                ),
                const Gap(16),
                Icon(Icons.fork_right,
                    size: 14,
                    color: theme.colorScheme.mutedForeground),
                const Gap(4),
                Text(
                  _formatNum(repo.forks),
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.mutedForeground),
                ),
                const Spacer(),
                if (repo.builtBy.isNotEmpty) ...[
                  _BuiltBy(users: repo.builtBy),
                  const Gap(12),
                ],
                Icon(Icons.trending_up,
                    size: 14, color: const Color(0xFF4ADE80)),
                const Gap(4),
                Text(
                  '+${_formatNum(repo.currentPeriodStars)} stars',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF4ADE80)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Developer card ───────────────────────────────────────────────────────────

class _DeveloperCard extends StatelessWidget {
  final TrendingDeveloper dev;
  const _DeveloperCard({required this.dev});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(dev.url)),
              child: _Avatar(url: dev.avatar, radius: 24),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(dev.url)),
                    child: Text(
                      dev.username,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (dev.name.isNotEmpty) ...[
                    const Gap(2),
                    Text(
                      dev.name,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.mutedForeground),
                    ),
                  ],
                  if (dev.repo != null) ...[
                    const Gap(8),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(dev.repo!.url)),
                      child: Row(
                        children: [
                          Icon(Icons.star_outline,
                              size: 14,
                              color: theme.colorScheme.primary),
                          const Gap(6),
                          Expanded(
                            child: Text(
                              dev.repo!.description.isNotEmpty
                                  ? '${dev.repo!.name} — ${dev.repo!.description}'
                                  : dev.repo!.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String url;
  final double radius;
  const _Avatar({required this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.secondary,
      ),
      child: Icon(Icons.person, size: radius, color: Theme.of(context).colorScheme.secondaryForeground),
    );
    if (url.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _LangDot extends StatelessWidget {
  final String color;
  final String name;
  const _LangDot({required this.color, required this.name});

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF888888);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _parseColor(color),
            shape: BoxShape.circle,
          ),
        ),
        const Gap(4),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _BuiltBy extends StatelessWidget {
  final List<BuiltByUser> users;
  const _BuiltBy({required this.users});

  @override
  Widget build(BuildContext context) {
    final visible = users.take(3).toList();
    const size = 18.0;
    const overlap = 12.0;
    final totalWidth = size + (visible.length - 1) * overlap;

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * overlap,
              child: _Avatar(url: visible[i].avatar, radius: size / 2),
            ),
        ],
      ),
    );
  }
}

String _formatNum(int n) {
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}
