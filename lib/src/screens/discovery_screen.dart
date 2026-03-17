import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/paper_card.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final papers = controller.discoveryQueue;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discovery deck',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Swipe left to skip or right to save.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: papers.isEmpty
                ? _EmptyDiscoveryState(
                    isLoading: controller.isSearching,
                    onLoadMore: controller.loadMore,
                    hasPreviousSearch: controller.lastSearch.keywords.isNotEmpty,
                  )
                : Stack(
                    children: [
                      if (papers.length > 1)
                        Positioned.fill(
                          top: 16,
                          child: Transform.scale(
                            scale: 0.97,
                            child: Opacity(
                              opacity: 0.75,
                              child: PaperCard(
                                paper: papers[1],
                                isPreview: true,
                              ),
                            ),
                          ),
                        ),
                      Dismissible(
                        key: ValueKey(papers.first.openAlexId),
                        direction: DismissDirection.horizontal,
                        onDismissed: (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            controller.saveTopPaper();
                          } else {
                            controller.skipTopPaper();
                          }
                        },
                        background: const _SwipeBackdrop(
                          alignment: Alignment.centerLeft,
                          color: Color(0xFF355B3D),
                          icon: Icons.bookmark_add,
                          label: 'Save',
                        ),
                        secondaryBackground: const _SwipeBackdrop(
                          alignment: Alignment.centerRight,
                          color: Color(0xFFB56A45),
                          icon: Icons.skip_next,
                          label: 'Skip',
                        ),
                        child: PaperCard(paper: papers.first),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: papers.isEmpty ? null : controller.skipTopPaper,
                  icon: const Icon(Icons.close),
                  label: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: papers.isEmpty || controller.isSavingPaper ? null : controller.saveTopPaper,
                  icon: controller.isSavingPaper
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bookmark_add),
                  label: const Text('Save to Zotero'),
                ),
              ),
            ],
          ),
          if (controller.nextCursor != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: controller.isSearching ? null : controller.loadMore,
                child: const Text('Load more papers'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SwipeBackdrop extends StatelessWidget {
  const _SwipeBackdrop({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Row(
        mainAxisAlignment:
            alignment == Alignment.centerLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyDiscoveryState extends StatelessWidget {
  const _EmptyDiscoveryState({
    required this.isLoading,
    required this.onLoadMore,
    required this.hasPreviousSearch,
  });

  final bool isLoading;
  final Future<void> Function() onLoadMore;
  final bool hasPreviousSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded, size: 42),
          ),
          const SizedBox(height: 18),
          Text(
            hasPreviousSearch ? 'No papers left in this deck.' : 'Run a search to fill your deck.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (hasPreviousSearch)
            FilledButton.tonal(
              onPressed: isLoading ? null : onLoadMore,
              child: const Text('Try loading more'),
            ),
        ],
      ),
    );
  }
}

