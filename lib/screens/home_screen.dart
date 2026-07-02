import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/caption_record.dart';
import '../providers/caption_provider.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/image_source_sheet.dart';
import 'preview_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptionProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recentFavorites = provider.favorites.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.16),
            theme.scaffoldBackgroundColor,
            colorScheme.tertiary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Caption Generator App',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Turn a photo into a polished caption, hashtags, and a share-ready post in a few taps.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Toggle theme',
                  onPressed: provider.toggleTheme,
                  icon: const Icon(Icons.dark_mode_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.tertiary],
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Start with a fresh image',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Pick from your camera or gallery, choose the platform, and let OpenAI analyze the image before writing the caption.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _showPickerSheet(context),
                      icon: const Icon(Icons.add_a_photo_rounded),
                      label: const Text('Pick an Image'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (recentFavorites.isEmpty)
              const EmptyStateCard(
                title: 'No favorites yet',
                description:
                    'Mark saved captions as favorites to keep your best performers close by.',
                icon: Icons.favorite_border_rounded,
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favorite Captions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...recentFavorites.map(
                        (record) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: const Icon(Icons.favorite_rounded),
                          ),
                          title: Text(
                            record.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              if (record.platform != null)
                                record.platform!.label,
                              if (record.tone != null) record.tone!.label,
                              record.language.label,
                            ].join(' • '),
                          ),
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

  Future<void> _showPickerSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (_) => const ImageSourceSheet(),
    );

    if (source == null || !context.mounted) {
      return;
    }

    final provider = context.read<CaptionProvider>();
    final didPick = await provider.pickImage(source);
    if (!didPick || !context.mounted) {
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PreviewScreen()));
  }
}
