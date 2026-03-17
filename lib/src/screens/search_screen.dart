import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/paper_models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _keywordsController;
  late final TextEditingController _intentController;
  late final TextEditingController _sourceLookupController;
  late final TextEditingController _yearStartController;
  late final TextEditingController _yearEndController;
  List<SourceRef> _selectedSources = const [];
  List<SourceRef> _sourceSuggestions = const [];
  bool _isLoadingSources = false;

  @override
  void initState() {
    super.initState();
    final lastSearch = widget.controller.lastSearch;
    _keywordsController = TextEditingController(text: lastSearch.keywords);
    _intentController = TextEditingController(text: lastSearch.intentSentence ?? '');
    _sourceLookupController = TextEditingController();
    _yearStartController = TextEditingController(text: lastSearch.yearStart?.toString() ?? '');
    _yearEndController = TextEditingController(text: lastSearch.yearEnd?.toString() ?? '');
    _selectedSources = List<SourceRef>.from(lastSearch.journalFilters);
  }

  @override
  void dispose() {
    _keywordsController.dispose();
    _intentController.dispose();
    _sourceLookupController.dispose();
    _yearStartController.dispose();
    _yearEndController.dispose();
    super.dispose();
  }

  Future<void> _lookupSources(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _sourceSuggestions = const [];
      });
      return;
    }

    setState(() {
      _isLoadingSources = true;
    });
    List<SourceRef> results = const [];
    try {
      results = await widget.controller.lookupSources(query);
    } catch (_) {
      results = const [];
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _sourceSuggestions = results
          .where((item) => _selectedSources.every((selected) => selected.id != item.id))
          .toList();
      _isLoadingSources = false;
    });
  }

  Future<void> _submitSearch() async {
    final request = SearchRequest(
      keywords: _keywordsController.text.trim(),
      intentSentence: _intentController.text.trim().isEmpty ? null : _intentController.text.trim(),
      yearStart: int.tryParse(_yearStartController.text.trim()),
      yearEnd: int.tryParse(_yearEndController.text.trim()),
      journalFilters: _selectedSources,
      pageSize: 50,
    );

    await widget.controller.search(request);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Find your next paper',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Search OpenAlex, triage fast, and send the keepers to Zotero.',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _keywordsController,
                decoration: const InputDecoration(
                  labelText: 'Keywords',
                  hintText: 'e.g. graph neural networks for molecules',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _intentController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Intent sentence',
                  hintText: 'Optional future semantic reranking input',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _yearStartController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year start'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _yearEndController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year end'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sourceLookupController,
                      onChanged: _lookupSources,
                      decoration: const InputDecoration(
                        labelText: 'Journal/source',
                        hintText: 'Search OpenAlex sources',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: _isLoadingSources
                        ? null
                        : () => _lookupSources(_sourceLookupController.text),
                    icon: _isLoadingSources
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.travel_explore),
                    label: const Text('Find'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final source in _selectedSources)
                    InputChip(
                      label: Text(source.displayName),
                      onDeleted: () {
                        setState(() {
                          _selectedSources =
                              _selectedSources.where((item) => item.id != source.id).toList();
                        });
                      },
                    ),
                ],
              ),
              if (_sourceSuggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Suggested journals',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sourceSuggestions
                      .take(8)
                      .map(
                        (source) => ActionChip(
                          label: Text(source.displayName),
                          onPressed: () {
                            setState(() {
                              _selectedSources = [..._selectedSources, source];
                              _sourceSuggestions =
                                  _sourceSuggestions.where((item) => item.id != source.id).toList();
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.controller.isSearching ? null : _submitSearch,
                  icon: widget.controller.isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Search papers'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent searches',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (widget.controller.searchHistory.isEmpty)
                Text(
                  'Your recent searches will appear here.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                ...widget.controller.searchHistory.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.keywords),
                    subtitle: Text(
                      [
                        if (entry.yearStart != null || entry.yearEnd != null)
                          '${entry.yearStart ?? 'Any'} - ${entry.yearEnd ?? 'Any'}',
                        if (entry.journalFilters.isNotEmpty)
                          '${entry.journalFilters.length} journal filter(s)',
                      ].join(' • '),
                    ),
                    trailing: const Icon(Icons.north_west),
                    onTap: () {
                      setState(() {
                        _keywordsController.text = entry.keywords;
                        _intentController.text = entry.intentSentence ?? '';
                        _yearStartController.text = entry.yearStart?.toString() ?? '';
                        _yearEndController.text = entry.yearEnd?.toString() ?? '';
                        _selectedSources = List<SourceRef>.from(entry.journalFilters);
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}
