import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/paper_models.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final saved = controller.savedPapers;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Saved papers',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Your triaged papers stay cached locally, including failed Zotero syncs.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        if (saved.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Nothing saved yet. Swipe right on a paper to add it here.'),
            ),
          )
        else
          ...saved.map((record) => _SavedPaperTile(controller: controller, record: record)),
      ],
    );
  }
}

class _SavedPaperTile extends StatelessWidget {
  const _SavedPaperTile({
    required this.controller,
    required this.record,
  });

  final AppController controller;
  final SavedPaperRecord record;

  @override
  Widget build(BuildContext context) {
    final paper = record.paper;
    final isFailed = record.status == SaveSyncStatus.failed;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    paper.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  avatar: Icon(
                    isFailed ? Icons.sync_problem : Icons.cloud_done,
                    size: 16,
                  ),
                  label: Text(isFailed ? 'Save failed' : 'Saved to Zotero'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              [
                if (paper.authors.isNotEmpty) paper.authors.take(4).join(', '),
                if (paper.journal?.isNotEmpty == true) paper.journal!,
                if (paper.year != null) '${paper.year}',
              ].join(' • '),
            ),
            if (paper.abstract.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                paper.abstract,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (isFailed) ...[
              const SizedBox(height: 12),
              Text(
                record.errorMessage ?? 'Unknown Zotero error.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => controller.retrySave(record),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry save'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

