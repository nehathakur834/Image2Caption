import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_gradient_button.dart';

/// Premium card with subtle shadow and optional gradient accent border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xxl),
    this.gradient,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? surface : null,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: border, width: 1),
        boxShadow: AppShadows.card(isDark),
        gradient: gradient,
      ),
      clipBehavior: clipBehavior,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Section header with title and optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle case final sub?) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A hashtag chip widget.
class HashtagChip extends StatelessWidget {
  const HashtagChip({super.key, required this.tag, this.onTap});

  final String tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.brandPurple.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: AppColors.brandPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          tag.startsWith('#') ? tag : '#$tag',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.brandViolet : AppColors.brandPurple,
          ),
        ),
      ),
    );
  }
}

/// Beautiful empty state widget.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.brandPurple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 44, color: AppColors.brandPurple),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textDark,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white54 : AppColors.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppGradientButton(
                label: actionLabel!,
                onPressed: onAction,
                icon: Icons.auto_awesome_rounded,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
