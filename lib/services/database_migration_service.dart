import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/company_profile.dart';
import 'database_service.dart';

class MigrationProgress {
  const MigrationProgress({
    required this.tableName,
    required this.tableIndex,
    required this.totalTables,
    required this.recordsInTable,
    required this.statusMessage,
    this.isComplete = false,
  });

  final String tableName;
  final int tableIndex;
  final int totalTables;
  final int recordsInTable;
  final String statusMessage;
  final bool isComplete;

  double get progressFraction => totalTables > 0 ? (tableIndex / totalTables).clamp(0.0, 1.0) : 0.0;
}

class MigrationResult {
  const MigrationResult({
    required this.companyId,
    required this.tableCounts,
    required this.totalRecords,
    required this.duration,
    required this.success,
    this.errorMessage,
    this.exportedJsonPath,
  });

  final String companyId;
  final Map<String, int> tableCounts;
  final int totalRecords;
  final Duration duration;
  final bool success;
  final String? errorMessage;
  final String? exportedJsonPath;

  Map<String, dynamic> toSummaryMap() => {
        'companyId': companyId,
        'totalRecords': totalRecords,
        'durationMs': duration.inMilliseconds,
        'success': success,
        'errorMessage': errorMessage,
        'tableCounts': tableCounts,
        'exportedJsonPath': exportedJsonPath,
      };
}

class DatabaseMigrationService {
  DatabaseMigrationService._();
  static final DatabaseMigrationService instance = DatabaseMigrationService._();

  static const List<String> allTables = [
    'categories',
    'products',
    'customers',
    'bills',
    'customer_loyalty',
    'loyalty_settings',
    'offers',
    'offer_tracking',
    'returns',
    'stock_movements',
  ];

  /// Query current record counts across all 10 SQLite tables
  Future<Map<String, int>> getLocalTableCounts(DatabaseService databaseService) async {
    final db = await databaseService.database;
    final Map<String, int> counts = {};
    for (final table in allTables) {
      try {
        final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM $table');
        counts[table] = (res.first['cnt'] as num?)?.toInt() ?? 0;
      } catch (e) {
        counts[table] = 0;
      }
    }
    return counts;
  }

  /// Extracts all existing records from all 10 SQLite tables as structured JSON-ready maps
  Future<Map<String, dynamic>> extractAllSqliteData({
    required DatabaseService databaseService,
    required String companyId,
    CompanyProfile? companyProfile,
  }) async {
    final db = await databaseService.database;
    final Map<String, dynamic> dump = {
      'schemaVersion': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'companyId': companyId,
      'companyProfile': companyProfile?.toMap() ?? {
        'id': companyId,
        'name': 'Ayesha Footwear',
      },
      'tables': <String, List<Map<String, dynamic>>>{},
    };

    final tablesMap = dump['tables'] as Map<String, List<Map<String, dynamic>>>;

    for (final table in allTables) {
      try {
        final rows = await db.query(table);
        tablesMap[table] = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      } catch (e) {
        tablesMap[table] = [];
      }
    }

    return dump;
  }

