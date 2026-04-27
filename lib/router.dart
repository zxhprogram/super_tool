import 'package:go_router/go_router.dart';
import 'pages/welcome_page.dart';
import 'pages/key_listener_page.dart';
import 'pages/formatter_page.dart';
import 'pages/bookmark_page.dart';
import 'pages/network_page.dart';
import 'pages/github_trending_page.dart';
import 'pages/system_overview_page.dart';
import 'pages/clipboard_history_page.dart';
import 'pages/app_usage_page.dart';
import 'pages/llm_chat_page.dart';
import 'pages/mouse_stats_page.dart';
import 'pages/shell_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
        GoRoute(path: '/key-listener', builder: (context, state) => const KeyListenerPage()),
        GoRoute(path: '/formatter', builder: (context, state) => const FormatterPage()),
        GoRoute(path: '/bookmarks', builder: (context, state) => const BookmarkPage()),
        GoRoute(path: '/network', builder: (context, state) => const NetworkPage()),
        GoRoute(path: '/github-trending', builder: (context, state) => const GitHubTrendingPage()),
        GoRoute(path: '/system', builder: (context, state) => const SystemOverviewPage()),
        GoRoute(path: '/clipboard', builder: (context, state) => const ClipboardHistoryPage()),
        GoRoute(path: '/app-usage', builder: (context, state) => const AppUsagePage()),
        GoRoute(path: '/llm-chat', builder: (context, state) => const LlmChatPage()),
        GoRoute(path: '/mouse-stats', builder: (context, state) => const MouseStatsPage()),
      ],
    ),
  ],
);
