import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/paper_models.dart';

class LocalStore {
  static const String _savedPapersKey = 'saved_papers';
  static const String _searchHistoryKey = 'search_history';
  static const String _lastSearchKey = 'last_search';
  static const String _zoteroConfigKey = 'zotero_config';
  static const String _skippedPaperIdsKey = 'skipped_paper_ids';
  static const String _legacyMigratedKey = 'legacy_migrated';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) {
      return _database!;
    }

    final databasePath = p.join(await getDatabasesPath(), 'paperfinder.db');
    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE paper_decisions(
            paper_id TEXT PRIMARY KEY,
            decision TEXT NOT NULL,
            saved_record_json TEXT,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE search_history(
            request_key TEXT PRIMARY KEY,
            request_json TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE metadata(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
    await _migrateLegacyData(_database!);
    return _database!;
  }

  Future<void> _migrateLegacyData(Database db) async {
    final migrated = await db.query(
      'metadata',
      where: 'key = ?',
      whereArgs: [_legacyMigratedKey],
      limit: 1,
    );
    if (migrated.isNotEmpty) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();

    final savedRaw = preferences.getString(_savedPapersKey);
    if (savedRaw != null && savedRaw.isNotEmpty) {
      final items = jsonDecode(savedRaw) as List<dynamic>;
      final records = items
          .map((item) => SavedPaperRecord.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      for (final record in records) {
        await db.insert(
          'paper_decisions',
          {
            'paper_id': record.paper.openAlexId,
            'decision': record.status.name,
            'saved_record_json': jsonEncode(record.toJson()),
            'updated_at': record.savedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    final skippedIds = preferences.getStringList(_skippedPaperIdsKey) ?? const <String>[];
    for (final paperId in skippedIds) {
      await db.insert(
        'paper_decisions',
        {
          'paper_id': paperId,
          'decision': SwipeAction.skip.name,
          'saved_record_json': null,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final historyRaw = preferences.getString(_searchHistoryKey);
    if (historyRaw != null && historyRaw.isNotEmpty) {
      final items = jsonDecode(historyRaw) as List<dynamic>;
      for (final item in items) {
        final request = SearchRequest.fromJson(Map<String, dynamic>.from(item as Map));
        await db.insert(
          'search_history',
          {
            'request_key': _requestKey(request),
            'request_json': jsonEncode(request.toJson()),
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    final lastSearchRaw = preferences.getString(_lastSearchKey);
    if (lastSearchRaw != null && lastSearchRaw.isNotEmpty) {
      await db.insert(
        'metadata',
        {
          'key': _lastSearchKey,
          'value': lastSearchRaw,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await db.insert(
      'metadata',
      {
        'key': _legacyMigratedKey,
        'value': 'true',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _requestKey(SearchRequest request) => jsonEncode(request.toJson());

  Future<List<SavedPaperRecord>> loadSavedPapers() async {
    final db = await _db;
    final rows = await db.query(
      'paper_decisions',
      columns: ['saved_record_json'],
      where: 'decision IN (?, ?)',
      whereArgs: [SaveSyncStatus.synced.name, SaveSyncStatus.failed.name],
      orderBy: 'updated_at DESC',
    );
    return rows
        .map((row) => row['saved_record_json'] as String?)
        .whereType<String>()
        .map((item) => SavedPaperRecord.fromJson(Map<String, dynamic>.from(jsonDecode(item) as Map)))
        .toList();
  }

  Future<void> saveSavedPapers(List<SavedPaperRecord> records) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'paper_decisions',
        where: 'decision IN (?, ?)',
        whereArgs: [SaveSyncStatus.synced.name, SaveSyncStatus.failed.name],
      );
      for (final record in records) {
        await txn.insert(
          'paper_decisions',
          {
            'paper_id': record.paper.openAlexId,
            'decision': record.status.name,
            'saved_record_json': jsonEncode(record.toJson()),
            'updated_at': record.savedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<SearchRequest>> loadSearchHistory() async {
    final db = await _db;
    final rows = await db.query(
      'search_history',
      columns: ['request_json'],
      orderBy: 'updated_at DESC',
      limit: 8,
    );
    return rows
        .map((row) => row['request_json'] as String)
        .map((item) => SearchRequest.fromJson(Map<String, dynamic>.from(jsonDecode(item) as Map)))
        .toList();
  }

  Future<void> saveSearchHistory(List<SearchRequest> history) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('search_history');
      for (final request in history) {
        await txn.insert(
          'search_history',
          {
            'request_key': _requestKey(request),
            'request_json': jsonEncode(request.toJson()),
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<SearchRequest?> loadLastSearch() async {
    final db = await _db;
    final rows = await db.query(
      'metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_lastSearchKey],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['value'] == null || (rows.first['value'] as String).isEmpty) {
      return null;
    }
    return SearchRequest.fromJson(
      Map<String, dynamic>.from(jsonDecode(rows.first['value'] as String) as Map),
    );
  }

  Future<void> saveLastSearch(SearchRequest request) async {
    final db = await _db;
    await db.insert(
      'metadata',
      {
        'key': _lastSearchKey,
        'value': jsonEncode(request.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Set<String>> loadSkippedPaperIds() async {
    final db = await _db;
    final rows = await db.query(
      'paper_decisions',
      columns: ['paper_id'],
      where: 'decision = ?',
      whereArgs: [SwipeAction.skip.name],
    );
    return rows.map((row) => row['paper_id'] as String).toSet();
  }

  Future<void> saveSkippedPaperIds(Set<String> paperIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'paper_decisions',
        where: 'decision = ?',
        whereArgs: [SwipeAction.skip.name],
      );
      for (final paperId in paperIds) {
        await txn.insert(
          'paper_decisions',
          {
            'paper_id': paperId,
            'decision': SwipeAction.skip.name,
            'saved_record_json': null,
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
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
