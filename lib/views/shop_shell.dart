import 'package:flutter/material.dart';

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
        onDeleteProduct: (product) async {
          await viewModel.deleteProduct(product.id);
        },
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
      // Using a custom floating bottom nav
      bottomNavigationBar: _buildFloatingBottomNav(context, currentTab),
    );
  }

  // ==========================================
  // NEW CLEAN & COMPACT BOTTOM NAVIGATION
  // ==========================================
  Widget _buildFloatingBottomNav(BuildContext context, int currentTab) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Bar
        Container(
          height: 65 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Tab 0: Home
                _navItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0, currentTab),

                // Tab 1: Sales
                _navItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Sales', 1, currentTab),

                // Empty space for the floating button
                const SizedBox(width: 60),

                // Tab 2: Customers
                _navItem(Icons.people_alt_outlined, Icons.people_alt_rounded, 'Customers', 2, currentTab),

                // Tab 3: Products
                _navItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Products', 3, currentTab),
              ],
            ),
          ),
        ),

        // Floating Center QR Button
        Positioned(
          top: -22, // Lifts the button above the navbar
          left: MediaQuery.of(context).size.width / 2 - 30, // Centers it
          child: GestureDetector(
            onTap: () => _openQrScanner(context),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF00BAF2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BAF2).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index, int currentTab) {
    final isSelected = index == currentTab;
    final color = isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF94A3B8);

    return Expanded(
      child: InkWell(
        onTap: () => viewModel.setTab(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
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
      MaterialPageRoute(
        builder: (_) => PdfPreviewView(
          bill: bill,
          companyName: viewModel.companyName,
          companyAddress: viewModel.currentCompanyProfile.address,
          companyMobile: viewModel.currentCompanyProfile.mobile,
          upiId: viewModel.upiId,
        ),
      ),
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
                content: Text('Product added & synced with Firestore!'),
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
                content: Text('Bill saved & customer profile updated.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
}