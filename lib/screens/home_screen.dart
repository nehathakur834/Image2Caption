import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/caption_record.dart';
import '../providers/caption_provider.dart';
import '../theme/theme.dart';
import '../widgets/app_components.dart';
import 'app_shell.dart';
import 'history_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recentItems = provider.history.take(5).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark, provider),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.lg),
                _HeroCard(isDark: isDark),
                const SizedBox(height: AppSpacing.xxl),
                SectionHeader(
                  title: 'Create Something New',
                  subtitle: 'Pick a workflow to get started',
                ),
                const SizedBox(height: AppSpacing.md),
                _QuickCreateCards(isDark: isDark),
                const SizedBox(height: AppSpacing.xxl),
                SectionHeader(
                  title: 'Recent Creations',
                  subtitle: 'Your latest AI-generated content',
                  trailing: recentItems.isNotEmpty
                      ? TextButton(
                          onPressed: () => _goToHistory(context),
                          child: const Text('View All'),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                if (recentItems.isEmpty)
                  _EmptyRecentCard(isDark: isDark)
                else
                  ...recentItems.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _RecentItemCard(
                        record: record,
                        isDark: isDark,
                        onTap: () => _openRecord(context, record),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    bool isDark,
    CaptionProvider provider,
  ) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning 👋'
        : hour < 18
            ? 'Good afternoon 👋'
            : 'Good evening 👋';

    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        greeting,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    // Theme toggle
                    GestureDetector(
                      onTap: provider.toggleTheme,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 20,
                          color: isDark ? Colors.white70 : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Turn your photos into engaging social content.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
    );
  }

  void _goToHistory(BuildContext context) {
    ShellNavigator.of(context)?.switchTab(2);
  }

  void _openRecord(BuildContext context, CaptionRecord record) {
    context.read<CaptionProvider>().reuseCaption(record);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: HistoryDetailScreen(record: record),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.button,
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Text(
                    '✨ AI Caption Generator',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Create perfect\ncaptions instantly',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Upload a photo and let AI write\nthe perfect caption for any platform.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _HeroCTA(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _goToCreate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppGradients.brand.createShader(bounds),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text(
              'Create Caption',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToCreate(BuildContext context) {
    ShellNavigator.of(context)?.switchTab(1);
  }
}

class _QuickCreateCards extends StatelessWidget {
  const _QuickCreateCards({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickCard(
            gradient: AppGradients.accent2,
            icon: Icons.image_rounded,
            title: 'Caption from\nImage',
            subtitle: 'Gallery or Camera',
            isDark: isDark,
            onTap: () => _navigateCreate(context),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickCard(
            gradient: AppGradients.accent3,
            icon: Icons.auto_fix_high_rounded,
            title: 'Quick\nGenerate',
            subtitle: 'AI-powered content',
            isDark: isDark,
            onTap: () => _navigateCreate(context),
          ),
        ),
      ],
    );
  }

  void _navigateCreate(BuildContext context) {
    ShellNavigator.of(context)?.switchTab(1);
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: AppShadows.subtle(isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textDark,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecentCard extends StatelessWidget {
  const _EmptyRecentCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 40,
            color: AppColors.brandPurple.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your creations will appear here ✨',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Create your first AI-powered caption to get started.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecentItemCard extends StatelessWidget {
  const _RecentItemCard({
    required this.record,
    required this.isDark,
    required this.onTap,
  });
  final CaptionRecord record;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(record.timestamp);

    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: AppShadows.subtle(isDark),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AppRadius.xl),
            ),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.file(
                File(record.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.brandPurple.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.image_rounded,
                    color: AppColors.brandPurple.withValues(alpha: 0.4),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.tag_rounded,
                        size: 12,
                        color: AppColors.brandPurple,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${record.hashtags.length} hashtags',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '·',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white30 : AppColors.lightBorder,
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
