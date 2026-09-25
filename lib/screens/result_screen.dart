import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/caption_record.dart';
import '../models/caption_result.dart';
import '../providers/caption_provider.dart';
import '../theme/theme.dart';
import '../widgets/app_components.dart';
import '../widgets/app_gradient_button.dart';
import '../widgets/loading_ai_widget.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final caption = context.read<CaptionProvider>().currentRecord?.caption ?? '';
    _controller = TextEditingController(text: caption);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptionProvider>();
    final record = provider.currentRecord;
    final result = provider.currentResult;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (record == null || result == null) {
      return const Scaffold(
        body: Center(child: Text('No caption generated yet.')),
      );
    }

    if (_controller.text != record.caption) {
      _controller.value = _controller.value.copyWith(
        text: record.caption,
        selection: TextSelection.collapsed(offset: record.caption.length),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context, isDark, provider, record),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppSpacing.lg),
                    // Image hero
                    _ImageHero(record: record, isDark: isDark),
                    const SizedBox(height: AppSpacing.xl),
                    // Analysis
                    _AnalysisSection(result: result, isDark: isDark),
                    const SizedBox(height: AppSpacing.xl),
                    // Caption suggestions
                    _CaptionSuggestionsSection(
                      provider: provider,
                      result: result,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Hashtags
                    _HashtagsSection(
                      record: record,
                      result: result,
                      isDark: isDark,
                      onCopyAll: () => _copyHashtags(context, record.hashtags),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Editable caption
                    _EditableCaptionSection(
                      controller: _controller,
                      provider: provider,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Actions
                    _ActionButtons(
                      controller: _controller,
                      record: record,
                      provider: provider,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Regenerate
                    _RegenerateSection(
                      provider: provider,
                      onRegenerate: () => _regenerate(context, provider),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          if (provider.isLoading) const LoadingAIWidget(),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    bool isDark,
    CaptionProvider provider,
    CaptionRecord record,
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Captions ✨',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(
            'AI-generated ideas for your post.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: record.isFavorite ? 'Remove favorite' : 'Add favorite',
          onPressed: () => provider.toggleFavorite(record),
          icon: ShaderMask(
            shaderCallback: (b) => AppGradients.brand.createShader(b),
            child: Icon(
              record.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
    );
  }

  Future<void> _copyHashtags(
      BuildContext context, List<String> hashtags) async {
    await Clipboard.setData(ClipboardData(text: hashtags.join(' ')));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hashtags copied ✓')),
      );
    }
  }

  Future<void> _regenerate(
      BuildContext context, CaptionProvider provider) async {
    await provider.regenerateCaption();
    final updated = provider.currentRecord;
    if (updated == null) return;
    _controller.text = updated.caption;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New captions generated ✨')),
      );
    }
  }
}

class _ImageHero extends StatelessWidget {
  const _ImageHero({required this.record, required this.isDark});
  final CaptionRecord record;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.cardRadius,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.file(
          File(record.imagePath),
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
    );
  }
}

class _AnalysisSection extends StatelessWidget {
  const _AnalysisSection({required this.result, required this.isDark});
  final CaptionResult result;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final objects = result.analysis.objects;
    final mood = result.analysis.mood;
    final summary = result.analysis.summary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppGradients.accent2,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.search_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'AI Image Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            summary,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...objects.map(
                (item) => _SmallChip(
                    label: item.toString(), isDark: isDark),
              ),
              _SmallChip(label: 'Mood: $mood', isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white60 : AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CaptionSuggestionsSection extends StatelessWidget {
  const _CaptionSuggestionsSection({
    required this.provider,
    required this.result,
    required this.isDark,
  });
  final CaptionProvider provider;
  final CaptionResult result;
  final bool isDark;

  static final List<LinearGradient> _accents = [
    AppGradients.accent1,
    AppGradients.accent2,
    AppGradients.accent3,
  ];

  @override
  Widget build(BuildContext context) {
    final suggestions = result.suggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Caption Suggestions'),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(suggestions.length, (i) {
          final suggestion = suggestions[i];
          final selected = provider.selectedSuggestionIndex == i;
          final accent = _accents[i % _accents.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GestureDetector(
              onTap: () => provider.selectSuggestion(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(
                    color: selected
                        ? AppColors.brandPurple
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected ? AppShadows.button : AppShadows.subtle(isDark),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: selected ? accent : null,
                          color: selected
                              ? null
                              : (isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.lightSurfaceVariant),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(
                          child: Text(
                            '0${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? Colors.white
                                  : (isDark ? Colors.white54 : AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                            suggestion.caption,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? Colors.white : AppColors.textDark,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (selected)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: Icon(Icons.check_circle_rounded,
                              color: AppColors.brandPurple, size: 20),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _HashtagsSection extends StatelessWidget {
  const _HashtagsSection({
    required this.record,
    required this.result,
    required this.isDark,
    required this.onCopyAll,
  });

  final CaptionRecord record;
  final CaptionResult result;
  final bool isDark;
  final VoidCallback onCopyAll;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Trending Hashtags',
            trailing: TextButton.icon(
              onPressed: onCopyAll,
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text('Copy All'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Group view
          ...result.groupedHashtags.entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white60 : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: entry.value
                              .map((tag) => HashtagChip(tag: tag))
                              .toList(),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }
}

class _EditableCaptionSection extends StatelessWidget {
  const _EditableCaptionSection({
    required this.controller,
    required this.provider,
    required this.isDark,
  });

  final TextEditingController controller;
  final CaptionProvider provider;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Edit Caption',
            subtitle: 'Fine-tune the AI suggestion',
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            onChanged: provider.updateCurrentCaption,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
            decoration: const InputDecoration(
              hintText: 'Adjust the generated caption here…',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.controller,
    required this.record,
    required this.provider,
    required this.isDark,
  });

  final TextEditingController controller;
  final CaptionRecord record;
  final CaptionProvider provider;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: Icons.copy_all_rounded,
            label: 'Copy',
            gradient: AppGradients.accent1,
            onTap: () async {
              await Clipboard.setData(
                  ClipboardData(text: controller.text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caption copied ✓')),
                );
              }
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionChip(
            icon: Icons.tag_rounded,
            label: 'Hashtags',
            gradient: AppGradients.accent2,
            onTap: () async {
              await Clipboard.setData(
                  ClipboardData(text: record.hashtags.join(' ')));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hashtags copied ✓')),
                );
              }
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionChip(
            icon: Icons.share_rounded,
            label: 'Share',
            gradient: AppGradients.accent3,
            onTap: () async {
              final content =
                  '${controller.text}\n\n${record.hashtags.join(' ')}';
              await SharePlus.instance.share(ShareParams(text: content));
            },
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegenerateSection extends StatelessWidget {
  const _RegenerateSection({
    required this.provider,
    required this.onRegenerate,
  });

  final CaptionProvider provider;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          'Not feeling it?',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white54 : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppGradientButton(
          label: '✨ Generate Again',
          isLoading: provider.isLoading,
          onPressed: provider.isLoading ? null : onRegenerate,
          gradient: AppGradients.brand,
        ),
      ],
    );
  }
}
