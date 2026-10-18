import 'dart:io';
import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/bill.dart';
import '../view_models/shop_view_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final currentMonthName = _monthNames[vm.selectedMonth.month - 1];
    final prevMonthName = _monthNames[vm.previousMonth.month - 1];

    final isPositiveSales = vm.netSalesPercentChange >= 0;
    final salesArrow = isPositiveSales ? '↗' : '↘';

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            // TOP HEADER: Brand Avatar, Title, Subtitle, Notifications Bell (Identical across all pages)
            Header(
              title: widget.viewModel.companyName,
              subtitle: 'Sales & Business Overview',
              unreadAlertsCount: widget.viewModel.finishedStockCount,
              onNotificationsPressed: widget.onStockAlerts,
            ),
            const SizedBox(height: 16),

            // MAIN DARK NAVY HERO BANNER: Net Sales & Today's Sales
            _buildNetSalesHeroBanner(
              vm: vm,
              currentMonthName: currentMonthName,
              prevMonthName: prevMonthName,
              isPositiveSales: isPositiveSales,
              salesArrow: salesArrow,
            ),
            const SizedBox(height: 14),

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

        // CREATE BILL FLOATING BUTTON (as in Image 2)
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildCreateBillFloatingButton(),
        ),
      ],
    );
  }

  Future<void> _openCalendarPicker(BuildContext context) async {
    final now = DateTime.now();
    final currentSelected = widget.viewModel.selectedMonth;
    final initialDate = currentSelected.isAfter(now) ? now : currentSelected;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: now, // Future dates cannot be selected!
      helpText: 'SELECT SALES FILTER DATE',
      cancelText: 'CANCEL',
      confirmText: 'APPLY FILTER',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F2648),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F2648),
              secondary: AppColors.accent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      widget.viewModel.setSelectedMonth(pickedDate);
    }
  }

  Widget _buildNetSalesHeroBanner({
    required ShopViewModel vm,
    required String currentMonthName,
    required String prevMonthName,
    required bool isPositiveSales,
    required String salesArrow,
  }) {
    final netSales = vm.netSalesSelectedMonth > 0 ? vm.netSalesSelectedMonth : vm.todaySales;
    final pctString = vm.netSalesPercentChange.abs().toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Blue App Bar
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331E3A8A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      // decoration: BoxDecoration(
      //   gradient: const LinearGradient(
      //     colors: [Color(0xFF0E223D), Color(0xFF16325C)],
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //   ),
      //   borderRadius: BorderRadius.circular(18),
      //   boxShadow: [
      //     BoxShadow(
      //       color: const Color(0xFF0E223D).withOpacity(0.25),
      //       blurRadius: 16,
      //       offset: const Offset(0, 6),
      //     ),
      //   ],
      // ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Net Sales
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Net Sales',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_month, color: Colors.white70, size: 10),
                              SizedBox(width: 4),
                              Text('Month to Date', style: TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Date Filter right under Month to Date (opens calendar with no future dates allowed)
                    InkWell(
                      onTap: () => _openCalendarPicker(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_calendar, size: 12, color: AppColors.accent),
                              const SizedBox(width: 5),
                              Text(
                                '${_shortMonths[vm.selectedMonth.month - 1]} ${vm.selectedMonth.day}, ${vm.selectedMonth.year}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${_formatCurrency(netSales)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          '$salesArrow $pctString%',
                          style: TextStyle(
                            color: isPositiveSales ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'vs $prevMonthName 1–${vm.selectedMonth.day}, ${vm.selectedMonth.year}',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                width: 1,
                height: 80,
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),

              // Right: Today's Sales
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Today's Sales",
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_formatCurrency(vm.todaySales)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vm.todayBills.length} bills  •  ${vm.todayBills.fold(0, (s, b) => s + b.qty)} items',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCardsGrid({required ShopViewModel vm}) {
    final completedBills = vm.completedBillsSelectedMonth > 0 ? vm.completedBillsSelectedMonth : vm.bills.length;
    final itemsSold = vm.itemsSoldSelectedMonth > 0 ? vm.itemsSoldSelectedMonth : vm.bills.fold(0, (s, b) => s + b.qty);
    final avgValue = vm.averageBillValueSelectedMonth > 0 ? vm.averageBillValueSelectedMonth : (completedBills > 0 ? (vm.todaySales / (completedBills == 0 ? 1 : completedBills)).round() : 0);
    final profit = vm.grossProfitSelectedMonth > 0 ? vm.grossProfitSelectedMonth : (vm.todaySales * 0.235).round();

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
                value: '$itemsSold pairs',
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
                title: 'Average Bill Value',
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
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
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F2648),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  changeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isPos ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'vs last month',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title & Metric Filter Pills
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Comparison',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F2648),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$currentMonthName 1–${DateTime.now().day}, ${vm.selectedMonth.year} vs $prevMonthName',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              // Segmented Pills: Sales | Items | Bills
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF0F2648) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSel ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Legend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legendDot(const Color(0xFF2563EB), 'This Month'),
              const SizedBox(width: 14),
              _legendDot(const Color(0xFF94A3B8), 'Previous Month'),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Line Chart Canvas
          SizedBox(
            height: 170,
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
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildTopSellingAndAlerts({required ShopViewModel vm}) {
    return Column(
      children: [
        // Top Selling Products Card
        _buildTopSellingCard(vm),
        const SizedBox(height: 16),
        // Stock Alerts Card
        _buildStockAlertsCard(vm),
      ],
    );
  }

  Widget _buildTopSellingCard(ShopViewModel vm) {
    final topList = vm.topSellingProducts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F2648),
                ),
              ),
              InkWell(
                onTap: widget.onViewAllProducts,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('By Quantity', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (topList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text('No product sales recorded yet.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              ),
            )
          else
            ...topList.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final item = entry.value;
              final prod = vm.findProductById(item.productId);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(
                      '$rank',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F2648)),
                    ),
                    const SizedBox(width: 12),
                    // Product image / thumbnail
                    _buildProductThumbnail(prod?.imagePath),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F2648)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Size ${item.size}  •  ${item.color}',
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
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F2648)),
                        ),
                        Text(
                          '₹${_formatCurrency(item.revenue)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F2648)),
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

  Widget _buildProductThumbnail(String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(imagePath), width: 38, height: 38, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.checkroom_outlined, size: 20, color: Color(0xFF0F2648)),
    );
  }

  Widget _buildStockAlertsCard(ShopViewModel vm) {
    final lowStock = vm.lowStockProducts;
    final outOfStock = vm.outOfStockProducts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F2648),
                ),
              ),
              InkWell(
                onTap: widget.onStockAlerts,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Two Pills: Low Stock & Out of Stock
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Low Stock', style: TextStyle(fontSize: 11, color: Color(0xFF9A3412))),
                            Text(
                              '${lowStock.length} products',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFC2410C)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Out of Stock', style: TextStyle(fontSize: 11, color: Color(0xFF991B1B))),
                            Text(
                              '${outOfStock.length} products',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFB91C1C)),
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
          const SizedBox(height: 14),

          // Recently Low Stock Sublist
          if (lowStock.isNotEmpty || outOfStock.isNotEmpty) ...[
            const Text(
              'Recently Low Stock',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            ...[...outOfStock, ...lowStock].take(3).map((prod) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _buildProductThumbnail(prod.imagePath),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F2648)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Size ${prod.sizes.isNotEmpty ? prod.sizes.first : "All"}  •  ${prod.colors.isNotEmpty ? prod.colors.first : "Standard"}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          Text(
                            'Qty: ${prod.stock} (Threshold: 5)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: prod.stock <= 0 ? Colors.red : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                      onPressed: widget.onStockAlerts,
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
    final recentBills = vm.bills.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Bills',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F2648),
                ),
              ),
              InkWell(
                onTap: widget.onViewAllBills,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (recentBills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No bills created yet. Click "+ Create Bill" below.', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                horizontalMargin: 0,
                columnSpacing: 18,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
                columns: const [
                  DataColumn(label: Text('Bill No.')),
                  DataColumn(label: Text('Date & Time')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Items')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Payment')),
                  DataColumn(label: Text('Action')),
                ],
                rows: recentBills.map((b) {
                  final formattedDate =
                      '${b.time.day} ${_shortMonths[b.time.month - 1]} ${b.time.year}, ${b.time.hour.toString().padLeft(2, '0')}:${b.time.minute.toString().padLeft(2, '0')}';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          b.id.length > 8 ? b.id.substring(b.id.length - 7) : b.id,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F2648)),
                        ),
                      ),
                      DataCell(Text(formattedDate, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                      DataCell(
                        Text(
                          b.customer.isNotEmpty ? b.customer : 'Walk-in',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                      DataCell(Text('${b.qty}', style: const TextStyle(fontSize: 12))),
                      DataCell(
                        Text(
                          '₹${_formatCurrency(b.total)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0F2648)),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            b.payMode,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF2563EB)),
                          onPressed: () => widget.onPreviewPdf(b),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateBillFloatingButton() {
    return InkWell(
      onTap: widget.onCreateBill,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFE87A24),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE87A24).withOpacity(0.50),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white, size: 24),
            Text(
              'Create Bill',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ],
        ),
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
    const maxDay = 10; // Comparing 1-10 as in the reference design
    const leftPadding = 48.0;
    const bottomPadding = 24.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    // Find max value
    int maxValue = 6000;
    for (int d = 1; d <= maxDay; d++) {
      if ((currentDaily[d] ?? 0) > maxValue) maxValue = currentDaily[d]!;
      if ((previousDaily[d] ?? 0) > maxValue) maxValue = previousDaily[d]!;
    }
    if (maxValue < 6000) maxValue = 6000;

    // Grid lines & Y Axis labels
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
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

    // X Axis Day Labels
    for (int d = 1; d <= maxDay; d++) {
      final x = leftPadding + ((d - 1) / (maxDay - 1)) * chartWidth;
      final label = '$d $currentMonthShort';
      final span = TextSpan(text: label, style: textStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 6));
    }

    // Draw Previous Month Line (Grey)
    _drawLine(
      canvas: canvas,
      daily: previousDaily,
      maxDay: maxDay,
      maxValue: maxValue,
      leftPadding: leftPadding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      color: const Color(0xFF94A3B8),
      strokeWidth: 2.0,
      dotRadius: 3.5,
    );

    // Draw This Month Line (Royal Blue)
    _drawLine(
      canvas: canvas,
      daily: currentDaily,
      maxDay: maxDay,
      maxValue: maxValue,
      leftPadding: leftPadding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      color: const Color(0xFF2563EB),
      strokeWidth: 2.8,
      dotRadius: 4.5,
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
