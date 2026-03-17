import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/paper_models.dart';

class OpenAlexRepository {
  OpenAlexRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://api.openalex.org';

  Future<SearchResponse> searchWorks(SearchRequest request) async {
    final queryParameters = <String, String>{
      'search': request.keywords.trim(),
      'per-page': request.pageSize.toString(),
      'select':
          'id,display_name,publication_year,authorships,abstract_inverted_index,primary_location,doi,cited_by_count,ids',
    };

    final filters = <String>[];
    if (request.yearStart != null) {
      filters.add('from_publication_date:${request.yearStart}-01-01');
    }
    if (request.yearEnd != null) {
      filters.add('to_publication_date:${request.yearEnd}-12-31');
    }
    if (request.journalFilters.isNotEmpty) {
      final sourceIds = request.journalFilters.map((source) => source.id).join('|');
      filters.add('primary_location.source.id:$sourceIds');
    }
    if (filters.isNotEmpty) {
      queryParameters['filter'] = filters.join(',');
    }
    if (request.pageCursor != null && request.pageCursor!.isNotEmpty) {
      queryParameters['cursor'] = request.pageCursor!;
    }

    final uri = Uri.parse('$_baseUrl/works').replace(queryParameters: queryParameters);
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenAlexException('OpenAlex search failed (${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (payload['results'] as List<dynamic>? ?? [])
        .map((item) => _paperFromOpenAlex(Map<String, dynamic>.from(item as Map)))
        .where((paper) => paper.title.isNotEmpty)
        .toList();
    final enrichedResults = await _hydrateMissingAbstracts(results);

    final meta = Map<String, dynamic>.from(payload['meta'] as Map? ?? {});
    return SearchResponse(
      papers: enrichedResults,
      nextCursor: meta['next_cursor'] as String?,
    );
  }

  Future<List<SourceRef>> autocompleteSources(String query) async {
    if (query.trim().isEmpty) {
      return const [];
    }

    final uri = Uri.parse('$_baseUrl/autocomplete/sources').replace(
      queryParameters: {
        'q': query.trim(),
      },
    );
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenAlexException('Source lookup failed (${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = payload['results'] as List<dynamic>? ?? [];
    return results
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(
          (json) => SourceRef(
            id: json['id'] as String? ?? '',
            displayName: json['display_name'] as String? ?? '',
          ),
        )
        .where((source) => source.id.isNotEmpty && source.displayName.isNotEmpty)
        .toList();
  }

  PaperSummary _paperFromOpenAlex(Map<String, dynamic> json) {
    final authorships = json['authorships'] as List<dynamic>? ?? [];
    final primaryLocation = Map<String, dynamic>.from(json['primary_location'] as Map? ?? {});
    final source = Map<String, dynamic>.from(primaryLocation['source'] as Map? ?? {});
    final ids = Map<String, dynamic>.from(json['ids'] as Map? ?? {});

    return PaperSummary(
      openAlexId: json['id'] as String? ?? '',
      title: json['display_name'] as String? ?? '',
      abstract: decodeAbstractInvertedIndex(
        Map<String, dynamic>.from(json['abstract_inverted_index'] as Map? ?? {}),
      ),
      authors: authorships
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .map((entry) => Map<String, dynamic>.from(entry['author'] as Map? ?? {}))
          .map((author) => author['display_name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
      year: json['publication_year'] as int?,
      journal: source['display_name'] as String?,
      doi: _normalizeDoi(json['doi'] as String? ?? ids['doi'] as String?),
      landingPageUrl: primaryLocation['landing_page_url'] as String?,
      citationCount: json['cited_by_count'] as int?,
      abstractSource: 'OpenAlex',
    );
  }

  Future<List<PaperSummary>> _hydrateMissingAbstracts(List<PaperSummary> papers) async {
    final hydrated = List<PaperSummary>.from(papers);
    final missingIndexes = <int>[
      for (var i = 0; i < hydrated.length; i++)
        if (!hydrated[i].hasAbstract) i,
    ];

    const int batchSize = 8;
    for (var start = 0; start < missingIndexes.length; start += batchSize) {
      final batch = missingIndexes.skip(start).take(batchSize);
      await Future.wait(
        batch.map((index) async {
          final doi = hydrated[index].doi;
          if (doi != null && doi.isNotEmpty) {
            final crossrefAbstract = await _fetchCrossrefAbstract(doi);
            if (crossrefAbstract != null && crossrefAbstract.isNotEmpty) {
              hydrated[index] = hydrated[index].copyWith(
                abstract: crossrefAbstract,
                abstractSource: 'Crossref',
              );
              return;
            }
          }

          final semanticScholarPaper = await _fetchSemanticScholarPaper(hydrated[index]);
          if (semanticScholarPaper != null) {
            hydrated[index] = semanticScholarPaper;
          }
        }),
      );
    }

    return hydrated;
  }

  Future<String?> _fetchCrossrefAbstract(String doi) async {
    try {
      final uri = Uri.https('api.crossref.org', '/works/${Uri.encodeComponent(doi)}');
      final response = await _client.get(
        uri,
        headers: const {
          'User-Agent': 'paperfinder/0.1',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final message = Map<String, dynamic>.from(payload['message'] as Map? ?? {});
      final rawAbstract = message['abstract'] as String?;
      if (rawAbstract == null || rawAbstract.isEmpty) {
        return null;
      }
      return _cleanCrossrefAbstract(rawAbstract);
    } catch (_) {
      return null;
    }
  }

  Future<PaperSummary?> _fetchSemanticScholarPaper(PaperSummary paper) async {
    try {
      final identifier = paper.doi != null && paper.doi!.isNotEmpty
          ? 'DOI:${paper.doi}'
          : Uri.encodeComponent(paper.title);
      final path = paper.doi != null && paper.doi!.isNotEmpty
          ? '/graph/v1/paper/$identifier'
          : '/graph/v1/paper/search/match';
      final queryParameters = paper.doi != null && paper.doi!.isNotEmpty
          ? {
              'fields': 'abstract,url,openAccessPdf,title',
            }
          : {
              'query': paper.title,
              'fields': 'abstract,url,openAccessPdf,title',
            };

      final uri = Uri.https('api.semanticscholar.org', path, queryParameters);
      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final resolved = paper.doi != null && paper.doi!.isNotEmpty
          ? payload
          : Map<String, dynamic>.from(payload['data'] as Map? ?? {});
      final recoveredAbstract = (resolved['abstract'] as String? ?? '').trim();
      final semanticUrl = resolved['url'] as String?;
      final openAccessPdf = Map<String, dynamic>.from(resolved['openAccessPdf'] as Map? ?? {});
      final pdfUrl = openAccessPdf['url'] as String?;

      if (recoveredAbstract.isEmpty && semanticUrl == null && pdfUrl == null) {
        return null;
      }

      return paper.copyWith(
        abstract: recoveredAbstract.isEmpty ? paper.abstract : recoveredAbstract,
        abstractSource: recoveredAbstract.isEmpty ? paper.abstractSource : 'Semantic Scholar',
        semanticScholarUrl: semanticUrl ?? paper.semanticScholarUrl,
        pdfUrl: pdfUrl ?? paper.pdfUrl,
      );
    } catch (_) {
      return null;
    }
  }

  static String _cleanCrossrefAbstract(String rawAbstract) {
    final withoutTags = rawAbstract.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return withoutTags
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String decodeAbstractInvertedIndex(Map<String, dynamic> index) {
    if (index.isEmpty) {
      return '';
    }

    final placements = <int, String>{};
    for (final entry in index.entries) {
      final positions = (entry.value as List<dynamic>? ?? []).cast<int>();
      for (final position in positions) {
        placements[position] = entry.key;
      }
    }

    final orderedPositions = placements.keys.toList()..sort();
    return orderedPositions.map((position) => placements[position]).join(' ').trim();
  }

  static String? _normalizeDoi(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw.replaceFirst('https://doi.org/', '');
  }
}

class OpenAlexException implements Exception {
  const OpenAlexException(this.message);

  final String message;

  @override
  String toString() => message;
}
