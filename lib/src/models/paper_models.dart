import 'dart:convert';

enum RankingStrategy { metadataOnly, semanticRerank }

enum SaveSyncStatus { synced, failed }

enum SwipeAction { save, skip }

class SourceRef {
  const SourceRef({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
      };

  factory SourceRef.fromJson(Map<String, dynamic> json) => SourceRef(
        id: json['id'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
      );
}

class SearchRequest {
  const SearchRequest({
    required this.keywords,
    required this.pageSize,
    this.intentSentence,
    this.yearStart,
    this.yearEnd,
    this.journalFilters = const [],
    this.pageCursor,
    this.rankingStrategy = RankingStrategy.metadataOnly,
  });

  final String keywords;
  final String? intentSentence;
  final int? yearStart;
  final int? yearEnd;
  final List<SourceRef> journalFilters;
  final int pageSize;
  final String? pageCursor;
  final RankingStrategy rankingStrategy;

  SearchRequest copyWith({
    String? keywords,
    String? intentSentence,
    int? yearStart,
    int? yearEnd,
    List<SourceRef>? journalFilters,
    int? pageSize,
    String? pageCursor,
    RankingStrategy? rankingStrategy,
    bool clearCursor = false,
  }) {
    return SearchRequest(
      keywords: keywords ?? this.keywords,
      intentSentence: intentSentence ?? this.intentSentence,
      yearStart: yearStart ?? this.yearStart,
      yearEnd: yearEnd ?? this.yearEnd,
      journalFilters: journalFilters ?? this.journalFilters,
      pageSize: pageSize ?? this.pageSize,
      pageCursor: clearCursor ? null : pageCursor ?? this.pageCursor,
      rankingStrategy: rankingStrategy ?? this.rankingStrategy,
    );
  }

  Map<String, dynamic> toJson() => {
        'keywords': keywords,
        'intentSentence': intentSentence,
        'yearStart': yearStart,
        'yearEnd': yearEnd,
        'journalFilters': journalFilters.map((source) => source.toJson()).toList(),
        'pageSize': pageSize,
        'pageCursor': pageCursor,
        'rankingStrategy': rankingStrategy.name,
      };

  factory SearchRequest.fromJson(Map<String, dynamic> json) => SearchRequest(
        keywords: json['keywords'] as String? ?? '',
        intentSentence: json['intentSentence'] as String?,
        yearStart: json['yearStart'] as int?,
        yearEnd: json['yearEnd'] as int?,
        journalFilters: (json['journalFilters'] as List<dynamic>? ?? [])
            .map((item) => SourceRef.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        pageSize: json['pageSize'] as int? ?? 20,
        pageCursor: json['pageCursor'] as String?,
        rankingStrategy: RankingStrategy.values.firstWhere(
          (value) => value.name == json['rankingStrategy'],
          orElse: () => RankingStrategy.metadataOnly,
        ),
      );
}

class PaperSummary {
  const PaperSummary({
    required this.openAlexId,
    required this.title,
    required this.abstract,
    required this.authors,
    this.year,
    this.journal,
    this.doi,
    this.landingPageUrl,
    this.semanticScholarUrl,
    this.pdfUrl,
    this.citationCount,
    this.abstractSource = 'OpenAlex',
  });

  final String openAlexId;
  final String title;
  final String abstract;
  final List<String> authors;
  final int? year;
  final String? journal;
  final String? doi;
  final String? landingPageUrl;
  final String? semanticScholarUrl;
  final String? pdfUrl;
  final int? citationCount;
  final String abstractSource;

  bool get hasLongAbstract => abstract.length > 420;
  bool get hasAbstract => abstract.trim().isNotEmpty;
  String? get preferredReadUrl => pdfUrl ?? landingPageUrl ?? semanticScholarUrl;

  PaperSummary copyWith({
    String? openAlexId,
    String? title,
    String? abstract,
    List<String>? authors,
    int? year,
    String? journal,
    String? doi,
    String? landingPageUrl,
    String? semanticScholarUrl,
    String? pdfUrl,
    int? citationCount,
    String? abstractSource,
  }) {
    return PaperSummary(
      openAlexId: openAlexId ?? this.openAlexId,
      title: title ?? this.title,
      abstract: abstract ?? this.abstract,
      authors: authors ?? this.authors,
      year: year ?? this.year,
      journal: journal ?? this.journal,
      doi: doi ?? this.doi,
      landingPageUrl: landingPageUrl ?? this.landingPageUrl,
      semanticScholarUrl: semanticScholarUrl ?? this.semanticScholarUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      citationCount: citationCount ?? this.citationCount,
      abstractSource: abstractSource ?? this.abstractSource,
    );
  }

  Map<String, dynamic> toJson() => {
        'openAlexId': openAlexId,
        'title': title,
        'abstract': abstract,
        'authors': authors,
        'year': year,
        'journal': journal,
        'doi': doi,
        'landingPageUrl': landingPageUrl,
        'semanticScholarUrl': semanticScholarUrl,
        'pdfUrl': pdfUrl,
        'citationCount': citationCount,
        'abstractSource': abstractSource,
      };

  factory PaperSummary.fromJson(Map<String, dynamic> json) => PaperSummary(
        openAlexId: json['openAlexId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        abstract: json['abstract'] as String? ?? '',
        authors: (json['authors'] as List<dynamic>? ?? []).cast<String>(),
        year: json['year'] as int?,
        journal: json['journal'] as String?,
        doi: json['doi'] as String?,
        landingPageUrl: json['landingPageUrl'] as String?,
        semanticScholarUrl: json['semanticScholarUrl'] as String?,
        pdfUrl: json['pdfUrl'] as String?,
        citationCount: json['citationCount'] as int?,
        abstractSource: json['abstractSource'] as String? ?? 'OpenAlex',
      );
}

class SwipeDecision {
  const SwipeDecision({
    required this.paperId,
    required this.action,
    required this.timestamp,
  });

  final String paperId;
  final SwipeAction action;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'paperId': paperId,
        'action': action.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SwipeDecision.fromJson(Map<String, dynamic> json) => SwipeDecision(
        paperId: json['paperId'] as String? ?? '',
        action: SwipeAction.values.firstWhere(
          (value) => value.name == json['action'],
          orElse: () => SwipeAction.skip,
        ),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

class ZoteroConfig {
  const ZoteroConfig({
    required this.apiKey,
    required this.userOrLibraryId,
    required this.libraryType,
    this.defaultCollectionId,
  });

  final String apiKey;
  final String userOrLibraryId;
  final String libraryType;
  final String? defaultCollectionId;

  bool get isComplete => apiKey.isNotEmpty && userOrLibraryId.isNotEmpty;

  ZoteroConfig copyWith({
    String? apiKey,
    String? userOrLibraryId,
    String? libraryType,
    String? defaultCollectionId,
    bool clearCollection = false,
  }) {
    return ZoteroConfig(
      apiKey: apiKey ?? this.apiKey,
      userOrLibraryId: userOrLibraryId ?? this.userOrLibraryId,
      libraryType: libraryType ?? this.libraryType,
      defaultCollectionId: clearCollection ? null : defaultCollectionId ?? this.defaultCollectionId,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'userOrLibraryId': userOrLibraryId,
        'libraryType': libraryType,
        'defaultCollectionId': defaultCollectionId,
      };

  factory ZoteroConfig.fromJson(Map<String, dynamic> json) => ZoteroConfig(
        apiKey: json['apiKey'] as String? ?? '',
        userOrLibraryId: json['userOrLibraryId'] as String? ?? '',
        libraryType: json['libraryType'] as String? ?? 'user',
        defaultCollectionId: json['defaultCollectionId'] as String?,
      );
}

class ZoteroCollection {
  const ZoteroCollection({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory ZoteroCollection.fromJson(Map<String, dynamic> json) => ZoteroCollection(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

class SavedPaperRecord {
  const SavedPaperRecord({
    required this.paper,
    required this.status,
    required this.savedAt,
    this.errorMessage,
  });

  final PaperSummary paper;
  final SaveSyncStatus status;
  final DateTime savedAt;
  final String? errorMessage;

  SavedPaperRecord copyWith({
    PaperSummary? paper,
    SaveSyncStatus? status,
    DateTime? savedAt,
    String? errorMessage,
  }) {
    return SavedPaperRecord(
      paper: paper ?? this.paper,
      status: status ?? this.status,
      savedAt: savedAt ?? this.savedAt,
      errorMessage: errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'paper': paper.toJson(),
        'status': status.name,
        'savedAt': savedAt.toIso8601String(),
        'errorMessage': errorMessage,
      };

  factory SavedPaperRecord.fromJson(Map<String, dynamic> json) => SavedPaperRecord(
        paper: PaperSummary.fromJson(Map<String, dynamic>.from(json['paper'] as Map)),
        status: SaveSyncStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => SaveSyncStatus.synced,
        ),
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
        errorMessage: json['errorMessage'] as String?,
      );
}

class SearchResponse {
  const SearchResponse({
    required this.papers,
    this.nextCursor,
  });

  final List<PaperSummary> papers;
  final String? nextCursor;
}

String encodeJsonList(List<Map<String, dynamic>> data) => jsonEncode(data);
