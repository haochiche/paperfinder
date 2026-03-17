import 'package:flutter/foundation.dart';

import '../models/paper_models.dart';
import '../repositories/local_store.dart';
import '../repositories/openalex_repository.dart';
import '../repositories/zotero_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    required OpenAlexRepository openAlexRepository,
    required ZoteroRepository zoteroRepository,
    required LocalStore localStore,
  })  : _openAlexRepository = openAlexRepository,
        _zoteroRepository = zoteroRepository,
        _localStore = localStore;

  final OpenAlexRepository _openAlexRepository;
  final ZoteroRepository _zoteroRepository;
  final LocalStore _localStore;

  int selectedTabIndex = 0;
  bool isInitializing = true;
  bool isSearching = false;
  bool isSavingPaper = false;
  bool isLoadingCollections = false;
  String? errorMessage;

  SearchRequest lastSearch = const SearchRequest(keywords: '', pageSize: 20);
  List<SearchRequest> searchHistory = const [];
  List<PaperSummary> discoveryQueue = const [];
  String? nextCursor;
  final Set<String> skippedPaperIds = <String>{};
  List<SavedPaperRecord> savedPapers = const [];
  ZoteroConfig zoteroConfig = const ZoteroConfig(
    apiKey: '',
    userOrLibraryId: '',
    libraryType: 'user',
  );
  List<ZoteroCollection> collections = const [];

  Future<void> initialize() async {
    isInitializing = true;
    notifyListeners();
    try {
      savedPapers = await _localStore.loadSavedPapers();
      searchHistory = await _localStore.loadSearchHistory();
      lastSearch = await _localStore.loadLastSearch() ?? lastSearch;
      zoteroConfig = await _localStore.loadZoteroConfig() ?? zoteroConfig;
      if (zoteroConfig.isComplete) {
        await loadCollections(silent: true);
      }
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void setTabIndex(int index) {
    selectedTabIndex = index;
    notifyListeners();
  }

  Future<void> search(SearchRequest request) async {
    if (request.keywords.trim().isEmpty) {
      errorMessage = 'Enter at least one keyword to search.';
      notifyListeners();
      return;
    }

    isSearching = true;
    errorMessage = null;
    skippedPaperIds.clear();
    notifyListeners();

    try {
      final response = await _openAlexRepository.searchWorks(request.copyWith(clearCursor: true));
      final savedIds = savedPapers.map((record) => record.paper.openAlexId).toSet();
      discoveryQueue = response.papers.where((paper) => !savedIds.contains(paper.openAlexId)).toList();
      nextCursor = response.nextCursor;
      lastSearch = request.copyWith(clearCursor: true);
      await _localStore.saveLastSearch(lastSearch);

      searchHistory = [
        lastSearch,
        ...searchHistory.where((item) => item.keywords != lastSearch.keywords),
      ].take(8).toList();
      await _localStore.saveSearchHistory(searchHistory);
      selectedTabIndex = 1;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isSearching || nextCursor == null || nextCursor!.isEmpty || lastSearch.keywords.isEmpty) {
      return;
    }

    isSearching = true;
    notifyListeners();
    try {
      final response = await _openAlexRepository.searchWorks(lastSearch.copyWith(pageCursor: nextCursor));
      final knownIds = {
        ...discoveryQueue.map((paper) => paper.openAlexId),
        ...savedPapers.map((record) => record.paper.openAlexId),
        ...skippedPaperIds,
      };
      final newItems = response.papers.where((paper) => !knownIds.contains(paper.openAlexId));
      discoveryQueue = [...discoveryQueue, ...newItems];
      nextCursor = response.nextCursor;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  Future<List<SourceRef>> lookupSources(String query) async {
    return _openAlexRepository.autocompleteSources(query);
  }

  Future<void> skipTopPaper() async {
    if (discoveryQueue.isEmpty) {
      return;
    }
    final paper = discoveryQueue.first;
    skippedPaperIds.add(paper.openAlexId);
    discoveryQueue = discoveryQueue.skip(1).toList();
    notifyListeners();
  }

  Future<void> saveTopPaper() async {
    if (discoveryQueue.isEmpty) {
      return;
    }
    await savePaper(discoveryQueue.first, removeFromQueue: true);
  }

  Future<void> savePaper(PaperSummary paper, {bool removeFromQueue = false}) async {
    if (savedPapers.any((record) => record.paper.openAlexId == paper.openAlexId)) {
      if (removeFromQueue) {
        discoveryQueue = discoveryQueue.where((item) => item.openAlexId != paper.openAlexId).toList();
      }
      notifyListeners();
      return;
    }

    isSavingPaper = true;
    errorMessage = null;
    notifyListeners();

    SavedPaperRecord record;
    try {
      if (!zoteroConfig.isComplete || zoteroConfig.defaultCollectionId == null) {
        throw const ZoteroException('Add Zotero credentials and choose a collection before saving.');
      }
      await _zoteroRepository.savePaper(config: zoteroConfig, paper: paper);
      record = SavedPaperRecord(
        paper: paper,
        status: SaveSyncStatus.synced,
        savedAt: DateTime.now(),
      );
    } catch (error) {
      record = SavedPaperRecord(
        paper: paper,
        status: SaveSyncStatus.failed,
        savedAt: DateTime.now(),
        errorMessage: error.toString(),
      );
      errorMessage = error.toString();
    }

    savedPapers = [record, ...savedPapers];
    await _localStore.saveSavedPapers(savedPapers);
    if (removeFromQueue) {
      discoveryQueue = discoveryQueue.skip(1).toList();
      selectedTabIndex = 1;
    }
    isSavingPaper = false;
    notifyListeners();
  }

  Future<void> retrySave(SavedPaperRecord record) async {
    savedPapers = savedPapers.where((item) => item.paper.openAlexId != record.paper.openAlexId).toList();
    await _localStore.saveSavedPapers(savedPapers);
    await savePaper(record.paper);
  }

  Future<void> updateZoteroConfig(ZoteroConfig config) async {
    zoteroConfig = config;
    await _localStore.saveZoteroConfig(zoteroConfig);
    notifyListeners();
  }

  Future<void> loadCollections({bool silent = false}) async {
    if (!zoteroConfig.isComplete) {
      errorMessage = 'Enter Zotero API credentials first.';
      notifyListeners();
      return;
    }

    if (!silent) {
      isLoadingCollections = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      collections = await _zoteroRepository.fetchCollections(zoteroConfig);
      if (zoteroConfig.defaultCollectionId != null &&
          collections.every((item) => item.id != zoteroConfig.defaultCollectionId)) {
        zoteroConfig = zoteroConfig.copyWith(clearCollection: true);
        await _localStore.saveZoteroConfig(zoteroConfig);
      }
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoadingCollections = false;
      notifyListeners();
    }
  }
}

