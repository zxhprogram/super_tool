import 'package:go_router/go_router.dart';
import 'pages/welcome_page.dart';
import 'pages/key_listener_page.dart';
import 'pages/formatter_page.dart';
import 'pages/shell_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const WelcomePage(),
        ),
        GoRoute(
          path: '/key-listener',
          builder: (context, state) => const KeyListenerPage(),
        ),
        GoRoute(
          path: '/formatter',
          builder: (context, state) => const FormatterPage(),
        ),
      ],
    ),
  ],
);