  /// Exports all records to a local JSON backup file on device storage
  Future<String> exportSqliteToJsonFile({
    required DatabaseService databaseService,
    required String companyId,
    CompanyProfile? companyProfile,
    String? targetDirectoryPath,
  }) async {
    final dump = await extractAllSqliteData(
      databaseService: databaseService,
      companyId: companyId,
      companyProfile: companyProfile,
    );

    final String baseDir;
    if (targetDirectoryPath != null && targetDirectoryPath.trim().isNotEmpty) {
      baseDir = targetDirectoryPath.trim();
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      baseDir = appDir.path;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanId = companyId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final filePath = p.join(baseDir, '${cleanId}_sqlite_migration_dump_$timestamp.json');

    final jsonStr = const JsonEncoder.withIndent('  ').convert(dump);
    final file = File(filePath);
    await file.writeAsString(jsonStr, flush: true);
    return file.path;
  }

  /// Performs full automatic migration from SQLite to Cloud Firestore
  /// Preserves all IDs, fields, relationships, and image references
  Future<MigrationResult> runMigrationToFirestore({
    required DatabaseService databaseService,
    required String companyId,
    CompanyProfile? companyProfile,
    FirebaseFirestore? firestore,
    bool autoExportJsonBackup = true,
    void Function(MigrationProgress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final cleanCompanyId = companyId.trim().isNotEmpty ? companyId.trim() : 'comp_ayesha_footwear';
    final targetFirestore = firestore ?? FirebaseFirestore.instance;

    String? jsonBackupPath;
    if (autoExportJsonBackup) {
      try {
        jsonBackupPath = await exportSqliteToJsonFile(
          databaseService: databaseService,
          companyId: cleanCompanyId,
          companyProfile: companyProfile,
        );
      } catch (e) {
        debugPrint('Backup export notice: $e');
      }
    }

    final db = await databaseService.database;
    final companyDoc = targetFirestore.collection('companies').doc(cleanCompanyId);

    // 1. Ensure Root Company document exists in Firestore
    if (companyProfile != null) {
      await companyDoc.set(companyProfile.toMap(), SetOptions(merge: true));
    } else {
      await companyDoc.set({
        'id': cleanCompanyId,
        'migratedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }

    final Map<String, int> tableCounts = {};
    int grandTotalRecords = 0;

    try {
      for (int i = 0; i < allTables.length; i++) {
        final table = allTables[i];
        final records = await db.query(table);
        final count = records.length;
        tableCounts[table] = count;
        grandTotalRecords += count;

        onProgress?.call(MigrationProgress(
          tableName: table,
          tableIndex: i + 1,
          totalTables: allTables.length,
          recordsInTable: count,
          statusMessage: 'Migrating $table ($count records) preserving IDs & relationships...',
        ));

        await _uploadTableRecords(
          table: table,
          records: records,
          companyDoc: companyDoc,
          targetFirestore: targetFirestore,
        );
      }

      stopwatch.stop();

      onProgress?.call(MigrationProgress(
        tableName: 'Complete',
        tableIndex: allTables.length,
        totalTables: allTables.length,
        recordsInTable: grandTotalRecords,
        statusMessage: 'Migration successful! $grandTotalRecords records uploaded to Firestore.',
        isComplete: true,
      ));

      return MigrationResult(
        companyId: cleanCompanyId,
        tableCounts: tableCounts,
        totalRecords: grandTotalRecords,
        duration: stopwatch.elapsed,
        success: true,
        exportedJsonPath: jsonBackupPath,
      );
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('Migration error: $e\n$st');
      return MigrationResult(
        companyId: cleanCompanyId,
        tableCounts: tableCounts,
        totalRecords: grandTotalRecords,
        duration: stopwatch.elapsed,
        success: false,
        errorMessage: e.toString(),
        exportedJsonPath: jsonBackupPath,
      );
    }
  }

  Future<void> _uploadTableRecords({
    required String table,
    required List<Map<String, dynamic>> records,
    required DocumentReference companyDoc,
    required FirebaseFirestore targetFirestore,
  }) async {
    if (records.isEmpty) return;

    // Special case for singleton config table
    if (table == 'loyalty_settings') {
      final configRecord = records.first;
      await companyDoc
          .collection('loyalty_settings')
          .doc('config')
          .set(configRecord, SetOptions(merge: true));
      return;
    }

    // Process in batches of 400 (Firestore maximum per batch is 500)
    const batchSize = 400;
    for (int i = 0; i < records.length; i += batchSize) {
      final end = (i + batchSize < records.length) ? i + batchSize : records.length;
      final slice = records.sublist(i, end);

      try {
        final batch = targetFirestore.batch();
        for (final row in slice) {
          final docId = _resolveDocumentId(table, row);
          final docRef = companyDoc.collection(table).doc(docId);
          batch.set(docRef, row, SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        // Fallback to individual sets if batch fails (e.g., in unit test mocks)
        for (final row in slice) {
          final docId = _resolveDocumentId(table, row);
          final docRef = companyDoc.collection(table).doc(docId);
          await docRef.set(row, SetOptions(merge: true));
        }
      }
    }
  }

  /// Preserves exact primary key ID as the Firestore document key
  String _resolveDocumentId(String table, Map<String, dynamic> row) {
    switch (table) {
      case 'categories':
        return (row['name'] as String?)?.trim() ?? 'category_${DateTime.now().millisecondsSinceEpoch}';
      case 'customer_loyalty':
        return (row['customer_id'] as String?)?.trim() ?? 'cust_${DateTime.now().millisecondsSinceEpoch}';
      case 'loyalty_settings':
        return 'config';
      case 'products':
      case 'customers':
      case 'bills':
      case 'offers':
      case 'offer_tracking':
      case 'returns':
      case 'stock_movements':
      default:
        return (row['id'] as String?)?.trim() ?? '${table}_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
