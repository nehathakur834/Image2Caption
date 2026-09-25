import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/caption_record.dart';
import '../providers/caption_provider.dart';
import '../theme/theme.dart';
import '../widgets/app_components.dart';
import '../widgets/app_gradient_button.dart';
import '../widgets/loading_ai_widget.dart';
import 'result_screen.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context, isDark),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppSpacing.lg),
                    if (provider.selectedImagePath == null)
                      _UploadCard(isDark: isDark)
                    else
                      _ImagePreviewCard(
                        imagePath: provider.selectedImagePath!,
                        isDark: isDark,
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    if (!provider.hasConfiguredApiKey)
                      _InfoBanner(
                        icon: Icons.key_off_rounded,
                        message:
                            'API key not configured. Start with --dart-define=OPENAI_API_KEY=your_key.',
                        isError: true,
                        isDark: isDark,
                      ),
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _InfoBanner(
                        icon: Icons.error_outline_rounded,
                        message: provider.errorMessage!,
                        isError: true,
                        isDark: isDark,
                      ),
                    ],
                    if (provider.selectedImagePath != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _OptionsCard(provider: provider, isDark: isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _GenerateButton(provider: provider),
                    ],
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

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      title: const Text('Create Caption'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CaptionProvider>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.brandPurple.withValues(alpha: 0.4),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        color: AppColors.brandPurple.withValues(alpha: isDark ? 0.08 : 0.04),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
                boxShadow: AppShadows.button,
              ),
              child: const Icon(Icons.add_photo_alternate_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Upload your image',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose from gallery or capture with camera',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    gradient: AppGradients.accent2,
                    onTap: () => _pickImage(context, provider, ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_camera_rounded,
                    label: 'Camera',
                    gradient: AppGradients.accent1,
                    onTap: () => _pickImage(context, provider, ImageSource.camera),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    CaptionProvider provider,
    ImageSource source,
  ) async {
    await provider.pickImage(source);
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.button,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({required this.imagePath, required this.isDark});
  final String imagePath;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CaptionProvider>();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(File(imagePath), fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Image ready',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _replaceImage(context, provider),
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    color: isDark ? Colors.white60 : AppColors.textMuted,
                  ),
                  tooltip: 'Replace image',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _replaceImage(
    BuildContext context,
    CaptionProvider provider,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _ImageSourceSheet(),
    );
    if (source == null) return;
    await provider.pickImage(source);
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.provider, required this.isDark});
  final CaptionProvider provider;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Caption Tone', subtitle: 'Leave on Auto to let AI decide'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PremiumChip(
                label: 'Auto',
                icon: Icons.auto_awesome_rounded,
                selected: provider.selectedTone == null,
                onTap: () => provider.setTone(null),
                isDark: isDark,
              ),
              ...CaptionTone.values.map(
                (tone) => _PremiumChip(
                  label: tone.label,
                  icon: tone.icon,
                  selected: provider.selectedTone == tone,
                  onTap: () => provider.setTone(tone),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Platform'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SocialPlatform.values.map(
              (platform) => _PremiumChip(
                label: platform.label,
                icon: platform.icon,
                selected: provider.selectedPlatform == platform,
                onTap: () => provider.setPlatform(platform),
                isDark: isDark,
              ),
            ).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Language'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppLanguage.values.map(
              (lang) => _PremiumChip(
                label: lang.label,
                icon: lang.icon,
                selected: provider.selectedLanguage == lang,
                onTap: () => provider.setLanguage(lang),
                isDark: isDark,
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }
}

class _PremiumChip extends StatelessWidget {
  const _PremiumChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.brand : null,
          color: selected
              ? null
              : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
          boxShadow: selected ? AppShadows.button : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textMuted),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.provider});
  final CaptionProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Ready to create? ✨',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        AppGradientButton(
          label: 'Generate Captions',
          icon: Icons.auto_awesome_rounded,
          isLoading: provider.isLoading,
          onPressed: provider.isLoading ? null : () => _generate(context),
        ),
      ],
    );
  }

  Future<void> _generate(BuildContext context) async {
    final provider = context.read<CaptionProvider>();
    await provider.generateCaption();

    if (!context.mounted || provider.currentRecord == null) return;

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: const ResultScreen(),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.isError,
    required this.isDark,
  });

  final IconData icon;
  final String message;
  final bool isError;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? color.withValues(alpha: 0.9) : color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                'Choose image source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
            _SheetTile(
              icon: Icons.photo_library_rounded,
              title: 'Gallery',
              subtitle: 'Choose an existing photo',
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SheetTile(
              icon: Icons.photo_camera_rounded,
              title: 'Camera',
              subtitle: 'Capture something new',
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
