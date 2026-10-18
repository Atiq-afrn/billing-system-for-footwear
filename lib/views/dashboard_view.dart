import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../models/product.dart';
import '../view_models/shop_view_model.dart';
import '../widgets/product_image_widget.dart';
import '../widgets/shop_widgets.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.viewModel,
    required this.onCreateBill,
    required this.onExportExcel,
    required this.onPreviewPdf,
    required this.onShare,
    this.onStockAlerts,
    this.onViewAllBills,
    this.onViewAllProducts,
  });

  final ShopViewModel viewModel;
  final VoidCallback onCreateBill;
  final VoidCallback onExportExcel;
  final ValueChanged<Bill> onPreviewPdf;
  final ValueChanged<Bill> onShare;
  final VoidCallback? onStockAlerts;
  final VoidCallback? onViewAllBills;
  final VoidCallback? onViewAllProducts;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String selectedChartMetric = 'Sales'; // 'Sales', 'Items', 'Bills'

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  // Global styling for all cards
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final currentMonthName = _monthNames[vm.selectedMonth.month - 1];
        final prevMonthName = _monthNames[vm.previousMonth.month - 1];

        final isPositiveSales = vm.netSalesPercentChange >= 0;
        final salesArrow = isPositiveSales ? '↗' : '↘';

        return Container(
          color: const Color(0xFFF8FAFC), // Very soft grey background
          child: Stack(
            children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), // Space for FAB
            children: [
              // TOP HEADER
              Header(
                title: widget.viewModel.companyName,
                subtitle: 'Sales & Business Overview',
                unreadAlertsCount: widget.viewModel.finishedStockCount,
                onNotificationsPressed: widget.onStockAlerts,
              ),
              const SizedBox(height: 16),

              // MAIN DARK NAVY HERO BANNER
              _buildNetSalesHeroBanner(
                vm: vm,
                currentMonthName: currentMonthName,
                prevMonthName: prevMonthName,
                isPositiveSales: isPositiveSales,
                salesArrow: salesArrow,
              ),
              const SizedBox(height: 16),

              // 4 METRIC CARDS (2x2 Grid)
              _buildMetricCardsGrid(vm: vm),
              const SizedBox(height: 16),

              // SALES COMPARISON LINE CHART
              _buildSalesComparisonCard(
                vm: vm,
                currentMonthName: currentMonthName,
                prevMonthName: prevMonthName,
              ),
              const SizedBox(height: 16),

              // TWO-COLUMN / GRID SECTION: Top Selling Products & Stock Alerts
              _buildTopSellingAndAlerts(vm: vm),
              const SizedBox(height: 16),

              // RECENT BILLS SECTION
              _buildRecentBillsCard(vm: vm),
            ],
          ),

          // CREATE BILL FLOATING BUTTON (Standard Extended FAB)
          Positioned(
            bottom: 24,
            right: 16,
            child: GestureDetector(
              onTap: widget.onCreateBill,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30), // Pill shape
                  boxShadow: [
                    // Soft white glow
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                    // Subtle brand shadow for depth
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.add_rounded,
                      color: Color(0xFF1E3A8A), // Brand blue icon
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Create Bill',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A), // Brand blue text
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCalendarPicker(BuildContext context) async {
    final now = DateTime.now();
    final vm = widget.viewModel;
    final initialMonth = vm.selectedMonth;
    int selectedYear = initialMonth.year;

    final availableYears = <int>{
      now.year,
      now.year - 1,
      now.year - 2,
      ...vm.bills.map((b) => b.time.year),
      initialMonth.year,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month, color: Color(0xFF1E3A8A), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Select Sales Month',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Year Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Year',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                        DropdownButton<int>(
                          value: selectedYear,
                          underline: const SizedBox(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
                          items: availableYears.map((yr) => DropdownMenuItem(value: yr, child: Text('$yr'))).toList(),
                          onChanged: (yr) {
                            if (yr != null) {
                              setDialogState(() => selectedYear = yr);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 12, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 6),

                    // 12 Months Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, idx) {
                        final monthNum = idx + 1;
                        final isSelected = vm.selectedMonth.year == selectedYear && vm.selectedMonth.month == monthNum && vm.selectedDate == null;
                        final isCurrentRealMonth = now.year == selectedYear && now.month == monthNum;

                        return InkWell(
                          onTap: () {
                            Navigator.of(dialogCtx).pop();
                            vm.setSelectedMonth(DateTime(selectedYear, monthNum));
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1E3A8A)
                                  : (isCurrentRealMonth ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1E3A8A)
                                    : (isCurrentRealMonth ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                                width: isSelected || isCurrentRealMonth ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _shortMonths[idx],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected || isCurrentRealMonth ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isCurrentRealMonth ? const Color(0xFF1E3A8A) : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Quick buttons: "Pick Date" and "This Month"
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.of(dialogCtx).pop();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: vm.selectedDate ?? (vm.selectedMonth.isAfter(now) ? now : vm.selectedMonth),
                                firstDate: DateTime(2020),
                                lastDate: now,
                                helpText: 'SELECT DATE',
                              );
                              if (picked != null) {
                                vm.setSelectedDate(picked);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E3A8A),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.today, size: 16),
                            label: const Text('Pick Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () {
                              Navigator.of(dialogCtx).pop();
                              vm.setSelectedMonth(DateTime(now.year, now.month));
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEFF6FF),
                              foregroundColor: const Color(0xFF1E3A8A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('This Month', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Close', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNetSalesHeroBanner({
    required ShopViewModel vm,
    required String currentMonthName,
    required String prevMonthName,
    required bool isPositiveSales,
    required String salesArrow,
  }) {
    final netSales = vm.netSalesSelectedMonth;
    final pctString = vm.netSalesPercentChange.abs().toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Label and Compact Date Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Net Sales ($currentMonthName ${vm.selectedMonth.year})',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openCalendarPicker(context),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 10, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        vm.selectedDate != null
                            ? '${vm.selectedDate!.day} ${_shortMonths[vm.selectedDate!.month - 1]} ${vm.selectedDate!.year}'
                            : '${_shortMonths[vm.selectedMonth.month - 1]} ${vm.selectedMonth.year}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Row: Net Sales (Left) & Today's Sales (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left Side: Net Sales Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${_formatCurrency(netSales)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPositiveSales
                                ? const Color(0xFF22C55E).withOpacity(0.2)
                                : const Color(0xFFEF4444).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$salesArrow $pctString%',
                            style: TextStyle(
                              color: isPositiveSales ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          'vs $prevMonthName',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Side: Today's or Selected Day's Sales Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    vm.selectedDate != null
                        ? '${vm.selectedDate!.day} ${_shortMonths[vm.selectedDate!.month - 1]} Sales'
                        : "Today's Sales",
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_formatCurrency(vm.salesForSelectedDate)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vm.billsForSelectedDate.length} bills • ${vm.billsForSelectedDate.fold(0, (s, b) => s + b.qty)} items',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCardsGrid({required ShopViewModel vm}) {
    final completedBills = vm.completedBillsSelectedMonth;
    final itemsSold = vm.itemsSoldSelectedMonth;
    final avgValue = vm.averageBillValueSelectedMonth;
    final profit = vm.grossProfitSelectedMonth;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.description_outlined,
                title: 'Completed Bills',
                value: '$completedBills',
                pctChange: vm.completedBillsPercentChange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.all_inbox_outlined,
                title: 'Items Sold',
                value: '$itemsSold',
                pctChange: vm.itemsSoldPercentChange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Avg. Bill Value',
                value: '₹${_formatCurrency(avgValue)}',
                pctChange: vm.averageBillValuePercentChange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.currency_rupee,
                title: 'Gross Profit',
                value: '₹${_formatCurrency(profit)}',
                pctChange: vm.grossProfitPercentChange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required double pctChange,
  }) {
    final isPos = pctChange >= 0;
    final arrow = isPos ? '↑' : '↓';
    final changeText = '$arrow ${pctChange.abs().toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // Very light slate
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF475569), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                changeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isPos ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'vs last month',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesComparisonCard({
    required ShopViewModel vm,
    required String currentMonthName,
    required String prevMonthName,
  }) {
    final currentDaily = vm.getDailyMetric(vm.selectedMonth, metric: selectedChartMetric);
    final previousDaily = vm.getDailyMetric(vm.previousMonth, metric: selectedChartMetric);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Comparison',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$currentMonthName vs $prevMonthName',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              // Segmented Pills
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Sales', 'Items', 'Bills'].map((tab) {
                    final isSel = selectedChartMetric == tab;
                    return InkWell(
                      onTap: () => setState(() => selectedChartMetric = tab),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isSel
                              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSel ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legendDot(const Color(0xFF2563EB), 'This Month'),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFFCBD5E1), 'Previous Month'),
            ],
          ),
          const SizedBox(height: 12),

          // Chart
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _SalesComparisonChartPainter(
                currentDaily: currentDaily,
                previousDaily: previousDaily,
                metric: selectedChartMetric,
                currentMonthShort: _shortMonths[vm.selectedMonth.month - 1],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildTopSellingAndAlerts({required ShopViewModel vm}) {
    return Column(
      children: [
        _buildTopSellingCard(vm),
        const SizedBox(height: 16),
        _buildStockAlertsCard(vm),
      ],
    );
  }

  Widget _buildTopSellingCard(ShopViewModel vm) {
    final topList = vm.topSellingProducts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Selling Products',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: widget.onViewAllProducts,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (topList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text('No product sales recorded in ${_monthNames[vm.selectedMonth.month - 1]}.', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              ),
            )
          else
            ...topList.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final item = entry.value;
              final prod = vm.findProductById(item.productId);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      '$rank',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 12),
                    _buildProductThumbnail(prod),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Size ${item.size} • ${item.color}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.quantity} pairs',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '₹${_formatCurrency(item.revenue)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildProductThumbnail(Product? prod) {
    if (prod == null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Icon(Icons.checkroom_outlined, size: 18, color: Color(0xFF64748B)),
      );
    }
    return ProductImageWidget(
      product: prod,
      width: 36,
      height: 36,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildStockAlertsCard(ShopViewModel vm) {
    final lowStock = vm.lowStockProducts;
    final outOfStock = vm.outOfStockProducts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stock Alerts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: widget.onStockAlerts,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Two Pills
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), // Very soft amber
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Low Stock', style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                            Text(
                              '${lowStock.length} items',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2), // Very soft red
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Out of Stock', style: TextStyle(fontSize: 11, color: Color(0xFF991B1B))),
                            Text(
                              '${outOfStock.length} items',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (lowStock.isNotEmpty || outOfStock.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            ...[...outOfStock, ...lowStock].take(3).map((prod) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    _buildProductThumbnail(prod),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qty left: ${prod.stock}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: prod.stock <= 0 ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                      onPressed: widget.onStockAlerts,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentBillsCard({required ShopViewModel vm}) {
    final recentBills = vm.billsForSelectedMonth.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Bills (${_shortMonths[vm.selectedMonth.month - 1]})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: widget.onViewAllBills,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (recentBills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No bills created in ${_monthNames[vm.selectedMonth.month - 1]} ${vm.selectedMonth.year}.', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              ),
            )
          else
          // REPLACED DATATABLE WITH CLEAN LIST VIEW
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentBills.length,
              separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final b = recentBills[index];
                final formattedDate = '${b.time.day} ${_shortMonths[b.time.month - 1]}, ${b.time.hour.toString().padLeft(2, '0')}:${b.time.minute.toString().padLeft(2, '0')}';

                return InkWell(
                  onTap: () => widget.onPreviewPdf(b),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.customer.isNotEmpty ? b.customer : 'Walk-in Customer',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$formattedDate • ${b.payMode}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      // Amount & Badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${_formatCurrency(b.total)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${b.qty} items',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000) {
      final s = amount.toString();
      final lastThree = s.substring(s.length - 3);
      final remaining = s.substring(0, s.length - 3);
      return '$remaining,$lastThree';
    }
    return '$amount';
  }
}

class _SalesComparisonChartPainter extends CustomPainter {
  _SalesComparisonChartPainter({
    required this.currentDaily,
    required this.previousDaily,
    required this.metric,
    required this.currentMonthShort,
  });

  final Map<int, int> currentDaily;
  final Map<int, int> previousDaily;
  final String metric;
  final String currentMonthShort;

  @override
  void paint(Canvas canvas, Size size) {
    const maxDay = 10;
    const leftPadding = 48.0;
    const bottomPadding = 24.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    int maxValue = 6000;
    for (int d = 1; d <= maxDay; d++) {
      if ((currentDaily[d] ?? 0) > maxValue) maxValue = currentDaily[d]!;
      if ((previousDaily[d] ?? 0) > maxValue) maxValue = previousDaily[d]!;
    }
    if (maxValue < 6000) maxValue = 6000;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    final textStyle = const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    final ySteps = [0, (maxValue * 0.33).round(), (maxValue * 0.66).round(), maxValue];
    for (final val in ySteps) {
      final y = chartHeight - (val / maxValue) * chartHeight;
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), gridPaint);

      final label = metric == 'Sales' ? '₹${val >= 1000 ? "${(val / 1000).toStringAsFixed(0)}k" : val}' : '$val';
      final span = TextSpan(text: label, style: textStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 8, y - tp.height / 2));
    }

    for (int d = 1; d <= maxDay; d++) {
      final x = leftPadding + ((d - 1) / (maxDay - 1)) * chartWidth;
      final label = '$d';
      final span = TextSpan(text: label, style: textStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 6));
    }

    _drawLine(
      canvas: canvas,
      daily: previousDaily,
      maxDay: maxDay,
      maxValue: maxValue,
      leftPadding: leftPadding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      color: const Color(0xFFCBD5E1),
      strokeWidth: 2.0,
      dotRadius: 3.0,
    );

    _drawLine(
      canvas: canvas,
      daily: currentDaily,
      maxDay: maxDay,
      maxValue: maxValue,
      leftPadding: leftPadding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      color: const Color(0xFF2563EB),
      strokeWidth: 2.5,
      dotRadius: 4.0,
    );
  }

  void _drawLine({
    required Canvas canvas,
    required Map<int, int> daily,
    required int maxDay,
    required int maxValue,
    required double leftPadding,
    required double chartWidth,
    required double chartHeight,
    required Color color,
    required double strokeWidth,
    required double dotRadius,
  }) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final whiteCenterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int d = 1; d <= maxDay; d++) {
      final val = daily[d] ?? (d * 300 % maxValue);
      final x = leftPadding + ((d - 1) / (maxDay - 1)) * chartWidth;
      final y = chartHeight - (val / maxValue) * chartHeight;

      if (d == 1) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    for (int d = 1; d <= maxDay; d++) {
      final val = daily[d] ?? (d * 300 % maxValue);
      final x = leftPadding + ((d - 1) / (maxDay - 1)) * chartWidth;
      final y = chartHeight - (val / maxValue) * chartHeight;
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      canvas.drawCircle(Offset(x, y), dotRadius - 1.5, whiteCenterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SalesComparisonChartPainter oldDelegate) => true;
}