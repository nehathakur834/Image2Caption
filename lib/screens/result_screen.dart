import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/caption_record.dart';
import '../providers/caption_provider.dart';

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
    final caption =
        context.read<CaptionProvider>().currentRecord?.caption ?? '';
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
    final theme = Theme.of(context);

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
      appBar: AppBar(
        title: const Text('Generated Result'),
        actions: [
          IconButton(
            tooltip: record.isFavorite ? 'Remove favorite' : 'Add favorite',
            onPressed: () => provider.toggleFavorite(record),
            icon: Icon(
              record.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.file(
                    File(record.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, size: 40),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (record.tone != null)
                            Chip(
                              avatar: Icon(record.tone!.icon, size: 18),
                              label: Text(record.tone!.label),
                            ),
                          if (record.platform != null)
                            Chip(
                              avatar: Icon(record.platform!.icon, size: 18),
                              label: Text(record.platform!.label),
                            ),
                          Chip(
                            avatar: Icon(record.language.icon, size: 18),
                            label: Text(record.language.label),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'AI Image Analysis',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result.analysis.summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ...result.analysis.objects.map(
                            (item) => Chip(label: Text(item)),
                          ),
                          Chip(label: Text('Mood: ${result.analysis.mood}')),
                          Chip(
                            label: Text('Context: ${result.analysis.context}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caption Suggestions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(result.suggestions.length, (index) {
                    final suggestion = result.suggestions[index];
                    final isSelected =
                        provider.selectedSuggestionIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == result.suggestions.length - 1 ? 0 : 12,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => provider.selectSuggestion(index),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: isSelected ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                foregroundColor: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                                child: Text('${index + 1}'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  suggestion.caption,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editable Caption',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    minLines: 4,
                    maxLines: 6,
                    onChanged: provider.updateCurrentCaption,
                    decoration: const InputDecoration(
                      hintText: 'Adjust the generated caption here',
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Smart Hashtag Groups',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _copyHashtags(record.hashtags),
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...result.groupedHashtags.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: entry.value
                                .map((tag) => Chip(label: Text(tag)))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => _copyCaption(_controller.text),
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Copy Caption'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _copyHashtags(record.hashtags),
                icon: const Icon(Icons.tag_rounded),
                label: const Text('Copy Hashtags'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _share(record, _controller.text),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share'),
              ),
              OutlinedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => _regenerate(provider),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: const Text('Regenerate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyCaption(String caption) async {
    await Clipboard.setData(ClipboardData(text: caption));
  }

  Future<void> _copyHashtags(List<String> hashtags) async {
    await Clipboard.setData(ClipboardData(text: hashtags.join(' ')));
  }

  Future<void> _share(CaptionRecord record, String caption) async {
    final content = '$caption\n\n${record.hashtags.join(' ')}';
    await SharePlus.instance.share(ShareParams(text: content));
  }

  Future<void> _regenerate(CaptionProvider provider) async {
    await provider.regenerateCaption();
    final updated = provider.currentRecord;
    if (updated == null) {
      return;
    }

    _controller.text = updated.caption;
  }
}
