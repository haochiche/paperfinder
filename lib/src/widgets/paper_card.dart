import 'package:flutter/material.dart';

import '../models/paper_models.dart';

class PaperCard extends StatefulWidget {
  const PaperCard({
    required this.paper,
    this.isPreview = false,
    super.key,
  });

  final PaperSummary paper;
  final bool isPreview;

  @override
  State<PaperCard> createState() => _PaperCardState();
}

class _PaperCardState extends State<PaperCard> {
  void _openAbstractReader(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Abstract',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.paper.hasAbstract
                      ? 'Abstract source: ${widget.paper.abstractSource}'
                      : 'No abstract source found',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      widget.paper.abstract.isEmpty
                          ? 'OpenAlex and Crossref do not provide an abstract for this work.'
                          : widget.paper.abstract,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.65),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paper = widget.paper;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      [
                        if (paper.journal?.isNotEmpty == true) paper.journal!,
                        if (paper.year != null) '${paper.year}',
                        if (paper.citationCount != null) '${paper.citationCount} citations',
                      ].join(' • '),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    paper.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    paper.authors.isEmpty ? 'Unknown authors' : paper.authors.join(', '),
                    maxLines: widget.isPreview ? 2 : null,
                    overflow: widget.isPreview ? TextOverflow.ellipsis : TextOverflow.visible,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Abstract',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 120),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.66),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      paper.abstract.isEmpty
                          ? 'OpenAlex and Crossref do not provide an abstract for this work.'
                          : paper.abstract,
                      maxLines: widget.isPreview ? 4 : 8,
                      overflow: TextOverflow.fade,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                  if (!widget.isPreview) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openAbstractReader(context),
                        icon: const Icon(Icons.open_in_full),
                        label: Text(paper.abstract.isEmpty ? 'Details' : 'Read full abstract'),
                      ),
                    ),
                  ],
                  if (paper.doi?.isNotEmpty == true && !widget.isPreview)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SelectableText('DOI: ${paper.doi}'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
