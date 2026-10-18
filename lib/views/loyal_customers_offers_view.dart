import 'package:flutter/material.dart';

import '../models/loyalty_models.dart';
import '../view_models/shop_view_model.dart';
import '../widgets/shop_widgets.dart';
import 'customer_details_view.dart';
import 'pdf_preview_view.dart';

class LoyalCustomersOffersView extends StatefulWidget {
  const LoyalCustomersOffersView({
    super.key,
    required this.viewModel,
  });

  final ShopViewModel viewModel;

  @override
  State<LoyalCustomersOffersView> createState() => _LoyalCustomersOffersViewState();
}

class _LoyalCustomersOffersViewState extends State<LoyalCustomersOffersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _customerSearch = '';
  CustomerSegment? _selectedSegmentFilter;
  bool _onlyOptedIn = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ShopViewModel get vm => widget.viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Loyal Customer & Offers',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '${vm.companyName} • Loyalty Program',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Create New Offer',
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF0F172A)),
            onPressed: () => _openCreateOfferSheet(context),
          ),
          IconButton(
            tooltip: 'Loyalty Settings',
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF0F172A)),
            onPressed: () => _tabController.animateTo(2),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF1E3A8A),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(iconMargin: EdgeInsets.zero, text: 'Customers & VIP'),
                Tab(iconMargin: EdgeInsets.zero, text: 'Offers'),
                Tab(iconMargin: EdgeInsets.zero, text: 'Rules & Points'),
                Tab(iconMargin: EdgeInsets.zero, text: 'Analytics'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomersTab(),
          _buildOffersTab(),
          _buildLoyaltySettingsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: CUSTOMERS & VIP SEGMENTS
  // ===========================================================================
  Widget _buildCustomersTab() {
    final allProfiles = vm.customerLoyaltyProfiles;

    // Filter by search query
    var filtered = allProfiles.where((p) {
      if (_customerSearch.trim().isEmpty) return true;
      final q = _customerSearch.toLowerCase().trim();
      final text = '${p.customer.name} ${p.customer.mobile} ${p.customer.id}'.toLowerCase();
      return text.contains(q);
    }).toList();

    // Filter by segment
    if (_selectedSegmentFilter != null) {
      filtered = filtered.where((p) => p.segment == _selectedSegmentFilter).toList();
    }

    // Filter by consent
    if (_onlyOptedIn) {
      filtered = filtered.where((p) => p.marketingConsent).toList();
    }

    return Column(
      children: [
        // Top summary strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              // Search input
              TextField(
                onChanged: (val) => setState(() => _customerSearch = val),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search customer name or mobile number...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: _customerSearch.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => setState(() => _customerSearch = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Segment Chips horizontally scrollable
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSegmentFilterChip(
                      label: 'All (${allProfiles.length})',
                      isSelected: _selectedSegmentFilter == null,
                      onTap: () => setState(() => _selectedSegmentFilter = null),
                    ),
                    const SizedBox(width: 6),
                    _buildSegmentFilterChip(
                      label: 'VIP (${vm.highSpendingCustomerCount})',
                      isSelected: _selectedSegmentFilter == CustomerSegment.highSpending,
                      color: CustomerSegment.highSpending.color,
                      onTap: () => setState(() => _selectedSegmentFilter = CustomerSegment.highSpending),
                    ),
                    const SizedBox(width: 6),
                    _buildSegmentFilterChip(
                      label: 'Loyal (${vm.loyalCustomerCount})',
                      isSelected: _selectedSegmentFilter == CustomerSegment.loyal,
                      color: CustomerSegment.loyal.color,
                      onTap: () => setState(() => _selectedSegmentFilter = CustomerSegment.loyal),
                    ),
                    const SizedBox(width: 6),
                    _buildSegmentFilterChip(
                      label: 'Regular (${vm.regularCustomerCount})',
                      isSelected: _selectedSegmentFilter == CustomerSegment.regular,
                      color: CustomerSegment.regular.color,
                      onTap: () => setState(() => _selectedSegmentFilter = CustomerSegment.regular),
                    ),
                    const SizedBox(width: 6),
                    _buildSegmentFilterChip(
                      label: 'New (${vm.newCustomerCount})',
                      isSelected: _selectedSegmentFilter == CustomerSegment.newCustomer,
                      color: CustomerSegment.newCustomer.color,
                      onTap: () => setState(() => _selectedSegmentFilter = CustomerSegment.newCustomer),
                    ),
                    const SizedBox(width: 6),
                    _buildSegmentFilterChip(
                      label: 'Inactive (${vm.inactiveCustomerCount})',
                      isSelected: _selectedSegmentFilter == CustomerSegment.inactive,
                      color: CustomerSegment.inactive.color,
                      onTap: () => setState(() => _selectedSegmentFilter = CustomerSegment.inactive),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _onlyOptedIn,
                      onSelected: (val) => setState(() => _onlyOptedIn = val),
                      label: const Text('WhatsApp Opted-In', style: TextStyle(fontSize: 11)),
                      selectedColor: const Color(0xFFD1FAE5),
                      checkmarkColor: const Color(0xFF10B981),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Customer Cards List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No Customers Found',
                  subtitle: 'No customer profiles match your current search or segment filter.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final profile = filtered[index];
                    return _buildCustomerLoyaltyCard(profile);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSegmentFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? const Color(0xFF1E3A8A)) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? const Color(0xFF1E3A8A)) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerLoyaltyCard(CustomerLoyaltyProfile profile) {
    final customer = profile.customer;
    final segment = profile.segment;
    final cleanName = customer.name.trim().isNotEmpty ? customer.name.trim() : 'Walk-in Customer';
    final initial = cleanName.characters.first.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: segment == CustomerSegment.highSpending
              ? const Color(0xFFF59E0B).withOpacity(0.5)
              : const Color(0xFFE2E8F0),
          width: segment == CustomerSegment.highSpending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name, Mobile, Segment Badge, Consent
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: segment.backgroundColor,
                  foregroundColor: segment.color,
                  child: Text(
                    initial,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cleanName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: segment.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(segment.icon, size: 11, color: segment.color),
                                const SizedBox(width: 3),
                                Text(
                                  segment.displayName,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: segment.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            customer.mobile.isNotEmpty ? customer.mobile : 'No Mobile Added',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                          ),
                          const SizedBox(width: 8),
                          // Consent Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: profile.marketingConsent
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              profile.marketingConsent ? 'WhatsApp Opted-In' : 'Opted Out',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: profile.marketingConsent
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Inactive warning if applicable
            if (segment == CustomerSegment.inactive)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEA580C)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'No purchases in ${profile.daysSinceLastPurchase} days. Send a Win-Back discount offer!',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFFC2410C), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Metrics Grid: Visits, Total Spent, Points, Last Purchase
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _metricCol(
                      'Visits',
                      '${profile.totalBills}',
                      const Color(0xFF2563EB),
                    ),
                  ),
                  Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                  Expanded(
                    child: _metricCol(
                      'Total Spent',
                      money(profile.totalSpent),
                      const Color(0xFF0F172A),
                    ),
                  ),
                  Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                  Expanded(
                    child: _metricCol(
                      'Reward Points',
                      '${profile.availablePoints} pts',
                      const Color(0xFFD97706),
                      subtext: '(Worth ${money(profile.pointsWorthRupees)})',
                    ),
                  ),
                  Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                  Expanded(
                    child: _metricCol(
                      'Last Visit',
                      profile.lastPurchaseDate != null
                          ? '${profile.lastPurchaseDate!.day}/${profile.lastPurchaseDate!.month}/${profile.lastPurchaseDate!.year}'
                          : 'Recent',
                      const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Preferences row: Preferred Sizes, Colors, and Top Items
            if (profile.preferredSizes.isNotEmpty || profile.topPurchasedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (profile.preferredSizes.isNotEmpty)
                      _infoBadge(Icons.straighten, 'Size: ${profile.preferredSizes.join(', ')}'),
                    if (profile.preferredColors.isNotEmpty)
                      _infoBadge(Icons.palette_outlined, profile.preferredColors.take(2).join(', ')),
                    if (profile.topPurchasedItems.isNotEmpty)
                      _infoBadge(Icons.shopping_bag_outlined, profile.topPurchasedItems.first),
                  ],
                ),
              ),

            // Bottom Actions Bar
            Row(
              children: [
                // Send WhatsApp Offer Button
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _openSendOfferModal(context, profile),
                    icon: const Icon(Icons.campaign, size: 16),
                    label: const Text(
                      'Send WhatsApp Offer',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Edit Points / Consent Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _openEditLoyaltyDialog(context, profile),
                  icon: const Icon(Icons.military_tech_outlined, size: 15),
                  label: const Text('Points & Consent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),

                // View Details Button
                IconButton.filledTonal(
                  tooltip: 'View Full Purchase History',
                  icon: const Icon(Icons.history, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailsView(
                          customer: profile.customer,
                          viewModel: vm,
                          onPreviewPdf: (bill) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfPreviewView(
                                  bill: bill,
                                  companyName: vm.companyName,
                                  companyAddress: vm.currentCompanyProfile.address,
                                  companyMobile: vm.currentCompanyProfile.mobile,
                                  upiId: vm.upiId,
                                ),
                              ),
                            );
                          },
                          onShare: (bill) => vm.sendBillWhatsApp(bill),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCol(String title, String val, Color color, {String? subtext}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            val,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
          ),
        ),
        if (subtext != null)
          Text(subtext, style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 10, color: Color(0xFF334155), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: OFFERS & PROMOTIONS MANAGEMENT
  // ===========================================================================
  Widget _buildOffersTab() {
    final offers = vm.offers;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('CREATE OFFER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        onPressed: () => _openCreateOfferSheet(context),
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Promotional Offers (${offers.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Create targeted discounts with codes, validity, and footwear categories.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Offers List
          Expanded(
            child: offers.isEmpty
                ? _buildEmptyState(
                    icon: Icons.local_offer_outlined,
                    title: 'No Promotional Offers Yet',
                    subtitle: 'Create customized discount offers for festive events or loyal customers.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return _buildOfferCard(offer);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Offer offer) {
    final isValid = offer.isCurrentlyValid;
    final dateStr =
        '${offer.validFrom.day}/${offer.validFrom.month} - ${offer.validUntil.day}/${offer.validUntil.month}/${offer.validUntil.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isValid ? const Color(0xFFCBD5E1) : const Color(0xFFFCA5A5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Code Badge, Title, Validity Badge, Menu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isValid ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                // Offer Code Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    offer.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    offer.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isValid ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isValid ? 'ACTIVE' : 'EXPIRED',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: isValid ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF64748B)),
                  onSelected: (val) {
                    if (val == 'delete') {
                      _confirmDeleteOffer(offer);
                    } else if (val == 'broadcast') {
                      _broadcastOfferToSegment(offer);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'broadcast',
                      child: Row(
                        children: [
                          Icon(Icons.send_rounded, size: 16, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Text('Broadcast to Segment', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Offer', style: TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Discount amount box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.discount, size: 14, color: Color(0xFFB45309)),
                          const SizedBox(width: 4),
                          Text(
                            offer.discountBadge,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (offer.minSpend > 0)
                            Text(
                              'Min Purchase: ₹${offer.minSpend}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            ),
                          Text(
                            'Target: ${offer.targetSegment}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.event, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      'Validity: $dateStr',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Category: ${offer.applicableCategory}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: LOYALTY RULES & PROGRAM CONFIGURATION
  // ===========================================================================
  Widget _buildLoyaltySettingsTab() {
    final cfg = vm.loyaltyConfig;

    final pointsPer100Ctrl = TextEditingController(text: '${cfg.pointsPer100Spent}');
    final pointValCtrl = TextEditingController(text: '${cfg.pointValueInRupees}');
    final minRedeemCtrl = TextEditingController(text: '${cfg.minRedemptionPoints}');
    final welcomeCtrl = TextEditingController(text: '${cfg.welcomeBonusPoints}');
    final highSpendCtrl = TextEditingController(text: '${cfg.highSpendingThreshold}');
    final loyalVisitsCtrl = TextEditingController(text: '${cfg.loyalVisitsThreshold}');
    final inactiveDaysCtrl = TextEditingController(text: '${cfg.inactiveDaysThreshold}');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top Info Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.workspace_premium, size: 24, color: Color(0xFF1E3A8A)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automated Loyalty Engine',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E3A8A)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Reward customer repeat purchases automatically on every bill generated.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _sectionCard(
          title: 'Points Earning & Redemption Rules',
          icon: Icons.monetization_on_outlined,
          children: [
            _numInput(
              controller: pointsPer100Ctrl,
              label: 'Points Earned per ₹100 Spent',
              helper: 'e.g. 1 point for every ₹100 purchased',
            ),
            const SizedBox(height: 12),
            _numInput(
              controller: pointValCtrl,
              label: 'Value of 1 Point in Rupees (₹)',
              helper: 'e.g. 1.0 means 1 point equals ₹1.0 discount',
              isDecimal: true,
            ),
            const SizedBox(height: 12),
            _numInput(
              controller: minRedeemCtrl,
              label: 'Minimum Points Required to Redeem',
              helper: 'Threshold customer must reach before using points',
            ),
            const SizedBox(height: 12),
            _numInput(
              controller: welcomeCtrl,
              label: 'New Customer Welcome Bonus Points',
              helper: 'Points credited upon first purchase account creation',
            ),
          ],
        ),
        const SizedBox(height: 14),

        _sectionCard(
          title: 'Customer Segmentation Thresholds',
          icon: Icons.group_work_outlined,
          children: [
            _numInput(
              controller: highSpendCtrl,
              label: 'High-Spending VIP Minimum Spent (₹)',
              helper: 'Customer spending ₹5000+ categorized as VIP',
            ),
            const SizedBox(height: 12),
            _numInput(
              controller: loyalVisitsCtrl,
              label: 'Loyal Customer Minimum Visit Count',
              helper: 'e.g. 3 or more shop visits to qualify as Loyal',
            ),
            const SizedBox(height: 12),
            _numInput(
              controller: inactiveDaysCtrl,
              label: 'Inactive / At-Risk Days Threshold',
              helper: 'Flag customer as Inactive if no visit in 45 days',
            ),
          ],
        ),
        const SizedBox(height: 20),

        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            final newConfig = LoyaltyProgramConfig(
              pointsPer100Spent: int.tryParse(pointsPer100Ctrl.text) ?? cfg.pointsPer100Spent,
              pointValueInRupees: double.tryParse(pointValCtrl.text) ?? cfg.pointValueInRupees,
              minRedemptionPoints: int.tryParse(minRedeemCtrl.text) ?? cfg.minRedemptionPoints,
              welcomeBonusPoints: int.tryParse(welcomeCtrl.text) ?? cfg.welcomeBonusPoints,
              highSpendingThreshold: int.tryParse(highSpendCtrl.text) ?? cfg.highSpendingThreshold,
              loyalVisitsThreshold: int.tryParse(loyalVisitsCtrl.text) ?? cfg.loyalVisitsThreshold,
              inactiveDaysThreshold: int.tryParse(inactiveDaysCtrl.text) ?? cfg.inactiveDaysThreshold,
            );
            await vm.updateLoyaltyConfig(newConfig);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Loyalty rules and program configuration saved successfully!'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('SAVE LOYALTY RULES & THRESHOLDS', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _numInput({
    required TextEditingController controller,
    required String label,
    required String helper,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            helperText: helper,
            helperStyle: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: REPORTS & ANALYTICS
  // ===========================================================================
  Widget _buildAnalyticsTab() {
    final topSpenders = vm.topLoyalCustomersBySpending;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Metric KPI Cards 2x2
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                title: 'Loyal Customers',
                value: '${vm.loyalCustomerCount}',
                subtitle: '${vm.customerLoyaltyProfiles.length} Total Registered',
                icon: Icons.star_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                title: 'Repeat Purchase Rate',
                value: '${vm.repeatPurchaseRate.toStringAsFixed(1)}%',
                subtitle: 'Shopped 2+ times',
                icon: Icons.repeat_rounded,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _kpiCard(
                title: 'Points Balance',
                value: '${vm.totalLoyaltyPointsIssued - vm.totalLoyaltyPointsRedeemed}',
                subtitle: '${vm.totalLoyaltyPointsRedeemed} redeemed',
                icon: Icons.monetization_on,
                color: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                title: 'Active Offers',
                value: '${vm.activeOffers.length}',
                subtitle: '${vm.offerTracking.length} offers shared',
                icon: Icons.campaign_rounded,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Customer Segment Breakdown bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Segment Distribution',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              _segmentBarRow('High-Spending VIP', vm.highSpendingCustomerCount, CustomerSegment.highSpending.color),
              _segmentBarRow('Loyal Repeat Shoppers', vm.loyalCustomerCount, CustomerSegment.loyal.color),
              _segmentBarRow('Regular Customers', vm.regularCustomerCount, CustomerSegment.regular.color),
              _segmentBarRow('New First-Time Customers', vm.newCustomerCount, CustomerSegment.newCustomer.color),
              _segmentBarRow('Inactive / At Risk', vm.inactiveCustomerCount, CustomerSegment.inactive.color),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Top Spenders Leaderboard
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events, size: 18, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Text(
                    'Top VIP Customers by Spending',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (topSpenders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No spending data yet.', style: TextStyle(color: Colors.grey)),
                )
              else
                ...topSpenders.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: idx == 0
                              ? const Color(0xFFFEF3C7)
                              : idx == 1
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFF1F5F9),
                          child: Text(
                            '#${idx + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: idx == 0 ? const Color(0xFFB45309) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.customer.name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              Text(
                                '${p.customer.mobile} • ${p.totalBills} visits',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          money(p.totalSpent),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _segmentBarRow(String label, int count, Color color) {
    final total = vm.customerLoyaltyProfiles.length;
    final pct = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$count (${(pct * 100).toStringAsFixed(0)}%)', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODALS & ACTIONS
  // ===========================================================================
  void _openSendOfferModal(BuildContext context, CustomerLoyaltyProfile profile) {
    if (!profile.marketingConsent) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Customer Opted Out'),
          content: Text(
            '${profile.customer.name} has opted out of marketing communications. Would you like to update their preference first or proceed manually?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _openEditLoyaltyDialog(context, profile);
              },
              child: const Text('Manage Consent'),
            ),
          ],
        ),
      );
      return;
    }

    final activeOffers = vm.activeOffers;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Send WhatsApp Offer to ${profile.customer.name}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const Text(
                'Select a promotional offer to send:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 10),
              if (activeOffers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'No active offers available. Create an offer in the Offers tab first, or send standard new arrivals notification.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                  ),
                )
              else
                ...activeOffers.map((offer) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      title: Text(
                        '${offer.title} (${offer.code})',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      subtitle: Text(
                        'Get ${offer.discountBadge} • Valid till ${offer.validUntil.day}/${offer.validUntil.month}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final sent = await vm.sendPersonalizedOffer(profile, offer);
                          if (!sent && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not launch WhatsApp.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.send, size: 14),
                        label: const Text('Send', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await vm.sendCustomerOffer(profile.customer);
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Send General New Footwear Arrival WhatsApp'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEditLoyaltyDialog(BuildContext context, CustomerLoyaltyProfile profile) {
    final pointsCtrl = TextEditingController(text: '${profile.availablePoints}');
    bool consent = profile.marketingConsent;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.military_tech, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Manage ${profile.customer.name}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Adjust Reward Points Balance:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: pointsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      suffixText: 'pts',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Marketing Consent Preference:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('WhatsApp Promotional Offers', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      consent ? 'Customer opted in to offers' : 'Customer opted out from promotions',
                      style: TextStyle(fontSize: 10, color: consent ? Colors.green : Colors.red),
                    ),
                    value: consent,
                    onChanged: (val) => setDialogState(() => consent = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
                  onPressed: () async {
                    final pts = int.tryParse(pointsCtrl.text) ?? profile.availablePoints;
                    await vm.adjustCustomerPoints(profile.customer.id, pts, 'Manual adjustment by owner');
                    await vm.updateCustomerLoyaltyConsent(profile.customer.id, consent);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Customer points and consent updated!')),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openCreateOfferSheet(BuildContext context) {
    final codeCtrl = TextEditingController(text: 'SPECIAL${DateTime.now().millisecond}');
    final titleCtrl = TextEditingController();
    String discountType = 'percentage';
    final discountValCtrl = TextEditingController(text: '15');
    final minSpendCtrl = TextEditingController(text: '999');
    String selectedCategory = 'All Categories';
    String selectedSegment = 'All';
    DateTime validUntil = DateTime.now().add(const Duration(days: 30));

    final categories = ['All Categories', ...vm.allCategories];
    const segments = ['All', 'High-Spending VIP', 'Loyal Customer', 'Regular Customer', 'New Customer', 'Inactive / At Risk'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(sheetCtx).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_shopping_cart, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 8),
                        const Text(
                          'Create New Promotional Offer',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const Divider(),
                    _textInput(controller: codeCtrl, label: 'Offer Promo Code (e.g. DIWALI20, FESTIVE100)'),
                    const SizedBox(height: 10),
                    _textInput(controller: titleCtrl, label: 'Offer Title (e.g. Festive Special Footwear Bonanza)'),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Discount Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: discountType,
                                isDense: true,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                items: const [
                                  DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'fixed', child: Text('Fixed Rupees (₹)', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => discountType = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _textInput(
                            controller: discountValCtrl,
                            label: discountType == 'percentage' ? 'Discount %' : 'Discount ₹',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _textInput(controller: minSpendCtrl, label: 'Min Spend (₹)', keyboardType: TextInputType.number),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Valid Until', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: sheetCtx,
                                    initialDate: validUntil,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) setSheetState(() => validUntil = picked);
                                },
                                icon: const Icon(Icons.calendar_today, size: 14),
                                label: Text('${validUntil.day}/${validUntil.month}/${validUntil.year}', style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Product Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                isDense: true,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => selectedCategory = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Target Segment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: selectedSegment,
                                isDense: true,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                items: segments.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => selectedSegment = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final code = codeCtrl.text.trim().toUpperCase();
                          final title = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'Special Footwear Offer';
                          if (code.isEmpty) return;

                          final newOffer = Offer(
                            id: 'OFFER-${DateTime.now().millisecondsSinceEpoch}',
                            code: code,
                            title: title,
                            discountType: discountType,
                            discountValue: double.tryParse(discountValCtrl.text) ?? 10.0,
                            minSpend: int.tryParse(minSpendCtrl.text) ?? 0,
                            applicableCategory: selectedCategory,
                            targetSegment: selectedSegment,
                            validFrom: DateTime.now(),
                            validUntil: validUntil,
                            messageTemplate: '',
                            isActive: true,
                          );

                          await vm.saveOffer(newOffer);
                          if (context.mounted) {
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Offer "$code" created and activated!')),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('SAVE & PUBLISH OFFER', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _textInput({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteOffer(Offer offer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Offer ${offer.code}?'),
        content: Text('Are you sure you want to delete "${offer.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.deleteOffer(offer.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _broadcastOfferToSegment(Offer offer) {
    final matchingProfiles = vm.customerLoyaltyProfiles.where((p) {
      if (!p.marketingConsent) return false;
      if (offer.targetSegment == 'All') return true;
      return p.segment.displayName == offer.targetSegment;
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Broadcast "${offer.code}"'),
        content: Text(
          'Found ${matchingProfiles.length} eligible customer(s) in "${offer.targetSegment}" who have opted in to WhatsApp promotions.\n\nWould you like to open the WhatsApp offer launcher for this group?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.pop(ctx);
              if (matchingProfiles.isNotEmpty) {
                vm.sendPersonalizedOffer(matchingProfiles.first, offer);
              }
            },
            child: const Text('Start WhatsApp Share'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
