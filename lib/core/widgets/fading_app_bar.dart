import 'package:flutter/material.dart';
import 'package:hypixel_tracker/core/theme/app_theme.dart';

// An app bar that fades out at its bottom edge, so the list looks like it
// slides under it. Use with `extendBodyBehindAppBar: true` on the Scaffold.
class FadingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FadingAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.actions,
    this.bottom,
  });

  final String title;

  /// A status line under the title, e.g. "Updated 09/10 14:05".
  final String? subtitle;
  final Color? subtitleColor;
  final List<Widget>? actions;

  /// Stays pinned under the title, e.g. a search field.
  final PreferredSizeWidget? bottom;

  static const _toolbarHeight = 64.0;

  // Height of the see-through strip at the bottom of the bar.
  static const _fadeHeight = AppSpacing.lg;

  @override
  Size get preferredSize => Size.fromHeight(
    _toolbarHeight + (bottom?.preferredSize.height ?? 0) + _fadeHeight,
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    final bottom = this.bottom;

    // The gradient covers the whole bar, system status bar included.
    final totalHeight =
        MediaQuery.paddingOf(context).top + preferredSize.height;

    return AppBar(
      toolbarHeight: _toolbarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle != null)
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: subtitleColor),
            ),
        ],
      ),
      actions: actions,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.background,
              AppColors.background.withValues(alpha: 0),
            ],
            stops: [0, 1 - _fadeHeight / totalHeight, 1],
          ),
        ),
        child: const SizedBox.expand(),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(
          (bottom?.preferredSize.height ?? 0) + _fadeHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?bottom,
            const SizedBox(height: _fadeHeight),
          ],
        ),
      ),
    );
  }
}
