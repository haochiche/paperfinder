import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/paper_models.dart';

class LocalStore {
  static const String _savedPapersKey = 'saved_papers';
  static const String _searchHistoryKey = 'search_history';
  static const String _lastSearchKey = 'last_search';
  static const String _zoteroConfigKey = 'zotero_config';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<List<SavedPaperRecord>> loadSavedPapers() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_savedPapersKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final items = jsonDecode(raw) as List<dynamic>;
    return items
        .map((item) => SavedPaperRecord.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveSavedPapers(List<SavedPaperRecord> records) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _savedPapersKey,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }

  Future<List<SearchRequest>> loadSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_searchHistoryKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final items = jsonDecode(raw) as List<dynamic>;
    return items
        .map((item) => SearchRequest.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveSearchHistory(List<SearchRequest> history) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _searchHistoryKey,
      jsonEncode(history.map((request) => request.toJson()).toList()),
    );
  }

  Future<SearchRequest?> loadLastSearch() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_lastSearchKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return SearchRequest.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> saveLastSearch(SearchRequest request) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastSearchKey, jsonEncode(request.toJson()));
  }

  Future<ZoteroConfig?> loadZoteroConfig() async {
    final raw = await _secureStorage.read(key: _zoteroConfigKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return ZoteroConfig.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> saveZoteroConfig(ZoteroConfig config) async {
    await _secureStorage.write(key: _zoteroConfigKey, value: jsonEncode(config.toJson()));
  }
}

