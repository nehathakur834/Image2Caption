import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/caption_provider.dart';
import '../theme/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.xl),
                // Appearance
                _SectionTitle(title: 'Appearance', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _ThemeTile(
                      label: 'Light Mode',
                      icon: Icons.light_mode_rounded,
                      isSelected: provider.themeMode == ThemeMode.light,
                      onTap: () => _setTheme(provider, ThemeMode.light),
                      isDark: isDark,
                    ),
                    _Divider(isDark: isDark),
                    _ThemeTile(
                      label: 'Dark Mode',
                      icon: Icons.dark_mode_rounded,
                      isSelected: provider.themeMode == ThemeMode.dark,
                      onTap: () => _setTheme(provider, ThemeMode.dark),
                      isDark: isDark,
                    ),
                    _Divider(isDark: isDark),
                    _ThemeTile(
                      label: 'System Default',
                      icon: Icons.phone_android_rounded,
                      isSelected: provider.themeMode == ThemeMode.system,
                      onTap: () => _setTheme(provider, ThemeMode.system),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                // AI
                _SectionTitle(title: 'AI', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _InfoTile(
                      icon: Icons.auto_awesome_rounded,
                      iconGradient: AppGradients.brand,
                      title: 'AI Caption Generator',
                      subtitle: 'Powered by OpenAI Vision',
                      isDark: isDark,
                    ),
                    _Divider(isDark: isDark),
                    _InfoTile(
                      icon: Icons.security_rounded,
                      iconGradient: AppGradients.accent2,
                      title: 'API Key Security',
                      subtitle: 'Keys are never stored in source code.\nUse --dart-define or .env',
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                // App
                _SectionTitle(title: 'App', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _InfoTile(
                      icon: Icons.info_outline_rounded,
                      iconGradient: AppGradients.accent1,
                      title: 'About Image2Caption',
                      subtitle: 'Version 1.0.0 · AI-powered social media tool',
                      isDark: isDark,
                    ),
                    _Divider(isDark: isDark),
                    _ActionTile(
                      icon: Icons.delete_sweep_rounded,
                      iconGradient: LinearGradient(
                        colors: [AppColors.error, Color(0xFFFF6B6B)],
                      ),
                      title: 'Clear History',
                      subtitle: 'Remove all saved captions',
                      isDark: isDark,
                      onTap: () => _clearHistory(context, provider),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                // Footer
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          gradient: AppGradients.brand,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Image2Caption',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Powered by OpenAI · Built with Flutter',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      surfaceTintColor: Colors.transparent,
      title: const Text('Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
    );
  }

  void _setTheme(CaptionProvider provider, ThemeMode target) {
    // Cycle until we reach the target mode.
    for (int i = 0; i < 3; i++) {
      if (provider.themeMode == target) return;
      provider.toggleTheme();
    }
  }

  Future<void> _clearHistory(
      BuildContext context, CaptionProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'All saved captions will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final record in List.of(provider.history)) {
        await provider.deleteCaption(record);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared')),
        );
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: isDark ? Colors.white38 : AppColors.textMuted,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.isDark, required this.children});
  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 62),
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isSelected
          ? AppRadius.cardRadius
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isSelected ? AppGradients.brand : null,
                color: isSelected
                    ? null
                    : (isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : AppColors.textMuted),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.brandPurple
                    : (isDark ? Colors.white : AppColors.textDark),
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.brandPurple,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final IconData icon;
  final Gradient iconGradient;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: iconGradient,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Gradient iconGradient;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: iconGradient,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white30 : AppColors.lightBorder,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
