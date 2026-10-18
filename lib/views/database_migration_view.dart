import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_colors.dart';
import '../services/database_migration_service.dart';
import '../services/database_service.dart';
import '../view_models/shop_view_model.dart';

class DatabaseMigrationView extends StatefulWidget {
  const DatabaseMigrationView({
    super.key,
    required this.viewModel,
  });

  final ShopViewModel viewModel;

  @override
  State<DatabaseMigrationView> createState() => _DatabaseMigrationViewState();
}

class _DatabaseMigrationViewState extends State<DatabaseMigrationView> {
  final DatabaseMigrationService _migrationService = DatabaseMigrationService.instance;
  Map<String, int>? _tableCounts;
  bool _isLoadingCounts = true;
  bool _isMigrating = false;
  MigrationProgress? _currentProgress;
  MigrationResult? _lastResult;
  String? _jsonBackupPath;

  final Map<String, IconData> _tableIcons = {
    'categories': Icons.category_outlined,
    'products': Icons.inventory_2_outlined,
    'customers': Icons.people_outline,
    'bills': Icons.receipt_long_outlined,
    'customer_loyalty': Icons.stars_outlined,
    'loyalty_settings': Icons.tune_outlined,
    'offers': Icons.local_offer_outlined,
    'offer_tracking': Icons.track_changes_outlined,
    'returns': Icons.swap_horizontal_circle_outlined,
    'stock_movements': Icons.timeline_outlined,
  };

