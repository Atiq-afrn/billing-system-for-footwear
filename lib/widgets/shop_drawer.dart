import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../services/cloud_sync_service.dart';
import '../view_models/shop_view_model.dart';
import '../views/app_splash_view.dart';
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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Column(
        children: [
          // ==========================================
          // DRAWER HEADER
          // ==========================================
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A), // Royal Blue
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
                        borderRadius: BorderRadius.circular(14),
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
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Owner: $ownerName',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Clean UPI Pill
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
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2, size: 16, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viewModel.upiId,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'CHANGE',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Clean Quick Stats Row
                Row(
                  children: [
                    Expanded(child: _statItem("Today's Sales", money(viewModel.todaySales))),
                    Container(width: 1, height: 28, color: Colors.white24),
                    Expanded(child: _statItem('Products', '${viewModel.products.length}')),
                    Container(width: 1, height: 28, color: Colors.white24),
                    Expanded(child: _statItem('Customers', '${viewModel.customers.length}')),
                  ],
                ),
              ],
            ),
          ),

          // ==========================================
          // DRAWER MENU ITEMS
          // ==========================================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _sectionHeader('Customer Retention'),

                _navItem(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Loyal Customers & Offers',
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

                _navItem(
                  icon: Icons.sync_alt,
                  title: 'Returns & Exchanges',
                  badge: viewModel.pendingApprovalCount > 0
                      ? '${viewModel.pendingApprovalCount} pending'
                      : (viewModel.returns.isNotEmpty ? '${viewModel.returns.length}' : null),
                  badgeColor: viewModel.pendingApprovalCount > 0
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF2563EB),
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

                const SizedBox(height: 12),
                _sectionHeader('Operations & Alerts'),

                _navItem(
                  icon: Icons.build_outlined,
                  title: 'Tools & Operations',
                  isSelected: viewModel.selectedTab == 4,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(4);
                  },
                ),

                _navItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Finished Stock & Alerts',
                  isSelected: viewModel.selectedTab == 5,
                  badge: finishedCount > 0 ? '$finishedCount' : null,
                  badgeColor: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(5);
                  },
                ),

                _navItem(
                  icon: Icons.qr_code_scanner,
                  title: 'Change UPI ID',
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

                _navItem(
                  icon: Icons.auto_awesome_rounded,
                  title: 'App Goals & Overview',
                  badge: 'TOUR',
                  badgeColor: const Color(0xFFF97316),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppSplashView(
                          isTourMode: true,
                          storeName: viewModel.companyName,
                          onGetStarted: () => Navigator.pop(context),
                          onSignIn: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ==========================================
          // DRAWER FOOTER
          // ==========================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user, color: Color(0xFF16A34A), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${viewModel.companyName} POS',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF475569)),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.red.shade50.withOpacity(0.5),
                    ),
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          title: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Warning Icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF2F2), // Soft Red
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 28),
                              ),
                              const SizedBox(height: 16),
                              // Title
                              const Text(
                                'Confirm Sign Out',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          content: const Text(
                            'Are you sure you want to sign out? You will need to sign in again to access the store.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                          ),
                          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          actions: [
                            Row(
                              children: [
                                // Cancel Button
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF64748B),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Sign Out Button
                                Expanded(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626), // Red
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        await viewModel.logout();
                      }
                    },
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _statItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    String? badge,
    Color? badgeColor,
  }) {
    final Color brandBlue = const Color(0xFF1E3A8A);
    final Color iconColor = isSelected ? brandBlue : const Color(0xFF64748B);
    final Color titleColor = isSelected ? brandBlue : const Color(0xFF1E293B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? brandBlue.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                      color: titleColor,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor ?? brandBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusBadge() {
    final status = viewModel.cloudSyncStatus;
    final Color bgColor;
    final Color textColor;
    final String label;

    switch (status) {
      case CloudSyncStatus.synced:
        bgColor = const Color(0xFFDCFCE7); // Green 100
        textColor = const Color(0xFF16A34A); // Green 600
        label = 'Synced';
        break;
      case CloudSyncStatus.syncing:
        bgColor = const Color(0xFFDBEAFE); // Blue 100
        textColor = const Color(0xFF2563EB); // Blue 600
        label = 'Syncing...';
        break;
      case CloudSyncStatus.offline:
        bgColor = const Color(0xFFFEF3C7); // Amber 100
        textColor = const Color(0xFFD97706); // Amber 600
        label = 'Offline';
        break;
      case CloudSyncStatus.error:
        bgColor = const Color(0xFFFEE2E2); // Red 100
        textColor = const Color(0xFFDC2626); // Red 600
        label = 'Pending';
        break;
      case CloudSyncStatus.idle:
        bgColor = const Color(0xFFF1F5F9); // Slate 100
        textColor = const Color(0xFF64748B); // Slate 500
        label = 'Ready';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
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
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor),
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
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
              const SizedBox(height: 24),
              const Text(
                'Dual-Database Sync',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your POS runs instantly on Local SQLite. Changes are automatically backed up to Firebase Firestore in the background.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF3E8FF),
                    foregroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                  label: const Text('Open Migration Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}