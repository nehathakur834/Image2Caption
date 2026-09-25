import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/caption_record.dart';
import '../providers/caption_provider.dart';
import '../theme/theme.dart';
import '../widgets/app_components.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptionProvider>();
    final history = provider.history;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          if (history.isEmpty)
            SliverFillRemaining(
              child: EmptyStateWidget(
                title: 'Nothing here yet ✨',
                description:
                    'Create your first AI-powered caption and it will appear here.',
                icon: Icons.photo_library_outlined,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final record = history[index];
                    return _HistoryGridCard(
                      record: record,
                      isDark: isDark,
                      onTap: () => _openDetail(context, provider, record),
                      onDelete: () => _delete(context, provider, record),
                    );
                  },
                  childCount: history.length,
                ),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Creations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(
            'Your AI-generated content collection.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
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

  void _openDetail(
    BuildContext context,
    CaptionProvider provider,
    CaptionRecord record,
  ) {
    provider.reuseCaption(record);
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

  void _delete(
    BuildContext context,
    CaptionProvider provider,
    CaptionRecord record,
  ) {
    provider.deleteCaption(record);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted from history')),
    );
  }
}

class _HistoryGridCard extends StatelessWidget {
  const _HistoryGridCard({
    required this.record,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final CaptionRecord record;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.file(
                  File(record.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.brandPurple.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.image_rounded,
                      color: AppColors.brandPurple.withValues(alpha: 0.4),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppGradients.brand,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: isDark ? Colors.white30 : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        record.caption,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: isDark ? const Color(0xFFE0E0E0) : AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(record.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
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