  final Map<String, String> _tableDescriptions = {
    'categories': 'Store product categories and catalog hierarchy',
    'products': 'All shoe items (preserves IDs, sizes, colors, and image_path)',
    'customers': 'Customer profiles (preserves IDs, phone numbers, notes)',
    'bills': 'Complete billing history (preserves customer_id, product_id, items_json)',
    'customer_loyalty': 'Loyalty points and redemption records',
    'loyalty_settings': 'Points per spend, redemption ratio, and thresholds',
    'offers': 'Active promotional vouchers and WhatsApp message templates',
    'offer_tracking': 'Offer dispatch and redemption tracking records',
    'returns': 'Return and exchange records (preserves bill_id, customer_id)',
    'stock_movements': 'Inventory audit trail and stock adjustment history',
  };

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoadingCounts = true);
    final dbService = widget.viewModel.databaseService ?? DatabaseService();
    final counts = await _migrationService.getLocalTableCounts(dbService);
    if (mounted) {
      setState(() {
        _tableCounts = counts;
        _isLoadingCounts = false;
      });
    }
  }

  int get _totalRecords => _tableCounts?.values.fold<int>(0, (sum, c) => sum + c) ?? 0;

  Future<void> _startMigration() async {
    final dbService = widget.viewModel.databaseService ?? DatabaseService();
    final companyId = widget.viewModel.companyId;

    setState(() {
      _isMigrating = true;
      _currentProgress = null;
      _lastResult = null;
    });

    final result = await _migrationService.runMigrationToFirestore(
      databaseService: dbService,
      companyId: companyId,
      companyProfile: widget.viewModel.currentCompanyProfile,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _currentProgress = progress);
        }
      },
    );

    if (mounted) {
      setState(() {
        _isMigrating = false;
        _lastResult = result;
        if (result.exportedJsonPath != null) {
          _jsonBackupPath = result.exportedJsonPath;
        }
      });

      _showCompletionDialog(result);
    }
  }

  Future<void> _exportJsonDump() async {
    final dbService = widget.viewModel.databaseService ?? DatabaseService();
    final companyId = widget.viewModel.companyId;

    try {
      final path = await _migrationService.exportSqliteToJsonFile(
        databaseService: dbService,
        companyId: companyId,
        companyProfile: widget.viewModel.currentCompanyProfile,
      );

      setState(() => _jsonBackupPath = path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SQLite database dumped to JSON:\n$path'),
            backgroundColor: AppColors.brandBlue,
            action: SnackBarAction(
              label: 'SHARE',
              textColor: Colors.white,
              onPressed: () => Share.shareXFiles([XFile(path)], text: 'Ayesha Footwear SQLite Database Dump'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export dump: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCompletionDialog(MigrationResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (result.success ? AppColors.success : AppColors.error).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                result.success ? Icons.cloud_done : Icons.error_outline,
                color: result.success ? AppColors.success : AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.success ? 'Migration Completed!' : 'Migration Warning',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.success
                    ? 'All ${result.totalRecords} SQLite records were successfully uploaded to Cloud Firestore, preserving all primary keys, foreign key relationships, and image references.'
                    : 'Migration finished with notice: ${result.errorMessage ?? "Unknown error"}. Local SQLite data is fully intact.',
                style: const TextStyle(fontSize: 13, color: AppColors.bodyText, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _summaryRow('Target Firestore Path', 'companies/${result.companyId}/'),
                    const Divider(height: 14),
                    _summaryRow('Total Records Uploaded', '${result.totalRecords}'),
                    const Divider(height: 14),
                    _summaryRow('Duration', '${result.duration.inSeconds}s'),
                    if (result.exportedJsonPath != null) ...[
                      const Divider(height: 14),
                      _summaryRow('Local JSON Backup', 'Created'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          if (result.exportedJsonPath != null)
            TextButton.icon(
              onPressed: () {
                Share.shareXFiles([XFile(result.exportedJsonPath!)], text: 'Ayesha Footwear SQLite Database Dump');
              },
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Share JSON Dump'),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.w600)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mainText),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Database Migration to Firestore', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Counts',
            onPressed: _isMigrating ? null : _loadCounts,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export JSON Dump',
            onPressed: _isMigrating ? null : _exportJsonDump,
          ),
        ],
      ),
      body: _isLoadingCounts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Card
                  _buildHeaderCard(),

                  const SizedBox(height: 12),

                  // Recent Result / Backup Banner
                  _buildRecentResultBanner(),

                  // Migration Progress Indicator (if active)
                  if (_isMigrating && _currentProgress != null) ...[
                    _buildProgressCard(_currentProgress!),
                    const SizedBox(height: 16),
                  ],

                  // Table Breakdown Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'EXISTING SQLITE TABLES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Total: $_totalRecords Records',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // List of 10 Tables
                  ...DatabaseMigrationService.allTables.map((table) {
                    final count = _tableCounts?[table] ?? 0;
                    return _buildTableTile(table, count);
                  }),

                  const SizedBox(height: 20),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isMigrating ? null : _startMigration,
                      icon: _isMigrating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload, size: 20),
                      label: Text(
                        _isMigrating ? 'Migrating Database to Firestore...' : 'START AUTOMATIC CLOUD MIGRATION',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E3A8A),
                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isMigrating ? null : _exportJsonDump,
                      icon: const Icon(Icons.data_object, size: 18),
                      label: const Text('Export All Records to JSON Backup File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildRecentResultBanner() {
    if (_lastResult == null && _jsonBackupPath == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_lastResult != null)
                  Text(
                    _lastResult!.success
                        ? 'Migration completed: ${_lastResult!.totalRecords} records synced to ${_lastResult!.companyId}'
                        : 'Notice: ${_lastResult!.errorMessage}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF166534)),
                  ),
                if (_jsonBackupPath != null)
                  Text(
                    'Backup JSON saved: ${_jsonBackupPath!.split(RegExp(r"[\\/]")).last}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF15803D)),
                  ),
              ],
            ),
          ),
          if (_jsonBackupPath != null)
            IconButton(
              icon: const Icon(Icons.share, size: 18, color: Color(0xFF16A34A)),
              tooltip: 'Share Backup File',
              onPressed: () => Share.shareXFiles([XFile(_jsonBackupPath!)], text: 'SQLite Backup Dump'),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final companyId = widget.viewModel.companyId;
    final companyName = widget.viewModel.companyName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_sync, color: Color(0xFF1E3A8A), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.mainText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Store ID: $companyId',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This tool automatically scans all 10 local SQLite tables and uploads every record to Cloud Firestore under companies/{companyId}/. Primary key IDs, foreign key links, and product image references are 100% preserved.',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(MigrationProgress progress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${progress.tableIndex} of ${progress.totalTables}: ${progress.tableName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
              ),
              Text(
                '${(progress.progressFraction * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.progressFraction,
            backgroundColor: const Color(0xFFDBEAFE),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Text(
            progress.statusMessage,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Widget _buildTableTile(String table, int count) {
    final icon = _tableIcons[table] ?? Icons.table_chart_outlined;
    final description = _tableDescriptions[table] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      table,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.mainText),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: count > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$count records',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: count > 0 ? const Color(0xFF16A34A) : AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
