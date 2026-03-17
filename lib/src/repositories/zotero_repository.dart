import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/paper_models.dart';

class ZoteroRepository {
  ZoteroRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://api.zotero.org';

  Future<List<ZoteroCollection>> fetchCollections(ZoteroConfig config) async {
    final uri = Uri.parse(
      '$_baseUrl/${config.libraryType}s/${config.userOrLibraryId}/collections',
    );
    final response = await _client.get(uri, headers: _headers(config));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ZoteroException('Invalid Zotero credentials.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ZoteroException('Unable to load collections (${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(
          (json) => ZoteroCollection(
            id: json['key'] as String? ?? '',
            name: (json['data'] as Map<String, dynamic>? ?? const {})['name'] as String? ?? '',
          ),
        )
        .where((collection) => collection.id.isNotEmpty && collection.name.isNotEmpty)
        .toList();
  }

  Future<void> savePaper({
    required ZoteroConfig config,
    required PaperSummary paper,
  }) async {
    final template = await _fetchJournalArticleTemplate(config);
    final collectionId = config.defaultCollectionId;
    final item = {
      ...template,
      'title': paper.title,
      'abstractNote': paper.abstract,
      'publicationTitle': paper.journal ?? '',
      'date': paper.year?.toString() ?? '',
      'DOI': paper.doi ?? '',
      'url': paper.landingPageUrl ?? '',
      'collections': collectionId == null ? <String>[] : <String>[collectionId],
      'creators': paper.authors
          .map(
            (name) => {
              'creatorType': 'author',
              ..._splitName(name),
            },
          )
          .toList(),
      'extra': 'Imported from OpenAlex (${paper.openAlexId})\nCitations: ${paper.citationCount ?? 0}',
    };

    final uri = Uri.parse('$_baseUrl/${config.libraryType}s/${config.userOrLibraryId}/items');
    final response = await _client.post(
      uri,
      headers: {
        ..._headers(config),
        'Content-Type': 'application/json',
        'Zotero-Write-Token': _writeToken(),
      },
      body: jsonEncode([item]),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ZoteroException('Zotero rejected the provided API key.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ZoteroException('Failed to save paper to Zotero (${response.statusCode}).');
    }
  }

  Future<Map<String, dynamic>> _fetchJournalArticleTemplate(ZoteroConfig config) async {
    final uri = Uri.parse('$_baseUrl/items/new').replace(queryParameters: {'itemType': 'journalArticle'});
    final response = await _client.get(uri, headers: _headers(config));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ZoteroException('Unable to fetch Zotero item template (${response.statusCode}).');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Map<String, String> _headers(ZoteroConfig config) => {
        'Zotero-API-Version': '3',
        'Zotero-API-Key': config.apiKey,
      };

  String _writeToken() {
    final random = Random.secure();
    final values = List<int>.generate(12, (_) => random.nextInt(255));
    return base64UrlEncode(values);
  }

  Map<String, String> _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return {
        'name': fullName,
      };
    }
    return {
      'firstName': parts.sublist(0, parts.length - 1).join(' '),
      'lastName': parts.last,
    };
  }
}

class ZoteroException implements Exception {
  const ZoteroException(this.message);

  final String message;

  @override
  String toString() => message;
}
