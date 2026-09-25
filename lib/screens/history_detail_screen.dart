import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/caption_record.dart';
import '../providers/caption_provider.dart';
import '../theme/theme.dart';
import '../widgets/app_components.dart';
import '../widgets/app_gradient_button.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.record});

  final CaptionRecord record;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRecord = provider.currentRecord ?? record;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark, provider, currentRecord),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.lg),
                // Large image
                ClipRRect(
                  borderRadius: AppRadius.cardRadius,
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.file(
                      File(currentRecord.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Metadata chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (currentRecord.tone != null)
                      _MetaChip(
                        icon: currentRecord.tone!.icon,
                        label: currentRecord.tone!.label,
                        isDark: isDark,
                      ),
                    if (currentRecord.platform != null)
                      _MetaChip(
                        icon: currentRecord.platform!.icon,
                        label: currentRecord.platform!.label,
                        isDark: isDark,
                      ),
                    _MetaChip(
                      icon: currentRecord.language.icon,
                      label: currentRecord.language.label,
                      isDark: isDark,
                    ),
                    _MetaChip(
                      icon: Icons.schedule_rounded,
                      label: _formatDate(currentRecord.timestamp),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                // Caption
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: 'Caption'),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        currentRecord.caption,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Hashtags
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: 'Hashtags'),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: currentRecord.hashtags
                            .map((tag) => HashtagChip(tag: tag))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Actions
                _ActionRow(record: currentRecord, isDark: isDark),
                const SizedBox(height: AppSpacing.xl),
                // Delete
                OutlinedButton.icon(
                  onPressed: () => _delete(context, provider, currentRecord),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete from History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(double.infinity, 50),
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
    CaptionRecord rec,
  ) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: isDark ? Colors.white : AppColors.textDark,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Caption Detail',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      actions: [
        IconButton(
          tooltip: rec.isFavorite ? 'Remove favorite' : 'Add to favorites',
          onPressed: () => provider.toggleFavorite(rec),
          icon: ShaderMask(
            shaderCallback: (b) => AppGradients.brand.createShader(b),
            child: Icon(
              rec.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    CaptionProvider provider,
    CaptionRecord rec,
  ) async {
    await provider.deleteCaption(rec);
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted from history')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandPurple),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.record, required this.isDark});

  final CaptionRecord record;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppGradientButton(
            label: 'Copy Caption',
            icon: Icons.copy_all_rounded,
            gradient: AppGradients.accent1,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: record.caption));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caption copied ✓')),
                );
              }
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _SmallActionButton(
          icon: Icons.tag_rounded,
          gradient: AppGradients.accent2,
          tooltip: 'Copy Hashtags',
          onTap: () async {
            await Clipboard.setData(
              ClipboardData(text: record.hashtags.join(' ')),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hashtags copied ✓')),
              );
            }
          },
        ),
        const SizedBox(width: AppSpacing.sm),
        _SmallActionButton(
          icon: Icons.share_rounded,
          gradient: AppGradients.accent3,
          tooltip: 'Share',
          onTap: () async {
            final content =
                '${record.caption}\n\n${record.hashtags.join(' ')}';
            await SharePlus.instance.share(ShareParams(text: content));
          },
        ),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.icon,
    required this.gradient,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Gradient gradient;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
