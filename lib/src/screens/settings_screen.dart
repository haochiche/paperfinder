import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/paper_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _userIdController;
  late final TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _userIdController = TextEditingController(text: widget.controller.zoteroConfig.userOrLibraryId);
    _apiKeyController = TextEditingController(text: widget.controller.zoteroConfig.apiKey);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final config = widget.controller.zoteroConfig.copyWith(
          apiKey: _apiKeyController.text.trim(),
          userOrLibraryId: _userIdController.text.trim(),
          libraryType: 'user',
        );
    await widget.controller.updateZoteroConfig(config);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Zotero settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Your API key stays in secure storage on-device. Pick a collection once and every save will route there.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _userIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Zotero user id',
                    hintText: 'Numeric user/library id',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Zotero API key',
                    hintText: 'Private key from Zotero settings',
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Save credentials'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: controller.isLoadingCollections
                            ? null
                            : () async {
                                await _saveSettings();
                                await controller.loadCollections();
                              },
                        icon: controller.isLoadingCollections
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync),
                        label: const Text('Load collections'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default save collection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (controller.collections.isEmpty)
                  const Text('Load your collections to choose a Zotero target.')
                else
                  DropdownButtonFormField<String>(
                    initialValue: controller.collections.any(
                      (collection) => collection.id == controller.zoteroConfig.defaultCollectionId,
                    )
                        ? controller.zoteroConfig.defaultCollectionId
                        : null,
                    items: controller.collections
                        .map(
                          (collection) => DropdownMenuItem<String>(
                            value: collection.id,
                            child: Text(collection.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      controller.updateZoteroConfig(
                        controller.zoteroConfig.copyWith(defaultCollectionId: value),
                      );
                    },
                    decoration: const InputDecoration(labelText: 'Collection'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: SwitchListTile(
            value: controller.lastSearch.rankingStrategy == RankingStrategy.semanticRerank,
            onChanged: null,
            title: const Text('Semantic reranking'),
            subtitle: const Text('Reserved for phase 2. v1 stays metadata-only.'),
          ),
        ),
      ],
    );
  }
}
