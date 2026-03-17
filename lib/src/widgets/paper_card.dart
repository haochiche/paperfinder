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
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final paper = widget.paper;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(22),
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
              maxLines: widget.isPreview ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 18),
            Text(
              'Abstract',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.66),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SingleChildScrollView(
                  physics: _expanded
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: Text(
                    paper.abstract.isEmpty ? 'No abstract available for this record.' : paper.abstract,
                    maxLines: _expanded ? null : 8,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.fade,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ),
              ),
            ),
            if (paper.hasLongAbstract && !widget.isPreview) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  label: Text(_expanded ? 'Collapse abstract' : 'Expand abstract'),
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
  }
}
