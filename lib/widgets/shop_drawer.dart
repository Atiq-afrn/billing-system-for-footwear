import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/company_profile.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../view_models/shop_view_model.dart';
import '../views/change_upi_view.dart';
import '../views/database_migration_view.dart';
import '../views/loyal_customers_offers_view.dart';
import '../views/returns_exchanges_view.dart';
import 'shop_widgets.dart';

class ShopDrawer extends StatelessWidget {
  const ShopDrawer({
    super.key,
    required this.viewModel,
    required this.onSelectTab,
    required this.onExportExcel,
    required this.onPreviewPdf,
    required this.onSendOffer,
    required this.onOpenQrScanner,
  });

  final ShopViewModel viewModel;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onExportExcel;
  final VoidCallback onPreviewPdf;
  final VoidCallback onSendOffer;
  final VoidCallback onOpenQrScanner;

  @override
  Widget build(BuildContext context) {
    final finishedCount = viewModel.finishedStockCount;
    final ownerName = (viewModel.userProfile?.name != null && viewModel.userProfile!.name.trim().isNotEmpty)
        ? viewModel.userProfile!.name.trim()
        : 'Store Owner';

    return Drawer(
      backgroundColor: Colors.white, // White side menu drawer
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 18, 18, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A), // Royal Blue drawer header
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.storefront, color: Color(0xFF1E3A8A), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viewModel.companyName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 13, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Owner: $ownerName',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // UPI and Contact Bar with Edit / Change button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STORE UPI ID',
                              style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            Text(
                              viewModel.upiId,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeUpiView(viewModel: viewModel),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 11, color: Color(0xFF1E3A8A)),
                              SizedBox(width: 3),
                              Text(
                                'CHANGE',
                                style: TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quick stats chip bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _statItem("Today's Sales", money(viewModel.todaySales))),
                      Container(width: 1, height: 24, color: Colors.white24),
                      Expanded(child: _statItem('Products', '${viewModel.products.length}')),
                      Container(width: 1, height: 24, color: Colors.white24),
                      Expanded(child: _statItem('Customers', '${viewModel.customers.length}')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Drawer Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: [
                _sectionHeader('CUSTOMER RETENTION & OFFERS'),

                // Dedicated Loyal Customers & Offers
                _navItem(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Loyal Customers & Offers',
                  subtitle: 'VIP segmentation, reward points & WhatsApp offers',
                  iconColor: const Color(0xFFD97706),
                  badge: '${viewModel.loyalCustomerCount + viewModel.highSpendingCustomerCount}',
                  badgeColor: const Color(0xFFD97706),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoyalCustomersOffersView(viewModel: viewModel),
                      ),
                    );
                  },
                ),

