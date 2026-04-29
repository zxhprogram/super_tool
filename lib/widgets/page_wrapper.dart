import 'package:shadcn_flutter/shadcn_flutter.dart';

class PageWrapper extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? breadcrumbLabel;
  final Widget? trailing;
  final Widget child;
  final bool padContent;

  const PageWrapper({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbLabel,
    this.trailing,
    required this.child,
    this.padContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (breadcrumbLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              breadcrumbLabel!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(title).h4().semiBold(),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Expanded(
          child: padContent
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: child,
                )
              : child,
        ),
      ],
    );
  }
}
