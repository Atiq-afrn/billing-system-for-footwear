import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_colors.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import '../view_models/shop_view_model.dart';
import '../widgets/shop_widgets.dart';

class CustomerDetailsView extends StatelessWidget {
  const CustomerDetailsView({
    super.key,
    required this.customer,
    required this.viewModel,
    required this.onPreviewPdf,
    required this.onShare,
  });

  final Customer customer;
  final ShopViewModel viewModel;
  final ValueChanged<Bill> onPreviewPdf;
  final ValueChanged<Bill> onShare;

  @override
  Widget build(BuildContext context) {
    final cleanName = customer.name.trim().isNotEmpty ? customer.name.trim() : 'Walk-in Customer';
    final initial = cleanName.characters.first.toUpperCase();
    final customerBills = viewModel.getBillsForCustomer(customer);
    final totalSpent = customerBills.isNotEmpty
        ? customerBills.fold(0, (sum, b) => sum + b.total)
        : customer.totalSpent;
    final totalVisits = customerBills.isNotEmpty ? customerBills.length : customer.visits;
    final avgSpend = totalVisits > 0 ? (totalSpent / totalVisits).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.deepNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Customer Profile & History',
          style: TextStyle(
            color: AppColors.deepNavy,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          if (customer.mobile.isNotEmpty)
            IconButton(
              tooltip: 'Call Customer',
              icon: const Icon(Icons.phone_outlined, color: AppColors.deepNavy),
              onPressed: () async {
                final uri = Uri.parse('tel:${customer.mobile}');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
          IconButton(
            tooltip: 'WhatsApp Offer',
            icon: const Icon(Icons.campaign_outlined, color: AppColors.deepNavy),
            onPressed: () => viewModel.sendCustomerOffer(customer),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Top Profile Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.deepNavy,
                        child: Text(
                          initial,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cleanName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone_android, size: 14, color: AppColors.accent),
                                const SizedBox(width: 6),
                                Text(
                                  customer.mobile.isNotEmpty ? customer.mobile : 'No Mobile Number',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 14),
                  // Quick Summary Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _heroStat('Total Spent', money(totalSpent)),
                      Container(width: 1, height: 26, color: Colors.white24),
                      _heroStat('Bills Issued', '$totalVisits'),
                      Container(width: 1, height: 26, color: Colors.white24),
                      _heroStat('Average Bill', money(avgSpend)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Footwear Preferences Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: AppColors.deepNavy, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Footwear Preferences & Notes',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.deepNavy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InfoChip(Icons.straighten, 'Size: ${customer.size.isNotEmpty ? customer.size : "Standard"}'),
                      InfoChip(Icons.palette_outlined, 'Color: ${customer.colors.isNotEmpty ? customer.colors : "Various"}'),
                      if (customer.lastItem.isNotEmpty)
                        InfoChip(Icons.shopping_bag_outlined, 'Recent: ${customer.lastItem}'),
                    ],
                  ),
                  if (customer.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Note: ${customer.note.trim()}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Bills Generated Against Customer Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Purchase History (${customerBills.length} Bills)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.deepNavy,
                  ),
                ),
                if (customerBills.isNotEmpty)
                  Text(
                    '${customerBills.fold(0, (sum, b) => sum + b.qty)} Pairs Total',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (customerBills.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFF94A3B8)),
                    SizedBox(height: 8),
                    Text(
                      'No saved bills found for this customer record yet.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...customerBills.map((bill) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BillTile(
                    bill: bill,
                    onPdf: () => onPreviewPdf(bill),
                    onShare: () => onShare(bill),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
