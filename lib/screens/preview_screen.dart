import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/caption_record.dart';
import '../providers/caption_provider.dart';
import '../widgets/selection_chip_group.dart';
import 'result_screen.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptionProvider>();
    final imagePath = provider.selectedImagePath;
    final theme = Theme.of(context);
    final errorMessage = provider.errorMessage;

    if (imagePath == null) {
      return const Scaffold(body: Center(child: Text('No image selected.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Preview & Generate')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 5,
                      child: Image.file(File(imagePath), fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.08,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.visibility_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'OpenAI will analyze the selected image and generate captions plus hashtags based on the image content, platform, and language.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!provider.hasConfiguredApiKey) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: theme.colorScheme.errorContainer,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.key_off_rounded,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'API key not configured. Start the app with --dart-define=OPENAI_API_KEY=your_key.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onErrorContainer,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: theme.colorScheme.errorContainer,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      errorMessage,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onErrorContainer,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Text(
                            'Caption Tone',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Optional: leave this unselected and the AI will decide the tone from the image.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ChoiceChip(
                                selected: provider.selectedTone == null,
                                label: const Text('Auto'),
                                avatar: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                ),
                                onSelected: (_) => provider.setTone(null),
                              ),
                              ...CaptionTone.values.map(
                                (tone) => ChoiceChip(
                                  selected: provider.selectedTone == tone,
                                  label: Text(tone.label),
                                  avatar: Icon(tone.icon, size: 18),
                                  onSelected: (_) => provider.setTone(tone),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Platform',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SelectionChipGroup<SocialPlatform>(
                            values: SocialPlatform.values,
                            selectedValue: provider.selectedPlatform,
                            labelBuilder: (platform) => platform.label,
                            iconBuilder: (platform) => platform.icon,
                            onSelected: (platform) =>
                                provider.setPlatform(platform),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Language',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SelectionChipGroup<AppLanguage>(
                            values: AppLanguage.values,
                            selectedValue: provider.selectedLanguage,
                            labelBuilder: (language) => language.label,
                            iconBuilder: (language) => language.icon,
                            onSelected: provider.setLanguage,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: provider.isLoading
                                ? null
                                : () => _generate(context),
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('Generate Caption'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (provider.isLoading)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing image and generating captions...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generate(BuildContext context) async {
    final provider = context.read<CaptionProvider>();
    await provider.generateCaption();

    if (!context.mounted || provider.currentRecord == null) {
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ResultScreen()));
  }
}
