import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final String route;
  const _FeatureData(this.icon, this.title, this.description, this.route);
}

const _features = [
  _FeatureData(Icons.keyboard, '按键监听', '全局按键事件捕获', '/key-listener'),
  _FeatureData(Icons.code, '配置格式化', 'JSON / YAML 格式化', '/formatter'),
  _FeatureData(Icons.bookmarks, '书签管理', '网页书签收藏管理', '/bookmarks'),
  _FeatureData(Icons.network_check, '网络监控', '实时网速与流量统计', '/network'),
  _FeatureData(Icons.monitor_heart, '系统总览', 'CPU/内存/磁盘/网络监控', '/system'),
  _FeatureData(Icons.trending_up, 'GitHub 趋势', '仓库与开发者热度榜', '/github-trending'),
  _FeatureData(Icons.content_paste, '剪贴板历史', '文本/图片/文件历史记录', '/clipboard'),
  _FeatureData(Icons.bar_chart, '应用统计', '应用程序使用时长记录', '/app-usage'),
  _FeatureData(Icons.smart_toy, 'AI 对话', '多模型 LLM 聊天', '/llm-chat'),
  _FeatureData(Icons.mouse, '鼠标统计', '全局鼠标点击计数', '/mouse-stats'),
];

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.construction,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Super Tool').h2(),
                  const Gap(4),
                  Text(
                    '一站式桌面工具集',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                  const Gap(4),
                  const Text('v1.0.0').muted(),
                ],
              ),
            ],
          ),
          const Gap(32),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                      ? 3
                      : 2;
              final cardWidth =
                  (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                      crossAxisCount;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _features
                    .map((f) => SizedBox(
                          width: cardWidth,
                          child: _FeatureCard(
                            icon: f.icon,
                            title: f.title,
                            description: f.description,
                            onTap: () => context.go(f.route),
                          ),
                        ))
                    .toList(),
              );
            },
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SurfaceCard(
          surfaceBlur: 8,
          surfaceOpacity: 0.6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child:
                      Icon(icon, size: 24, color: theme.colorScheme.primary),
                ),
                const Gap(16),
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
      ),
    );
  }
}
