import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../state/sidebar_state.dart';

class ShellPage extends StatelessWidget {
  final Widget child;
  const ShellPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final expanded = sidebarExpanded.watch(context);
    final location = GoRouterState.of(context).uri.path;

    return Row(
      children: [
        NavigationRail(
          expanded: expanded,
          labelType: NavigationLabelType.expanded,
          labelPosition: NavigationLabelPosition.end,
          alignment: NavigationRailAlignment.start,
          selectedKey: ValueKey(location),
          onSelected: (key) {
            if (key is ValueKey<String>) {
              context.go(key.value);
            }
          },
          header: [
            NavigationButton(
              alignment: Alignment.centerLeft,
              label: const Text('Super Tool'),
              onPressed: () {
                sidebarExpanded.value = !sidebarExpanded.value;
              },
              child: const Icon(Icons.menu),
            ),
            const NavigationDivider(),
          ],
          children: [
            NavigationItem(
              key: const ValueKey('/'),
              label: const Text('首页'),
              child: const Icon(Icons.home),
            ),
            NavigationItem(
              key: const ValueKey('/key-listener'),
              label: const Text('按键监听'),
              child: const Icon(Icons.keyboard),
            ),
            NavigationItem(
              key: const ValueKey('/formatter'),
              label: const Text('配置格式化'),
              child: const Icon(Icons.code),
            ),
            NavigationItem(
              key: const ValueKey('/bookmarks'),
              label: const Text('书签管理'),
              child: const Icon(Icons.bookmarks),
            ),
            NavigationItem(
              key: const ValueKey('/network'),
              label: const Text('网络监控'),
              child: const Icon(Icons.network_check),
            ),
            NavigationItem(
              key: const ValueKey('/system'),
              label: const Text('系统总览'),
              child: const Icon(Icons.monitor_heart),
            ),
            NavigationItem(
              key: const ValueKey('/github-trending'),
              label: const Text('GitHub 趋势'),
              child: const Icon(Icons.trending_up),
            ),
            NavigationItem(
              key: const ValueKey('/clipboard'),
              label: const Text('剪贴板历史'),
              child: const Icon(Icons.content_paste),
            ),
            NavigationItem(
              key: const ValueKey('/app-usage'),
              label: const Text('应用统计'),
              child: const Icon(Icons.bar_chart),
            ),
          ],
        ),
        Expanded(child: child),
      ],
    );
  }
}
