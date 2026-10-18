import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import '../view_models/shop_view_model.dart';
import '../widgets/shop_widgets.dart';
import 'change_upi_view.dart';

class ToolsOperationsView extends StatelessWidget {
  const ToolsOperationsView({
    super.key,
    required this.viewModel,
    required this.onExportExcel,
    required this.onPreviewPdf,
    required this.onSendOffer,
    required this.onOpenQrScanner,
  });

  final ShopViewModel viewModel;
  final VoidCallback onExportExcel;
  final ValueChanged<Bill>? onPreviewPdf;
  final ValueChanged<Customer>? onSendOffer;
  final VoidCallback onOpenQrScanner;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Header(
          title: viewModel.companyName,
          subtitle: 'Operations & Data Exports',
          unreadAlertsCount: viewModel.finishedStockCount,
          onNotificationsPressed: () => _showStockAlertsSheet(context),
        ),
        const SizedBox(height: 22),
        Text('Tools & Operations', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Store data backups, printable receipts, WhatsApp marketing, and UPI payments.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        // Tool 1: Excel Export
        _buildToolCard(
          context: context,
          icon: Icons.table_chart_outlined,
          iconColor: Colors.green.shade700,
          title: 'Export Store Data to Excel (.xlsx)',
          description: 'Export all customer profiles, footwear inventory stock, and bill receipts into a single Excel file.',
          buttonText: 'EXPORT EXCEL',
          onTap: onExportExcel,
        ),
        const SizedBox(height: 14),

        // Tool 2: PDF Template
        _buildToolCard(
          context: context,
          icon: Icons.picture_as_pdf_outlined,
          iconColor: Colors.red.shade700,
          title: 'Bill PDF Invoice & Print Preview',
          description: 'Generate standardized A4 tax invoices with full line-item details, size/color breakdown, and store branding.',
          buttonText: 'PREVIEW INVOICE',
          onTap: () {
            if (viewModel.bills.isNotEmpty && onPreviewPdf != null) {
              onPreviewPdf!(viewModel.bills.first);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No bills available yet. Create a bill to preview PDF.')),
              );
            }
          },
        ),
        const SizedBox(height: 14),

        // Tool 3: WhatsApp Offers
        _buildToolCard(
          context: context,
          icon: Icons.chat_outlined,
          iconColor: Colors.teal.shade700,
          title: 'WhatsApp Promotional Offers',
          description: 'Send stock arrival alerts and festive footwear offers to customer WhatsApp numbers.',
          buttonText: 'SEND OFFER',
          onTap: () {
            if (viewModel.customers.isNotEmpty && onSendOffer != null) {
              onSendOffer!(viewModel.customers.first);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No customers registered yet. Add a customer or create a bill first.')),
              );
            }
          },
        ),
        const SizedBox(height: 14),

        // Tool 4: UPI QR Scanner & Code
        _buildToolCard(
          context: context,
          icon: Icons.qr_code_scanner,
          iconColor: const Color(0xFF00BAF2),
          title: 'UPI Store QR & Camera Scanner',
          description: 'Accept customer UPI payments directly to ${viewModel.upiId} and scan product barcodes.',
          buttonText: 'OPEN SCANNER & QR',
          onTap: onOpenQrScanner,
        ),
        const SizedBox(height: 14),

        // Tool 5: Change UPI ID
        _buildToolCard(
          context: context,
          icon: Icons.qr_code_2_outlined,
          iconColor: const Color(0xFF1E3A8A),
          title: 'Change Business UPI ID',
          description: 'Securely verify your identity via email OTP or Firebase password to update the store UPI ID.',
          buttonText: 'CHANGE UPI ID',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeUpiView(viewModel: viewModel),
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // Tool 5: SQLite Database Status
        _buildToolCard(
          context: context,
          icon: Icons.storage_outlined,
          iconColor: AppColors.deepNavy,
          title: 'SQLite Database & Offline Backup',
          description: 'Local database: ${viewModel.products.length} Products, ${viewModel.bills.length} Bills, ${viewModel.customers.length} Customers stored safely on device.',
          buttonText: 'CHECK DB STATUS',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'SQLite Storage OK • ${viewModel.products.length} Stock items • ${viewModel.bills.length} Invoices • ${viewModel.customers.length} Customers',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.deepNavy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy.withOpacity(0.08),
                foregroundColor: AppColors.deepNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showStockAlertsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockAlertsSheet(viewModel: viewModel),
    );
  }
}

class _StockAlertsSheet extends StatelessWidget {
  const _StockAlertsSheet({required this.viewModel});
  final ShopViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final outOfStock = viewModel.outOfStockProducts;
    final lowStock = viewModel.lowStockProducts;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_active, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stock Alerts & Notifications',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.deepNavy),
                    ),
                    Text(
                      '${outOfStock.length} out-of-stock items, ${lowStock.length} low stock items',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const Divider(height: 24),
          if (outOfStock.isEmpty && lowStock.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('All products are in stock! 👍', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (outOfStock.isNotEmpty) ...[
                    const Text(
                      '⛔ STOCK IS UNAVAILABLE / FINISHED (0 Pairs Left)',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ...outOfStock.map((p) => _buildAlertItem(context, p, isZero: true)),
                    const SizedBox(height: 16),
                  ],
                  if (lowStock.isNotEmpty) ...[
                    const Text(
                      '⚠️ LOW STOCK WARNING (≤ 3 Pairs Left)',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ...lowStock.map((p) => _buildAlertItem(context, p, isZero: false)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, dynamic p, {required bool isZero}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isZero ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isZero ? Colors.red.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(isZero ? Icons.cancel : Icons.warning_amber_rounded, color: isZero ? Colors.red : Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text('${p.category} • ${p.stock} in stock • ₹${p.price}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(context);
              _showQuickRestockDialog(context, p);
            },
            style: FilledButton.styleFrom(
              backgroundColor: isZero ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Restock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showQuickRestockDialog(BuildContext context, dynamic p) {
    final controller = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restock "${p.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${p.stock} pairs'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Total Stock (Pairs)',
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          FilledButton(
            style: orangeButton(),
            onPressed: () async {
              final newStock = int.tryParse(controller.text.trim()) ?? 10;
              await viewModel.restockProduct(p.id, newStock);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Restocked "${p.name}" to $newStock pairs in SQLite.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('UPDATE STOCK'),
          ),
        ],
      ),
    );
  }
}
