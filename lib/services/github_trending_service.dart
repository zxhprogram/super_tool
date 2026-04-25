import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/github_trending_model.dart';

class GitHubTrendingService {
  static const _base = 'https://github.com';
  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept': 'text/html,application/xhtml+xml',
  };

  Future<List<TrendingRepo>> fetchRepos({
    String language = '',
    String since = 'daily',
  }) async {
    final path =
        language.isEmpty ? '/trending' : '/trending/${Uri.encodeComponent(language)}';
    final uri = Uri.parse('$_base$path').replace(
      queryParameters: {'since': since},
    );
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return _parseRepos(res.body);
  }

  Future<List<TrendingDeveloper>> fetchDevelopers({
    String language = '',
    String since = 'daily',
  }) async {
    final path = language.isEmpty
        ? '/trending/developers'
        : '/trending/developers/${Uri.encodeComponent(language)}';
    final uri = Uri.parse('$_base$path').replace(
      queryParameters: {'since': since},
    );
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return _parseDevelopers(res.body);
  }

  // ── Parsers ──────────────────────────────────────────────────────────────

  List<TrendingRepo> _parseRepos(String html) {
    final doc = html_parser.parse(html);
    final articles = doc.querySelectorAll('article.Box-row');
    final repos = <TrendingRepo>[];

    for (final article in articles) {
      // Owner / repo from h2 > a href="/owner/repo"
      final repoLink = article.querySelector('h2.h3 a');
      if (repoLink == null) continue;
      final href = repoLink.attributes['href'] ?? '';
      final parts = href.split('/').where((s) => s.isNotEmpty).toList();
      if (parts.length < 2) continue;
      final author = parts[0];
      final name = parts[1];
      final repoUrl = '$_base/$author/$name';

      // Description
      final descEl = article.querySelector('p.color-fg-muted');
      final description = descEl?.text.trim() ?? '';

      // Language
      var language = '';
      var languageColor = '';
      final langColorEl = article.querySelector('span.repo-language-color');
      final langNameEl = article.querySelector('[itemprop="programmingLanguage"]');
      if (langNameEl != null) {
        language = langNameEl.text.trim();
        final style = langColorEl?.attributes['style'] ?? '';
        final colorMatch = RegExp(r'#[0-9a-fA-F]{3,6}').firstMatch(style);
        languageColor = colorMatch?.group(0) ?? '';
      }

      // Stars & forks — links to /stargazers and /forks
      var stars = 0;
      var forks = 0;
      final statLinks = article.querySelectorAll('a.Link--muted');
      for (final link in statLinks) {
        final h = link.attributes['href'] ?? '';
        final num = _parseNum(link.text.trim());
        if (h.endsWith('/stargazers')) stars = num;
        if (h.endsWith('/forks')) forks = num;
      }

      // Period stars — span.float-sm-right text "3,975 stars today"
      var periodStars = 0;
      final periodEl = article.querySelector('span.float-sm-right');
      if (periodEl != null) {
        periodStars = _parseNum(periodEl.text.trim());
      }

      // Built-by avatars
      final builtBy = article
          .querySelectorAll('img.avatar-user')
          .map((img) {
            final src = img.attributes['src'] ?? '';
            final alt = img.attributes['alt'] ?? '';
            final username = alt.startsWith('@') ? alt.substring(1) : alt;
            return BuiltByUser(username: username, avatar: src);
          })
          .toList();

      // Owner avatar — use GitHub's avatar endpoint
      final avatar = 'https://github.com/$author.png';

      repos.add(TrendingRepo(
        author: author,
        name: name,
        avatar: avatar,
        url: repoUrl,
        description: description,
        language: language,
        languageColor: languageColor,
        stars: stars,
        forks: forks,
        currentPeriodStars: periodStars,
        builtBy: builtBy,
      ));
    }
    return repos;
  }

  List<TrendingDeveloper> _parseDevelopers(String html) {
    final doc = html_parser.parse(html);
    final articles = doc.querySelectorAll('article.Box-row');
    final devs = <TrendingDeveloper>[];

    for (final article in articles) {
      // Username from article id: "pa-username"
      final id = article.attributes['id'] ?? '';
      final username = id.startsWith('pa-') ? id.substring(3) : '';
      if (username.isEmpty) continue;

      // Avatar
      final avatarImg = article.querySelector('img.avatar-user');
      final avatar = avatarImg?.attributes['src'] ?? '';

      // Full name — h1.h3 a
      final nameEl = article.querySelector('h1.h3 a');
      final name = nameEl?.text.trim() ?? '';

      final devUrl = '$_base/$username';

      // Popular repo — h1.h4 a
      TrendingDeveloperRepo? repo;
      final repoLinkEl = article.querySelector('h1.h4 a');
      if (repoLinkEl != null) {
        final repoHref = repoLinkEl.attributes['href'] ?? '';
        final repoParts =
            repoHref.split('/').where((s) => s.isNotEmpty).toList();
        final repoName = repoParts.length >= 2 ? repoParts[1] : repoLinkEl.text.trim();
        // Description after h1.h4
        final repoDescEl = article.querySelector('div.f6.color-fg-muted.mt-1');
        final repoDesc = repoDescEl?.text.trim() ?? '';
        repo = TrendingDeveloperRepo(
          name: repoName,
          description: repoDesc,
          url: '$_base$repoHref',
        );
      }

      devs.add(TrendingDeveloper(
        username: username,
        name: name,
        type: 'user',
        url: devUrl,
        avatar: avatar,
        repo: repo,
      ));
    }
    return devs;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _parseNum(String text) {
    final cleaned = text.replaceAll(',', '').replaceAll(' ', '');
    final match = RegExp(r'\d+').firstMatch(cleaned);
    return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
  }
}
