import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Global clean card decoration
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final currentCustomer = viewModel.customers.firstWhere(
              (c) => c.id == customer.id || (c.mobile.isNotEmpty && c.mobile == customer.mobile),
          orElse: () => customer,
        );
        final cleanName = currentCustomer.name.trim().isNotEmpty
            ? currentCustomer.name.trim()
            : 'Walk-in Customer';
        final initial = cleanName.characters.first.toUpperCase();
        final customerBills = viewModel.getBillsForCustomer(currentCustomer);
        final totalSpent = customerBills.isNotEmpty
            ? customerBills.fold(0, (sum, b) => sum + b.total)
            : currentCustomer.totalSpent;
        final totalVisits = customerBills.isNotEmpty ? customerBills.length : currentCustomer.visits;
        final avgSpend = totalVisits > 0 ? (totalSpent / totalVisits).round() : 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Customer Profile',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            actions: [
              if (currentCustomer.mobile.isNotEmpty)
                IconButton(
                  tooltip: 'Call Customer',
                  icon: const Icon(Icons.phone_outlined, color: Color(0xFF0F172A)),
                  onPressed: () async {
                    final uri = Uri.parse('tel:${currentCustomer.mobile}');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
              IconButton(
                tooltip: 'WhatsApp Offer',
                icon: const Icon(Icons.campaign_outlined, color: Color(0xFF0F172A)),
                onPressed: () => viewModel.sendCustomerOffer(currentCustomer),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // ==========================================
                // 1. PROFILE CARD (Clean & Compact)
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26, // Reduced from 28
                            backgroundColor: const Color(0xFFEFF6FF),
                            foregroundColor: const Color(0xFF2563EB),
                            child: Text(
                              initial,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cleanName,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_android, size: 13, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      currentCustomer.mobile.isNotEmpty ? currentCustomer.mobile : 'No Mobile Number',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ),

                      // Quick Summary Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _heroStat('Total Spent', money(totalSpent)),
                          Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                          _heroStat('Bills', '$totalVisits'),
                          Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                          _heroStat('Avg Bill', money(avgSpend)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ==========================================
                // 2. PREFERENCES & NOTES CARD
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune, color: Color(0xFF64748B), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Preferences & Notes',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InfoChip(Icons.straighten, 'Size: ${currentCustomer.size.isNotEmpty ? currentCustomer.size : "Standard"}'),
                          InfoChip(Icons.palette_outlined, 'Color: ${currentCustomer.colors.isNotEmpty ? currentCustomer.colors : "Various"}'),
                          if (currentCustomer.lastItem.isNotEmpty)
                            InfoChip(Icons.shopping_bag_outlined, 'Recent: ${currentCustomer.lastItem}'),
                        ],
                      ),
                      if (currentCustomer.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            'Note: ${currentCustomer.note.trim()}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.3),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ==========================================
                // 3. PURCHASE HISTORY SECTION
                // ==========================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Purchase History (${customerBills.length} Bills)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (customerBills.isNotEmpty)
                      Text(
                        '${customerBills.fold(0, (sum, b) => sum + b.qty)} Pairs Total',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (customerBills.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: _cardDecoration(),
                    child: const Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF94A3B8)),
                        SizedBox(height: 8),
                        Text(
                          'No saved bills found yet.',
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
      },
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}