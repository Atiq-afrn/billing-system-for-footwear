import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../view_models/shop_view_model.dart';
import '../widgets/shop_drawer.dart';
import 'add_product_sheet.dart';
import 'bills_view.dart';
import 'create_bill_sheet.dart';
import 'customers_view.dart';
import 'dashboard_view.dart';
import 'out_of_stock_view.dart';
import 'pdf_preview_view.dart';
import 'products_view.dart';
import 'qr_scanner_view.dart';
import 'tools_operations_view.dart';

class ShopShell extends StatelessWidget {
  const ShopShell({super.key, required this.viewModel});
  final ShopViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      // 0: Dashboard
      DashboardView(
        viewModel: viewModel,
        onCreateBill: () => _showCreateBill(context),
        onExportExcel: () => _handleExportExcel(context),
        onPreviewPdf: (bill) => _handlePreviewPdf(context, bill),
        onShare: (bill) => _handleShareWhatsApp(context, bill),
        onStockAlerts: () => viewModel.setTab(5),
        onViewAllBills: () => viewModel.setTab(1),
        onViewAllProducts: () => viewModel.setTab(3),
      ),
      // 1: Bills
      BillsView(
        viewModel: viewModel,
        onCreateBill: () => _showCreateBill(context),
        onPreviewPdf: (bill) => _handlePreviewPdf(context, bill),
        onShare: (bill) => _handleShareWhatsApp(context, bill),
        onStockAlerts: () => viewModel.setTab(5),
      ),
      // 2: Customers
      CustomersView(
        viewModel: viewModel,
        onExportExcel: () => _handleExportExcel(context),
        onSendOffer: (customer) => _handleSendOffer(context, customer),
        onPreviewPdf: (bill) => _handlePreviewPdf(context, bill),
        onShareBill: (bill) => _handleShareWhatsApp(context, bill),
        onStockAlerts: () => viewModel.setTab(5),
      ),
      // 3: Products
      ProductsView(
        products: viewModel.products,
        onAddProduct: () => _showAddProduct(context),
        unreadAlertsCount: viewModel.finishedStockCount,
        onStockAlerts: () => viewModel.setTab(5),
        companyName: viewModel.companyName,
        onCreateBillWithProduct: (product) => _showCreateBill(context, preselectedProduct: product),
      ),
      // 4: Dedicated Tools & Operations View
      ToolsOperationsView(
        viewModel: viewModel,
        onExportExcel: () => _handleExportExcel(context),
        onPreviewPdf: (bill) => _handlePreviewPdf(context, bill),
        onSendOffer: (customer) => _handleSendOffer(context, customer),
        onOpenQrScanner: () => _openQrScanner(context),
      ),
      // 5: Dedicated Finished Stock & Alerts View
      OutOfStockView(
        viewModel: viewModel,
      ),
    ];

    final currentTab = viewModel.selectedTab.clamp(0, pages.length - 1);

    return Scaffold(
      drawer: ShopDrawer(
        viewModel: viewModel,
        onSelectTab: (tab) => viewModel.setTab(tab),
        onExportExcel: () => _handleExportExcel(context),
        onPreviewPdf: () {
          if (viewModel.bills.isNotEmpty) {
            _handlePreviewPdf(context, viewModel.bills.first);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create a bill first to preview PDF.')),
            );
          }
        },
        onSendOffer: () {
          if (viewModel.customers.isNotEmpty) {
            _handleSendOffer(context, viewModel.customers.first);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add customers to send WhatsApp offers.')),
            );
          }
        },
        onOpenQrScanner: () => _openQrScanner(context),
      ),
      body: SafeArea(child: pages[currentTab]),
      bottomNavigationBar: _buildPaytmStyleBottomNav(context, currentTab),
    );
  }

  Widget _buildPaytmStyleBottomNav(BuildContext context, int currentTab) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BAF2).withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              // Tab 0: Home
              _buildNavButton(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentTab == 0,
                onTap: () => viewModel.setTab(0),
              ),

              // Tab 1: Sales
              _buildNavButton(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Sales',
                isSelected: currentTab == 1,
                onTap: () => viewModel.setTab(1),
              ),

              // CENTER: QR Scanner Button with Radiant Blue Dispersion Pulse
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: () => _openQrScanner(context),
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF002E6E), Color(0xFF00BAF2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BAF2).withOpacity(0.55),
                            blurRadius: 16,
                            spreadRadius: 3,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                          SizedBox(height: 1),
                          Text(
                            'SCAN',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 8,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Tab 2: Customers
              _buildNavButton(
                icon: Icons.people_alt_outlined,
                activeIcon: Icons.people_alt_rounded,
                label: 'Customers',
                isSelected: currentTab == 2,
                onTap: () => viewModel.setTab(2),
              ),

              // Tab 3: Products
              _buildNavButton(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'Products',
                isSelected: currentTab == 3,
                onTap: () => viewModel.setTab(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            // Blue dispersion effect when selected
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      Color(0x3300BAF2), // Dispersed vibrant blue top
                      Color(0x142563EB), // Soft blue tint bottom
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: const Color(0x6600BAF2), width: 1.2)
                : Border.all(color: Colors.transparent, width: 1.2),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x4400BAF2),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated blue dispersion indicator pill on top
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 16 : 0,
                height: 2.5,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00BAF2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0xFF00BAF2),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? const Color(0xFF0062D2) : const Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF0052B4) : const Color(0xFF64748B),
                  letterSpacing: isSelected ? 0.3 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQrScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerView(
          companyName: viewModel.companyName,
          upiId: viewModel.upiId,
          products: viewModel.products,
          initialAmount: viewModel.todaySales > 0 ? (viewModel.todaySales / (viewModel.todayBills.isEmpty ? 1 : viewModel.todayBills.length)).round() : 999,
          onProductScanned: (product) {
            _showCreateBill(context, preselectedProduct: product);
          },
        ),
      ),
    );
  }

  Future<void> _handleExportExcel(BuildContext context) async {
    try {
      final path = await viewModel.exportExcel();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel exported: ${path.split(RegExp(r'[/\\]')).last}'),
            action: SnackBarAction(
              label: 'SHARE',
              onPressed: () => viewModel.shareExcelFile(path),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel: $e')),
        );
      }
    }
  }

  void _handlePreviewPdf(BuildContext context, Bill bill) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfPreviewView(bill: bill)),
    );
  }

  Future<void> _handleShareWhatsApp(BuildContext context, Bill bill) async {
    final launched = await viewModel.sendBillWhatsApp(bill);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp. Check if installed.')),
      );
    }
  }

  Future<void> _handleSendOffer(BuildContext context, Customer customer) async {
    final launched = await viewModel.sendCustomerOffer(customer);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp for customer offer.')),
      );
    }
  }

  void _showAddProduct(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductSheet(
        products: viewModel.products,
        categories: viewModel.allCategories,
        onAddCategory: viewModel.addCustomCategory,
        onRemoveCategory: viewModel.removeCategory,
        onSave: (draft) async {
          await viewModel.addProduct(draft);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product added to SQLite database.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showCreateBill(BuildContext context, {Product? preselectedProduct}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateBillSheet(
        products: viewModel.products,
        preselectedProduct: preselectedProduct,
        categories: viewModel.allCategories,
        onSave: (draft) async {
          await viewModel.createBill(draft);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bill saved to SQLite & customer profile updated.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
}
