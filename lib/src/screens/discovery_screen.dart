import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/paper_models.dart';
import '../widgets/paper_card.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  Offset _dragOffset = Offset.zero;

  AppController get controller => widget.controller;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    final width = MediaQuery.of(context).size.width;
    final threshold = width * 0.28;

    if (_dragOffset.dx > threshold) {
      setState(() => _dragOffset = Offset.zero);
      await controller.saveTopPaper();
      return;
    }
    if (_dragOffset.dx < -threshold) {
      setState(() => _dragOffset = Offset.zero);
      await controller.skipTopPaper();
      return;
    }

    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final papers = controller.discoveryQueue;
    final dragProgress = (_dragOffset.dx.abs() / 120).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.showResultsList ? 'Search results' : 'Discovery deck',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            controller.showResultsList
                ? 'Browse the result list first, then open any paper into the swipe deck.'
                : 'Swipe left to skip or right to save.',
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
                : controller.showResultsList
                    ? _ResultsList(
                        papers: papers,
                        onOpenPaper: (paperId) {
                          controller.openPaperDeck(paperId);
                          setState(() {
                            _dragOffset = Offset.zero;
                          });
                        },
                      )
                    : Stack(
                        children: [
                          if (papers.length > 1)
                            Positioned.fill(
                              top: 14 + (12 * (1 - dragProgress)),
                              child: Transform.scale(
                                scale: 0.95 + (0.03 * dragProgress),
                                child: Opacity(
                                  opacity: 0.68 + (0.12 * dragProgress),
                                  child: PaperCard(
                                    paper: papers[1],
                                    isPreview: true,
                                  ),
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: _SwipeBackdrop(
                              alignment: _dragOffset.dx >= 0 ? Alignment.centerLeft : Alignment.centerRight,
                              color: _dragOffset.dx >= 0 ? const Color(0xFF355B3D) : const Color(0xFFB56A45),
                              icon: _dragOffset.dx >= 0 ? Icons.bookmark_add : Icons.skip_next,
                              label: _dragOffset.dx >= 0 ? 'SAVE' : 'SKIP',
                              intensity: dragProgress,
                            ),
                          ),
                          Positioned.fill(
                            child: GestureDetector(
                              onPanUpdate: _handleDragUpdate,
                              onPanEnd: _handleDragEnd,
                              child: Transform.translate(
                                offset: _dragOffset,
                                child: Transform.rotate(
                                  angle: (_dragOffset.dx / 320) * (math.pi / 18),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: PaperCard(paper: papers.first),
                                      ),
                                      if (_dragOffset.dx.abs() > 18)
                                        Positioned(
                                          top: 28,
                                          left: _dragOffset.dx >= 0 ? 24 : null,
                                          right: _dragOffset.dx < 0 ? 24 : null,
                                          child: Transform.rotate(
                                            angle: _dragOffset.dx >= 0 ? -0.2 : 0.2,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: _dragOffset.dx >= 0
                                                      ? const Color(0xFF355B3D)
                                                      : const Color(0xFFB56A45),
                                                  width: 3,
                                                ),
                                                color: Colors.white.withValues(alpha: 0.82),
                                              ),
                                              child: Text(
                                                _dragOffset.dx >= 0 ? 'SAVE' : 'SKIP',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.4,
                                                  color: _dragOffset.dx >= 0
                                                      ? const Color(0xFF355B3D)
                                                      : const Color(0xFFB56A45),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
          const SizedBox(height: 16),
          if (!controller.showResultsList)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.showBrowseList,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to list'),
                  ),
                ),
                const SizedBox(width: 12),
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
                    label: const Text('Save'),
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
    this.intensity = 1,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18 + (0.25 * intensity)),
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
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.papers,
    required this.onOpenPaper,
  });

  final List<PaperSummary> papers;
  final ValueChanged<String> onOpenPaper;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: papers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final paper = papers[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => onOpenPaper(paper.openAlexId),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (paper.authors.isNotEmpty) paper.authors.take(3).join(', '),
                      if (paper.journal != null) paper.journal!,
                      if (paper.year != null) '${paper.year}',
                    ].join(' • '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    paper.abstract.isEmpty
                        ? 'Abstract unavailable from OpenAlex or Crossref for this paper.'
                        : paper.abstract,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paper.abstract.isEmpty
                        ? 'No abstract source found'
                        : 'Abstract source: ${paper.abstractSource}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => onOpenPaper(paper.openAlexId),
                        icon: const Icon(Icons.swipe),
                        label: const Text('Open cards'),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
