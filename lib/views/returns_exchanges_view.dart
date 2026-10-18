import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../models/product.dart';
import '../models/return_models.dart';
import '../view_models/shop_view_model.dart';
import '../widgets/shop_widgets.dart';

class ReturnsExchangesView extends StatefulWidget {
  const ReturnsExchangesView({
    super.key,
    required this.viewModel,
  });

  final ShopViewModel viewModel;

  @override
  State<ReturnsExchangesView> createState() => _ReturnsExchangesViewState();
}

class _ReturnsExchangesViewState extends State<ReturnsExchangesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  ReturnStatus? _statusFilter;
  ReturnType? _typeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Return & Exchange Management',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16.5,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '${vm.companyName} • Inventory & Refund Control',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Process Return / Exchange',
            icon: const Icon(Icons.add_task_rounded, color: Colors.white),
            onPressed: () => _openProcessReturnWizard(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF1E3A8A),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Returns & Exchanges'),
                      if (vm.pendingApprovalCount > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${vm.pendingApprovalCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(iconMargin: EdgeInsets.zero, text: 'Stock Movements & Audit'),
                const Tab(iconMargin: EdgeInsets.zero, text: 'Reports & Analytics'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReturnsListTab(),
          _buildStockMovementsTab(),
          _buildReportsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.swap_horizontal_circle, size: 20),
        label: const Text('NEW RETURN / EXCHANGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
        onPressed: () => _openProcessReturnWizard(context),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: RETURNS & EXCHANGES LIST
  // ===========================================================================
  Widget _buildReturnsListTab() {
    final allReturns = vm.returns;

    var filtered = allReturns.where((r) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      final text = '${r.id} ${r.billId} ${r.customerName} ${r.mobile}'.toLowerCase();
      return text.contains(q);
    }).toList();

    if (_statusFilter != null) {
      filtered = filtered.where((r) => r.status == _statusFilter).toList();
    }

    if (_typeFilter != null) {
      filtered = filtered.where((r) => r.type == _typeFilter).toList();
    }

    return Column(
      children: [
        // Search & Filters bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by Return ID, Bill ID, Customer...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => setState(() => _searchQuery = ''),
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

              // Filter pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All (${allReturns.length})', _statusFilter == null && _typeFilter == null, () {
                      setState(() {
                        _statusFilter = null;
                        _typeFilter = null;
                      });
                    }),
                    const SizedBox(width: 6),
                    _filterChip(
                      'Pending (${vm.pendingApprovalCount})',
                      _statusFilter == ReturnStatus.pendingApproval,
                      () => setState(() => _statusFilter = ReturnStatus.pendingApproval),
                      color: ReturnStatus.pendingApproval.color,
                    ),
                    const SizedBox(width: 6),
                    _filterChip(
                      'Approved',
                      _statusFilter == ReturnStatus.approved,
                      () => setState(() => _statusFilter = ReturnStatus.approved),
                      color: ReturnStatus.approved.color,
                    ),
                    const SizedBox(width: 6),
                    _filterChip(
                      'Completed',
                      _statusFilter == ReturnStatus.completed,
                      () => setState(() => _statusFilter = ReturnStatus.completed),
                      color: ReturnStatus.completed.color,
                    ),
                    const SizedBox(width: 6),
                    _filterChip(
                      'Exchanges Only',
                      _typeFilter == ReturnType.exchange,
                      () => setState(() => _typeFilter = _typeFilter == ReturnType.exchange ? null : ReturnType.exchange),
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 6),
                    _filterChip(
                      'Returns Only',
                      _typeFilter == ReturnType.returnOnly,
                      () => setState(() => _typeFilter = _typeFilter == ReturnType.returnOnly ? null : ReturnType.returnOnly),
                      color: const Color(0xFF0284C7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(
                  icon: Icons.assignment_return_outlined,
                  title: 'No Return Records Found',
                  subtitle: 'Tap the button below to process a customer return or product exchange.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final record = filtered[index];
                    return _buildReturnRecordCard(record);
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? const Color(0xFF1E3A8A)) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? (color ?? const Color(0xFF1E3A8A)) : const Color(0xFFE2E8F0),
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

  Widget _buildReturnRecordCard(ReturnRecord record) {
    final status = record.status;
    final dateStr =
        '${record.createdAt.day.toString().padLeft(2, '0')}/${record.createdAt.month.toString().padLeft(2, '0')}/${record.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == ReturnStatus.pendingApproval
              ? const Color(0xFFF59E0B)
              : const Color(0xFFE2E8F0),
          width: status == ReturnStatus.pendingApproval ? 1.5 : 1,
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
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: status.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Icon(record.type.icon, size: 18, color: const Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            record.id,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              'Bill: ${record.billId}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${record.customerName} • ${record.mobile} • $dateStr',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        status.displayName.toUpperCase(),
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body: Returned Items & Exchange Items
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Returned Items List
                Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    const Text('RETURNED ITEMS:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
                    const Spacer(),
                    Text('Total: ${money(record.returnedTotalAmount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ...record.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.productName} (Qty: ${item.qty})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Size: ${item.size} | Color: ${item.color} • Reason: ${item.reason}',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.condition.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.condition.shortName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.condition.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Exchange Replacement Items if applicable
                if (record.isExchange && record.exchangeItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text('REPLACEMENT EXCHANGED ITEMS:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
                      const Spacer(),
                      Text('Total: ${money(record.exchangeTotalAmount)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...record.exchangeItems.map((exch) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${exch.productName} (Qty: ${exch.qty})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                                ),
                                Text(
                                  'Size: ${exch.size} | Color: ${exch.color} • Price: ${money(exch.unitPrice)}',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            money(exch.total),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 8),

                // Financial Settlement summary pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: record.isCustomerRefund
                        ? const Color(0xFFFEF2F2)
                        : record.isCustomerPayable
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: record.isCustomerRefund
                          ? const Color(0xFFFECACA)
                          : record.isCustomerPayable
                              ? const Color(0xFFBFDBFE)
                              : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        record.isCustomerRefund
                            ? Icons.money_off_rounded
                            : record.isCustomerPayable
                                ? Icons.payments_rounded
                                : Icons.balance_rounded,
                        size: 16,
                        color: record.isCustomerRefund
                            ? Colors.red
                            : record.isCustomerPayable
                                ? const Color(0xFF1E3A8A)
                                : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.isCustomerRefund
                              ? 'Refund Paid: ${money(record.customerRefundAmount)} (${record.refundMethod})'
                              : record.isCustomerPayable
                                  ? 'Balance Paid by Customer: ${money(record.customerPayableAmount)} (${record.refundMethod})'
                                  : 'Even Exchange (No Balance Due)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: record.isCustomerRefund
                                ? const Color(0xFFDC2626)
                                : record.isCustomerPayable
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      if (record.transactionRef.isNotEmpty)
                        Text(
                          'Ref: ${record.transactionRef}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Action Bar
                Row(
                  children: [
                    // View Receipt Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showReceiptModal(context, record),
                        icon: const Icon(Icons.receipt, size: 14),
                        label: const Text('View Receipt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // WhatsApp Receipt Button
                    IconButton.filledTonal(
                      tooltip: 'Share Receipt on WhatsApp',
                      icon: const Icon(Icons.share, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => vm.sendReturnReceiptWhatsApp(record),
                    ),

                    // Approval Action if pending
                    if (status == ReturnStatus.pendingApproval) ...[
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () async {
                          await vm.updateReturnStatus(record.id, ReturnStatus.approved);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Return approved! Inventory synced.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Reject Return',
                        icon: const Icon(Icons.close, color: Colors.red, size: 18),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _openRejectDialog(context, record),
                      ),
                    ],
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
  // TAB 2: INVENTORY MOVEMENTS AUDIT LOG
  // ===========================================================================
  Widget _buildStockMovementsTab() {
    final movements = vm.stockMovements;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Damaged Stock Quarantine Alert Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vm.damagedStockItemsCount} Damaged / Defective Items',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Quarantined & excluded from available saleable stock.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            const Icon(Icons.history, size: 18, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            Text(
              'Stock Movement History (${movements.length})',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (movements.isEmpty)
          _buildEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No Movements Recorded',
            subtitle: 'Sales, returns, and restocks will generate movement records.',
          )
        else
          ...movements.map((m) {
            final dateStr = '${m.createdAt.day}/${m.createdAt.month} ${m.createdAt.hour}:${m.createdAt.minute.toString().padLeft(2, '0')}';
            final isPositive = m.qtyChange > 0;
            final isNegative = m.qtyChange < 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isPositive
                        ? const Color(0xFFD1FAE5)
                        : isNegative
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFF1F5F9),
                    foregroundColor: isPositive
                        ? const Color(0xFF059669)
                        : isNegative
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF475569),
                    child: Text(
                      isPositive ? '+${m.qtyChange}' : '${m.qtyChange}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.productName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        Text(
                          '${m.typeLabel} • Ref: ${m.referenceId} • $dateStr',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                        if (m.note.isNotEmpty)
                          Text(
                            m.note,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: REPORTS & ANALYTICS
  // ===========================================================================
  Widget _buildReportsTab() {
    final reasons = vm.returnReasonsBreakdown;
    final topReturned = vm.mostReturnedProducts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 2x2 Metric Cards
        Row(
          children: [
            Expanded(
              child: _analyticsCard(
                title: 'Total Returns',
                val: '${vm.totalReturnsCount}',
                sub: 'Items returned',
                icon: Icons.assignment_return,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _analyticsCard(
                title: 'Total Exchanges',
                val: '${vm.totalExchangesCount}',
                sub: 'Product exchanges',
                icon: Icons.swap_horiz,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _analyticsCard(
                title: 'Refunds Disbursed',
                val: money(vm.totalRefundsDisbursed),
                sub: 'Total refund payout',
                icon: Icons.money_off,
                color: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _analyticsCard(
                title: 'Net Exchange Inflow',
                val: money(vm.totalExchangeNetPaid),
                sub: 'Extra amount collected',
                icon: Icons.attach_money,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Return Reasons Breakdown
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
                'Top Return Reasons',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
              ),
              const Divider(height: 16),
              if (reasons.isEmpty)
                const Text('No return reason data available yet.', style: TextStyle(color: Colors.grey, fontSize: 12))
              else
                ...reasons.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Text('${entry.value} returns', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Most Returned Products
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
                'Frequently Returned Footwear Products',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
              ),
              const Divider(height: 16),
              if (topReturned.isEmpty)
                const Text('No return data available yet.', style: TextStyle(color: Colors.grey, fontSize: 12))
              else
                ...topReturned.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Text('${entry.value} units', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
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

  Widget _analyticsCard({
    required String title,
    required String val,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          Text(sub, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  // ===========================================================================
  // PROCESS RETURN & EXCHANGE WIZARD
  // ===========================================================================
  void _openProcessReturnWizard(BuildContext context) {
    Bill? selectedBill;
    ReturnType selectedType = ReturnType.returnOnly;
    final Map<int, int> returnQuantities = {}; // itemIndex -> qty
    final Map<int, String> returnReasons = {};
    final Map<int, ProductCondition> returnConditions = {};

    // Exchange items: selected replacement product
    Product? replacementProduct;
    String replacementSize = '';
    String replacementColor = '';
    int replacementQty = 1;

    String refundMethod = 'Cash';
    final refController = TextEditingController();
    final noteController = TextEditingController();
    ReturnStatus initialStatus = ReturnStatus.completed;

    const reasonsList = [
      'Wrong Size',
      'Wrong Product / Style',
      'Damaged Product',
      'Manufacturing Defect',
      'Customer Preference / Changed Mind',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final allBills = vm.bills;

            // Calculations
            int returnedSubtotal = 0;
            if (selectedBill != null) {
              final items = selectedBill!.allItems;
              for (var i = 0; i < items.length; i++) {
                final qty = returnQuantities[i] ?? 0;
                returnedSubtotal += qty * items[i].price;
              }
            }

            int exchangeSubtotal = 0;
            if (selectedType == ReturnType.exchange && replacementProduct != null) {
              exchangeSubtotal = replacementProduct!.price * replacementQty;
            }

            // Net amount: positive = customer pays extra, negative = refund to customer
            final netDifference = exchangeSubtotal - returnedSubtotal;

            return Container(
              padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(sheetCtx).viewInsets.bottom + 20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sheet Header
                    Row(
                      children: [
                        const Icon(Icons.swap_horizontal_circle, color: Color(0xFF1E3A8A), size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Process Return / Exchange',
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

                    // STEP 1: VERIFY ORIGINAL BILL
                    const Text(
                      'STEP 1: SELECT ORIGINAL BILL (VERIFICATION)',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 6),
                    if (selectedBill == null) ...[
                      DropdownButtonFormField<Bill>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Search or Select Original Bill...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        items: allBills.map((b) {
                          return DropdownMenuItem<Bill>(
                            value: b,
                            child: Text(
                              '${b.id} • ${b.customer} (${b.mobile}) • ${money(b.total)}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              selectedBill = val;
                              returnQuantities.clear();
                              returnReasons.clear();
                              returnConditions.clear();
                              final items = val.allItems;
                              for (var i = 0; i < items.length; i++) {
                                final eligible = vm.getEligibleReturnQty(
                                  val,
                                  items[i].productId,
                                  items[i].size,
                                  items[i].color,
                                );
                                returnQuantities[i] = eligible > 0 ? 1 : 0;
                                returnReasons[i] = 'Wrong Size';
                                returnConditions[i] = ProductCondition.sellable;
                              }
                            });
                          }
                        },
                      ),
                    ] else ...[
                      // Bill Details Card
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long, color: Color(0xFF1E3A8A), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bill: ${selectedBill!.id} • ${selectedBill!.customer}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                                  ),
                                  Text(
                                    'Mobile: ${selectedBill!.mobile} • Date: ${selectedBill!.time.day}/${selectedBill!.time.month}/${selectedBill!.time.year}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => setSheetState(() => selectedBill = null),
                              child: const Text('Change', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // STEP 2: RETURN ITEMS INSPECTION
                      const Text(
                        'STEP 2: SELECT RETURNED ITEMS & INSPECT CONDITION',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 6),
                      ...selectedBill!.allItems.asMap().entries.map((entry) {
                        final i = entry.key;
                        final it = entry.value;
                        final eligible = vm.getEligibleReturnQty(selectedBill!, it.productId, it.size, it.color);
                        final curQty = returnQuantities[i] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(it.productName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                        Text(
                                          'Size: ${it.size} | Color: ${it.color} • Purchased: ${it.qty} (Eligible for return: $eligible)',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: eligible == 0 ? Colors.red : const Color(0xFF64748B),
                                            fontWeight: eligible == 0 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (eligible > 0)
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                                          onPressed: curQty > 0
                                              ? () => setSheetState(() => returnQuantities[i] = curQty - 1)
                                              : null,
                                        ),
                                        Text('$curQty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 18),
                                          onPressed: curQty < eligible
                                              ? () => setSheetState(() => returnQuantities[i] = curQty + 1)
                                              : null,
                                        ),
                                      ],
                                    )
                                  else
                                    const Text('Already Returned', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (curQty > 0) ...[
                                const Divider(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: returnReasons[i] ?? reasonsList.first,
                                        isDense: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Return Reason',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        ),
                                        items: reasonsList
                                            .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 11))))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) setSheetState(() => returnReasons[i] = val);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<ProductCondition>(
                                        value: returnConditions[i] ?? ProductCondition.sellable,
                                        isDense: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Item Condition',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        ),
                                        items: ProductCondition.values
                                            .map((c) => DropdownMenuItem(
                                                value: c,
                                                child: Text(c.shortName, style: TextStyle(fontSize: 11, color: c.color, fontWeight: FontWeight.bold))))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) setSheetState(() => returnConditions[i] = val);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),

                      // STEP 3: TRANSACTION TYPE (RETURN vs EXCHANGE)
                      const Text(
                        'STEP 3: TRANSACTION TYPE',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Return & Refund', style: TextStyle(fontSize: 12))),
                              selected: selectedType == ReturnType.returnOnly,
                              selectedColor: const Color(0xFF1E3A8A),
                              labelStyle: TextStyle(
                                color: selectedType == ReturnType.returnOnly ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) => setSheetState(() => selectedType = ReturnType.returnOnly),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Product Exchange', style: TextStyle(fontSize: 12))),
                              selected: selectedType == ReturnType.exchange,
                              selectedColor: const Color(0xFF1E3A8A),
                              labelStyle: TextStyle(
                                color: selectedType == ReturnType.exchange ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) => setSheetState(() => selectedType = ReturnType.exchange),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // IF EXCHANGE: SELECT REPLACEMENT PRODUCT
                      if (selectedType == ReturnType.exchange) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Replacement Footwear Item:',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Color(0xFF166534)),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<Product>(
                                isExpanded: true,
                                value: replacementProduct,
                                hint: const Text('Choose product from store inventory...', style: TextStyle(fontSize: 12)),
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                                items: vm.products.where((p) => p.stock > 0).map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text('${p.name} • ${money(p.price)} (Stock: ${p.stock})', style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (p) {
                                  if (p != null) {
                                    setSheetState(() {
                                      replacementProduct = p;
                                      replacementSize = p.sizes.isNotEmpty ? p.sizes.first : 'Free';
                                      replacementColor = p.colors.isNotEmpty ? p.colors.first : 'Standard';
                                    });
                                  }
                                },
                              ),
                              if (replacementProduct != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: replacementSize,
                                        isDense: true,
                                        decoration: const InputDecoration(labelText: 'Size', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                                        items: replacementProduct!.sizes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
                                        onChanged: (val) {
                                          if (val != null) setSheetState(() => replacementSize = val);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: replacementColor,
                                        isDense: true,
                                        decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                                        items: replacementProduct!.colors.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 11)))).toList(),
                                        onChanged: (val) {
                                          if (val != null) setSheetState(() => replacementColor = val);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 70,
                                      child: DropdownButtonFormField<int>(
                                        value: replacementQty,
                                        isDense: true,
                                        decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                                        items: List.generate(
                                          replacementProduct!.stock.clamp(1, 5),
                                          (idx) => DropdownMenuItem(value: idx + 1, child: Text('${idx + 1}', style: const TextStyle(fontSize: 11))),
                                        ),
                                        onChanged: (val) {
                                          if (val != null) setSheetState(() => replacementQty = val);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // FINANCIAL DIFFERENCE CARD
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text('Returned Value:', style: TextStyle(fontSize: 11.5)),
                                const Spacer(),
                                Text(money(returnedSubtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (selectedType == ReturnType.exchange) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text('Replacement Value:', style: TextStyle(fontSize: 11.5)),
                                  const Spacer(),
                                  Text(money(exchangeSubtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                            const Divider(height: 12),
                            Row(
                              children: [
                                Text(
                                  netDifference < 0
                                      ? 'REFUND DUE TO CUSTOMER:'
                                      : netDifference > 0
                                          ? 'BALANCE PAYABLE BY CUSTOMER:'
                                          : 'NET BALANCE:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: netDifference < 0
                                        ? Colors.red
                                        : netDifference > 0
                                            ? const Color(0xFF1E3A8A)
                                            : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  money(netDifference.abs()),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: netDifference < 0
                                        ? Colors.red
                                        : netDifference > 0
                                            ? const Color(0xFF1E3A8A)
                                            : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // STEP 4: PAYMENT METHOD & APPROVAL
                      const Text(
                        'STEP 4: REFUND / PAYMENT METHOD & STATUS',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: refundMethod,
                              isDense: true,
                              decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                              items: const [
                                DropdownMenuItem(value: 'Cash', child: Text('Cash', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'UPI', child: Text('UPI / QR', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'Store Credit', child: Text('Store Credit', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'Card', child: Text('Card', style: TextStyle(fontSize: 12))),
                              ],
                              onChanged: (val) {
                                if (val != null) setSheetState(() => refundMethod = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<ReturnStatus>(
                              value: initialStatus,
                              isDense: true,
                              decoration: const InputDecoration(labelText: 'Initial Status', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                              items: const [
                                DropdownMenuItem(value: ReturnStatus.completed, child: Text('Completed (Immediate)', style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: ReturnStatus.pendingApproval, child: Text('Pending Approval', style: TextStyle(fontSize: 11))),
                              ],
                              onChanged: (val) {
                                if (val != null) setSheetState(() => initialStatus = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: refController,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Transaction Ref / UPI UTR (Optional)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SUBMIT BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: returnedSubtotal == 0
                              ? null
                              : () async {
                                  final returnedItems = <ReturnItem>[];
                                  final billItems = selectedBill!.allItems;
                                  for (var i = 0; i < billItems.length; i++) {
                                    final q = returnQuantities[i] ?? 0;
                                    if (q > 0) {
                                      returnedItems.add(
                                        ReturnItem(
                                          productId: billItems[i].productId,
                                          productName: billItems[i].productName,
                                          size: billItems[i].size,
                                          color: billItems[i].color,
                                          qty: q,
                                          unitPrice: billItems[i].price,
                                          reason: returnReasons[i] ?? 'Wrong Size',
                                          condition: returnConditions[i] ?? ProductCondition.sellable,
                                        ),
                                      );
                                    }
                                  }

                                  final exchItems = <ExchangeItem>[];
                                  if (selectedType == ReturnType.exchange && replacementProduct != null) {
                                    exchItems.add(
                                      ExchangeItem(
                                        productId: replacementProduct!.id,
                                        productName: replacementProduct!.name,
                                        size: replacementSize,
                                        color: replacementColor,
                                        qty: replacementQty,
                                        unitPrice: replacementProduct!.price,
                                      ),
                                    );
                                  }

                                  final adminName = (vm.userProfile?.name != null && vm.userProfile!.name.trim().isNotEmpty)
                                      ? vm.userProfile!.name.trim()
                                      : 'Store Owner';

                                  final record = ReturnRecord(
                                    id: 'RET-${DateTime.now().millisecondsSinceEpoch}',
                                    billId: selectedBill!.id,
                                    customerId: selectedBill!.customerId,
                                    customerName: selectedBill!.customer,
                                    mobile: selectedBill!.mobile,
                                    type: selectedType,
                                    status: initialStatus,
                                    returnReason: returnedItems.isNotEmpty ? returnedItems.first.reason : 'Customer Preference',
                                    productCondition: returnedItems.isNotEmpty ? returnedItems.first.condition : ProductCondition.sellable,
                                    returnedTotalAmount: returnedSubtotal,
                                    exchangeTotalAmount: exchangeSubtotal,
                                    netAmount: netDifference,
                                    refundMethod: refundMethod,
                                    refundStatus: initialStatus == ReturnStatus.completed ? 'Completed' : 'Pending',
                                    transactionRef: refController.text.trim(),
                                    approvedBy: adminName,
                                    createdAt: DateTime.now(),
                                    processedAt: initialStatus == ReturnStatus.completed ? DateTime.now() : null,
                                    notes: noteController.text.trim(),
                                    items: returnedItems,
                                    exchangeItems: exchItems,
                                  );

                                  await vm.processReturnOrExchange(record);

                                  if (sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx);
                                    if (mounted) {
                                      _showReceiptModal(context, record);
                                    }
                                  }
                                },
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('SUBMIT & RECORD TRANSACTION', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openRejectDialog(BuildContext context, ReturnRecord record) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Return ${record.id}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide the reason for rejection:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. Returned after policy limit, worn condition...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.updateReturnStatus(
                record.id,
                ReturnStatus.rejected,
                rejectionReason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : 'Does not meet store return policy',
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showReceiptModal(BuildContext context, ReturnRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(18),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF1E3A8A), size: 36),
                    const SizedBox(height: 6),
                    Text(
                      '${vm.companyName.toUpperCase()} POS',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    Text(
                      record.isExchange ? 'EXCHANGE RECEIPT' : 'RETURN & REFUND VOUCHER',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              Text('Transaction ID: ${record.id}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text('Original Bill ID: ${record.billId}', style: const TextStyle(fontSize: 11)),
              Text('Customer: ${record.customerName} (${record.mobile})', style: const TextStyle(fontSize: 11)),
              Text('Date: ${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}', style: const TextStyle(fontSize: 11)),
              const Divider(height: 16),

              const Text('Returned Items:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ...record.items.map((it) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text('${it.productName} (${it.size}/${it.color}) x${it.qty}', style: const TextStyle(fontSize: 11))),
                      Text(money(it.total), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),

              if (record.isExchange && record.exchangeItems.isNotEmpty) ...[
                const Divider(height: 16),
                const Text('Replacement Exchanged Items:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ...record.exchangeItems.map((ex) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text('${ex.productName} (${ex.size}/${ex.color}) x${ex.qty}', style: const TextStyle(fontSize: 11))),
                        Text(money(ex.total), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
              ],
              const Divider(height: 16),

              if (record.isCustomerRefund)
                Row(
                  children: [
                    const Text('Refund Paid:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                    const Spacer(),
                    Text(money(record.customerRefundAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.red)),
                  ],
                )
              else if (record.isCustomerPayable)
                Row(
                  children: [
                    const Text('Balance Paid by Customer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                    const Spacer(),
                    Text(money(record.customerPayableAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E3A8A))),
                  ],
                )
              else
                const Center(
                  child: Text('Even Exchange (Zero Balance)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),

              const SizedBox(height: 8),
              Text('Payment Method: ${record.refundMethod}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              if (record.transactionRef.isNotEmpty)
                Text('Ref/UTR: ${record.transactionRef}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              Text('Processed by: ${record.approvedBy}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              vm.sendReturnReceiptWhatsApp(record);
            },
            icon: const Icon(Icons.share, size: 16, color: Color(0xFF10B981)),
            label: const Text('Share WhatsApp'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
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