                // Dedicated Returns & Exchanges
                _navItem(
                  icon: Icons.swap_horizontal_circle_outlined,
                  title: 'Returns & Exchanges',
                  subtitle: 'Bill verification, inventory sync & refunds',
                  iconColor: const Color(0xFF2563EB),
                  badge: viewModel.pendingApprovalCount > 0
                      ? '${viewModel.pendingApprovalCount} pending'
                      : (viewModel.returns.isNotEmpty ? '${viewModel.returns.length}' : null),
                  badgeColor: viewModel.pendingApprovalCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReturnsExchangesView(viewModel: viewModel),
                      ),
                    );
                  },
                ),

                const Divider(height: 20, indent: 8, endIndent: 8),

                _sectionHeader('OPERATIONS & ALERTS'),

                // Dedicated Tools & Operations Tab
                _navItem(
                  icon: Icons.handyman_outlined,
                  title: 'Tools & Operations',
                  subtitle: 'Excel exports, PDF receipts, WhatsApp, UPI',
                  isSelected: viewModel.selectedTab == 4,
                  iconColor: AppColors.accent,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(4);
                  },
                ),

                // Dedicated Out of Stock / Finished Stock Tab
                _navItem(
                  icon: Icons.remove_shopping_cart_outlined,
                  title: 'Finished Stock & Alerts',
                  subtitle: finishedCount > 0
                      ? '$finishedCount items currently unavailable'
                      : 'All stock healthy (0 finished)',
                  isSelected: viewModel.selectedTab == 5,
                  iconColor: finishedCount > 0 ? Colors.red : Colors.green,
                  badge: finishedCount > 0 ? '$finishedCount' : null,
                  badgeColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(5);
                  },
                ),

                // Dedicated Change UPI ID item
                _navItem(
                  icon: Icons.qr_code_2_outlined,
                  title: 'Change UPI ID',
                  subtitle: 'Security OTP & Firebase verification',
                  iconColor: const Color(0xFF1E3A8A),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeUpiView(viewModel: viewModel),
                      ),
                    );
                  },
                ),

                // Dedicated Cloud & Database Sync item
                _navItem(
                  icon: Icons.cloud_sync_outlined,
                  title: 'Cloud & Database Sync',
                  subtitle: 'SQLite 0ms local + Firebase Firestore backup',
                  iconColor: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.pop(context);
                    _showSyncDialog(context);
                  },
                ),

                // Dedicated Store Branches & Switcher item
                _navItem(
                  icon: Icons.store_mall_directory_outlined,
                  title: 'Store Branches & Switcher',
                  subtitle: 'Isolated cloud databases for each store',
                  iconColor: const Color(0xFF0D9488),
                  onTap: () {
                    Navigator.pop(context);
                    _showCompanyManagerDialog(context);
                  },
                ),

                // Dedicated Database Migration to Firestore item
                _navItem(
                  icon: Icons.upload_file_outlined,
                  title: 'Migrate SQLite to Firestore',
                  subtitle: 'Upload all 10 tables preserving IDs & relations',
                  iconColor: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DatabaseMigrationView(viewModel: viewModel),
                      ),
                    );
                  },
                ),

                const Divider(height: 24, indent: 8, endIndent: 8),
              ],
            ),
          ),

          // Drawer Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${viewModel.companyName} POS',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.deepNavy),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showSyncDialog(context),
                      borderRadius: BorderRadius.circular(6),
                      child: _buildSyncStatusBadge(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.logout, color: Colors.red.shade700, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Confirm Sign Out',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          content: const Text(
                            'Are you sure you want to sign out of Ayesha Footwear POS? You will need to sign in again to access the store.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                          ),
                          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                            ),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              icon: const Icon(Icons.logout, size: 16),
                              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        await AuthService.instance.logout();
                        await viewModel.refreshUserProfile();
                      }
                    },
                    icon: const Icon(Icons.logout, size: 15),
                    label: const Text('SIGN OUT / SWITCH STORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? iconColor,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0x1414213D) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: AppColors.deepNavy.withOpacity(0.2)) : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.deepNavy : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : (iconColor ?? AppColors.deepNavy),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.deepNavy,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 16,
          color: isSelected ? AppColors.deepNavy : Colors.grey.shade400,
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildSyncStatusBadge() {
    final status = viewModel.cloudSyncStatus;
    final Color bgColor;
    final Color textColor;
    final Color borderColor;
    final String label;

    switch (status) {
      case CloudSyncStatus.synced:
        bgColor = Colors.green.shade50;
        textColor = const Color(0xFF16A34A);
        borderColor = Colors.green.shade200;
        label = 'Cloud Synced';
        break;
      case CloudSyncStatus.syncing:
        bgColor = Colors.blue.shade50;
        textColor = const Color(0xFF2563EB);
        borderColor = Colors.blue.shade200;
        label = 'Syncing...';
        break;
      case CloudSyncStatus.offline:
        bgColor = Colors.amber.shade50;
        textColor = const Color(0xFFD97706);
        borderColor = Colors.amber.shade200;
        label = 'Offline / Local';
        break;
      case CloudSyncStatus.error:
        bgColor = Colors.red.shade50;
        textColor = const Color(0xFFDC2626);
        borderColor = Colors.red.shade200;
        label = 'Sync Pending';
        break;
      case CloudSyncStatus.idle:
        bgColor = Colors.grey.shade100;
        textColor = const Color(0xFF4B5563);
        borderColor = Colors.grey.shade300;
        label = 'Ready';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDualDatabaseCard(BuildContext context) {
    final status = viewModel.cloudSyncStatus;
    final companyId = viewModel.companyId;
    final lastSynced = viewModel.lastSyncedAt;

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    switch (status) {
      case CloudSyncStatus.syncing:
        statusColor = const Color(0xFF2563EB);
        statusText = 'Syncing Cloud...';
        statusIcon = Icons.sync;
        break;
      case CloudSyncStatus.synced:
        statusColor = const Color(0xFF16A34A);
        statusText = 'Cloud Synced (Firestore)';
        statusIcon = Icons.cloud_done;
        break;
      case CloudSyncStatus.offline:
        statusColor = const Color(0xFFD97706);
        statusText = 'Offline Mode (Local Active)';
        statusIcon = Icons.cloud_off;
        break;
      case CloudSyncStatus.error:
        statusColor = const Color(0xFFDC2626);
        statusText = 'Sync Pending (Local Active)';
        statusIcon = Icons.sync_problem;
        break;
      case CloudSyncStatus.idle:
        statusColor = const Color(0xFF4B5563);
        statusText = 'Local Ready';
        statusIcon = Icons.storage;
        break;
    }

    String syncTimeStr = 'Not synced yet';
    if (lastSynced != null) {
      final diff = DateTime.now().difference(lastSynced);
      if (diff.inSeconds < 60) {
        syncTimeStr = 'Just now';
      } else if (diff.inMinutes < 60) {
        syncTimeStr = '${diff.inMinutes}m ago';
      } else {
        syncTimeStr = '${diff.inHours}h ago';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'Store ID: $companyId',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Starting cloud sync...'),
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                  final ok = await viewModel.syncWithCloud();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Cloud Firestore synchronization complete!'
                              : 'Offline / local mode active. Local changes will sync when online.',
                        ),
                        backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Sync',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.speed, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'SQLite 0ms instant local | Firestore cloud backup',
                    style: TextStyle(fontSize: 9.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  syncTimeStr,
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_sync, color: Color(0xFF1E3A8A), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dual-Database Cloud Sync',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Local SQLite instant POS + Firebase Firestore cloud sync',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDualDatabaseCard(context),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCompanyManagerDialog(context);
                  },
                  icon: const Icon(Icons.store_mall_directory_outlined, size: 18),
                  label: const Text('Manage Store Branches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF3E8FF),
                    foregroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DatabaseMigrationView(viewModel: viewModel),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: const Text('Full Database Migration to Firestore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompanyManagerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: FutureBuilder<List<CompanyProfile>>(
            future: viewModel.fetchOwnerCompanies(),
            builder: (context, snapshot) {
              final companies = snapshot.data ?? [viewModel.currentCompanyProfile];
              final currentId = viewModel.companyId;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.store, color: Color(0xFF1E3A8A), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Store Branches & Multi-Company',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Switch store or create separate isolated branches',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'YOUR STORES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ...companies.map((comp) {
                      final isActive = comp.id == currentId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? Icons.check_circle : Icons.storefront_outlined,
                              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          comp.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isActive ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isActive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2563EB),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${comp.id} • UPI: ${comp.upiId.isNotEmpty ? comp.upiId : "Not set"}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (!isActive) ...[
                              const SizedBox(width: 8),
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await viewModel.switchCompany(comp);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Switched store to "${comp.name}"'),
                                        backgroundColor: const Color(0xFF16A34A),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E3A8A),
                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCreateBranchDialog(context);
                      },
                      icon: const Icon(Icons.add_business_outlined, size: 18),
                      label: const Text('+ Register New Store Branch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showCreateBranchDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final upiCtrl = TextEditingController(text: viewModel.upiId);
    final mobileCtrl = TextEditingController(text: viewModel.userProfile?.mobile ?? '');
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_business, color: Color(0xFF1E3A8A), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Add Store Branch',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Each branch has its own isolated stock, billing, loyalty, and customer data connected to Firebase.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Branch / Store Name *',
                    hintText: 'e.g. Ayesha Footwear Branch 2',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter branch name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: upiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Store UPI ID for QR Billing *',
                    hintText: 'e.g. merchant@okaxis',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid UPI ID' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Mobile Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Branch Address (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dlgContext);
              await viewModel.createAndSwitchCompany(
                name: nameCtrl.text.trim(),
                upiId: upiCtrl.text.trim(),
                mobile: mobileCtrl.text.trim(),
                address: addressCtrl.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Branch "${nameCtrl.text.trim()}" created & active!'),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
              }
            },
            child: const Text('Create & Switch', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
