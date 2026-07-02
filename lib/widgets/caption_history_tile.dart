import 'dart:io';

import 'package:flutter/material.dart';

import '../models/caption_record.dart';

class CaptionHistoryTile extends StatelessWidget {
  const CaptionHistoryTile({
    super.key,
    required this.record,
    required this.onDelete,
    required this.onFavorite,
    required this.onReuse,
  });

  final CaptionRecord record;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;
  final VoidCallback onReuse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 8,
            child: Image.file(
              File(record.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 42),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (record.platform != null)
                            Chip(label: Text(record.platform!.label)),
                          if (record.tone != null)
                            Chip(label: Text(record.tone!.label)),
                          Chip(label: Text(record.language.label)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onFavorite,
                      icon: Icon(
                        record.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  record.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  record.hashtags.join(' '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: onReuse,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Reuse'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
