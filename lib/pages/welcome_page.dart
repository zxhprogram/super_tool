import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.construction,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const Gap(24),
          const Text('Super Tool').h1(),
          const Gap(8),
          Text(
            '一站式桌面工具集',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          const Gap(32),
          const Text('v1.0.0').muted(),
          const Gap(48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _FeatureCard(
                icon: Icons.keyboard,
                title: '按键监听',
                description: '全局按键事件捕获',
                onTap: () => context.go('/key-listener'),
              ),
              _FeatureCard(
                icon: Icons.code,
                title: '配置格式化',
                description: 'JSON / YAML 格式化',
                onTap: () => context.go('/formatter'),
              ),
              _FeatureCard(
                icon: Icons.bookmarks,
                title: '书签管理',
                description: '网页书签收藏管理',
                onTap: () => context.go('/bookmarks'),
              ),
              _FeatureCard(
                icon: Icons.network_check,
                title: '网络监控',
                description: '实时网速与流量统计',
                onTap: () => context.go('/network'),
              ),
              _FeatureCard(
                icon: Icons.monitor_heart,
                title: '系统总览',
                description: 'CPU/内存/磁盘/网络监控',
                onTap: () => context.go('/system'),
              ),
              _FeatureCard(
                icon: Icons.trending_up,
                title: 'GitHub 趋势',
                description: '仓库与开发者热度榜',
                onTap: () => context.go('/github-trending'),
              ),
              _FeatureCard(
                icon: Icons.content_paste,
                title: '剪贴板历史',
                description: '文本/图片/文件历史记录',
                onTap: () => context.go('/clipboard'),
              ),
              _FeatureCard(
                icon: Icons.bar_chart,
                title: '应用统计',
                description: '应用程序使用时长记录',
                onTap: () => context.go('/app-usage'),
              ),
              _FeatureCard(
                icon: Icons.smart_toy,
                title: 'AI 对话',
                description: '多模型 LLM 聊天',
                onTap: () => context.go('/llm-chat'),
              ),
              _FeatureCard(
                icon: Icons.mouse,
                title: '鼠标统计',
                description: '全局鼠标点击计数',
                onTap: () => context.go('/mouse-stats'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: theme.colorScheme.primary),
              const Gap(12),
              Text(title).semiBold(),
              const Gap(4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
