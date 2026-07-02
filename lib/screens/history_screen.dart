import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/caption_provider.dart';
import '../widgets/caption_history_tile.dart';
import '../widgets/empty_state_card.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptionProvider>();
    final history = provider.history;

    return SafeArea(
      child: history.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: EmptyStateCard(
                title: 'No saved captions yet',
                description:
                    'Generate your first caption to build a reusable history library with image previews.',
                icon: Icons.history_toggle_off_rounded,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final record = history[index];
                return CaptionHistoryTile(
                  record: record,
                  onDelete: () => provider.deleteCaption(record),
                  onFavorite: () => provider.toggleFavorite(record),
                  onReuse: () async {
                    provider.reuseCaption(record);
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ResultScreen(),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
