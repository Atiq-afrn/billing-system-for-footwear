// import 'package:flutter/material.dart';
//
// import '../app/app_colors.dart';
// import '../models/bill.dart';
// import '../view_models/shop_view_model.dart';
// import '../widgets/shop_widgets.dart';
//
// class BillsView extends StatefulWidget {
//   const BillsView({
//     super.key,
//     required this.viewModel,
//     required this.onCreateBill,
//     required this.onPreviewPdf,
//     required this.onShare,
//     this.onStockAlerts,
//   });
//
//   final ShopViewModel viewModel;
//   final VoidCallback onCreateBill;
//   final ValueChanged<Bill> onPreviewPdf;
//   final ValueChanged<Bill> onShare;
//   final VoidCallback? onStockAlerts;
//
//   @override
//   State<BillsView> createState() => _BillsViewState();
// }
//
// class _BillsViewState extends State<BillsView> {
//   String query = '';
//   DateTime? selectedMonthFilter;
//
//   static const _monthNames = [
//     'January', 'February', 'March', 'April', 'May', 'June',
//     'July', 'August', 'September', 'October', 'November', 'December'
//   ];
//
//   static const _shortMonths = [
//     'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     selectedMonthFilter = widget.viewModel.selectedMonth;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final vm = widget.viewModel;
//     final availableMonths = vm.availableMonths;
//
//     final baseBills = selectedMonthFilter == null
//         ? vm.bills
//         : vm.bills.where((b) =>
//             b.time.year == selectedMonthFilter!.year &&
//             b.time.month == selectedMonthFilter!.month).toList();
//
//     final filteredBills = query.isEmpty
//         ? baseBills
//         : baseBills.where((b) {
//             final q = query.toLowerCase();
//             return b.id.toLowerCase().contains(q) ||
//                 b.customer.toLowerCase().contains(q) ||
//                 b.mobile.contains(q) ||
//                 b.item.toLowerCase().contains(q);
//           }).toList();
//
//     final currentMonthTotal = baseBills.fold(0, (sum, b) => sum + b.total);
//     final currentMonthQty = baseBills.fold(0, (sum, b) => sum + b.qty);
//
//     return Stack(
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Header(
//                 title: vm.companyName,
//                 subtitle: 'Sales & Invoices History',
//                 unreadAlertsCount: vm.finishedStockCount,
//                 onNotificationsPressed: widget.onStockAlerts,
//               ),
//               const SizedBox(height: 16),
//
//               // Title and Actions Row
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Sales History',
//                       style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                             color: const Color(0xFF0F2648),
//                             fontWeight: FontWeight.w900,
//                           ),
//                     ),
//                   ),
//                   FilledButton.icon(
//                     onPressed: () async {
//                       final targetMonth = selectedMonthFilter ?? vm.selectedMonth;
//                       final path = await vm.exportMonthlyBills(targetMonth);
//                       if (context.mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text('Exported ${_monthNames[targetMonth.month - 1]} sales to Excel.'),
//                             action: SnackBarAction(
//                               label: 'SHARE',
//                               onPressed: () => vm.shareExcelFile(path),
//                             ),
//                             behavior: SnackBarBehavior.floating,
//                           ),
//                         );
//                       }
//                     },
//                     style: orangeButton(),
//                     icon: const Icon(Icons.table_chart_outlined, size: 16),
//                     label: const Text('Export Month Excel', style: TextStyle(fontSize: 12)),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//
//               // Month Selector Chips Bar
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: [
//                     ChoiceChip(
//                       label: const Text('All Sales'),
//                       selected: selectedMonthFilter == null,
//                       onSelected: (_) => setState(() => selectedMonthFilter = null),
//                       selectedColor: const Color(0xFF0F2648),
//                       labelStyle: TextStyle(
//                         color: selectedMonthFilter == null ? Colors.white : AppColors.mainText,
//                         fontWeight: selectedMonthFilter == null ? FontWeight.bold : FontWeight.normal,
//                         fontSize: 12,
//                       ),
//                       visualDensity: VisualDensity.compact,
//                     ),
//                     ...availableMonths.map((m) {
//                       final isSel = selectedMonthFilter != null &&
//                           selectedMonthFilter!.year == m.year &&
//                           selectedMonthFilter!.month == m.month;
//                       final label = '${_shortMonths[m.month - 1]} ${m.year}';
//                       return Padding(
//                         padding: const EdgeInsets.only(left: 6),
//                         child: ChoiceChip(
//                           label: Text(label),
//                           selected: isSel,
//                           onSelected: (_) => setState(() => selectedMonthFilter = m),
//                           selectedColor: const Color(0xFF0F2648),
//                           labelStyle: TextStyle(
//                             color: isSel ? Colors.white : AppColors.mainText,
//                             fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
//                             fontSize: 12,
//                           ),
//                           visualDensity: VisualDensity.compact,
//                         ),
//                       );
//                     }),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),
//
//               // Monthly Sales Summary Banner
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF0F2648),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           selectedMonthFilter != null
//                               ? '${_monthNames[selectedMonthFilter!.month - 1]} ${selectedMonthFilter!.year} Revenue'
//                               : 'Total All-Time Revenue',
//                           style: const TextStyle(color: Colors.white70, fontSize: 11),
//                         ),
//                         Text(
//                           money(currentMonthTotal),
//                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
//                         ),
//                       ],
//                     ),
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.12),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             '${baseBills.length} Bills',
//                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.12),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             '$currentMonthQty Pairs',
//                             style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 12),
//
//               // Search Input
//               TextField(
//                 onChanged: (v) => setState(() => query = v),
//                 decoration: InputDecoration(
//                   prefixIcon: const Icon(Icons.search, size: 20),
//                   hintText: 'Search bill ID, customer name or phone...',
//                   suffixIcon: query.isNotEmpty
//                       ? IconButton(
//                           icon: const Icon(Icons.clear, size: 18),
//                           onPressed: () => setState(() => query = ''),
//                         )
//                       : null,
//                 ),
//               ),
//               const SizedBox(height: 12),
//
//               // Bills List
//               Expanded(
//                 child: filteredBills.isEmpty
//                     ? Center(
//                         child: Text(
//                           query.isEmpty
//                               ? 'No sales records found for this period.'
//                               : 'No matching bills found.',
//                           style: const TextStyle(color: Color(0xFF64748B)),
//                         ),
//                       )
//                     : ListView.separated(
//                         padding: const EdgeInsets.only(bottom: 80),
//                         itemCount: filteredBills.length,
//                         separatorBuilder: (_, __) => const SizedBox(height: 10),
//                         itemBuilder: (_, index) {
//                           final bill = filteredBills[index];
//                           return BillTile(
//                             bill: bill,
//                             onPdf: () => widget.onPreviewPdf(bill),
//                             onShare: () => widget.onShare(bill),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         ),
//
//         // Create Bill Floating Button
//         Positioned(
//           bottom: 16,
//           right: 16,
//           child: InkWell(
//             onTap: widget.onCreateBill,
//             borderRadius: BorderRadius.circular(35),
//             child: Container(
//               width: 68,
//               height: 68,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFE87A24),
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFFE87A24).withOpacity(0.45),
//                     blurRadius: 16,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: const Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.add, color: Colors.white, size: 22),
//                   Text(
//                     'Create Bill',
//                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/bill.dart';
import '../view_models/shop_view_model.dart';
import '../widgets/shop_widgets.dart';

class BillsView extends StatefulWidget {
  const BillsView({
    super.key,
    required this.viewModel,
    required this.onCreateBill,
    required this.onPreviewPdf,
    required this.onShare,
    this.onStockAlerts,
  });

  final ShopViewModel viewModel;
  final VoidCallback onCreateBill;
  final ValueChanged<Bill> onPreviewPdf;
  final ValueChanged<Bill> onShare;
  final VoidCallback? onStockAlerts;

  @override
  State<BillsView> createState() => _BillsViewState();
}

class _BillsViewState extends State<BillsView> {
  String query = '';
  DateTime? selectedMonthFilter;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _navy = Color(0xFF142D50);
  static const _muted = Color(0xFF78869A);
  static const _border = Color(0xFFE5EAF1);
  static const _pageBackground = Color(0xFFF7F9FC);
  static const _orange = Color(0xFFED8128);

  @override
  void initState() {
    super.initState();
    selectedMonthFilter = widget.viewModel.selectedMonth;
  }

  Future<void> _showMonthPicker() async {
    final now = DateTime.now();
    final initial = selectedMonthFilter ?? widget.viewModel.selectedMonth;
    int selectedYear = initial.year;
    int selectedMonth = initial.month;

    final availableYears = <int>{
      now.year,
      ...widget.viewModel.bills.map((bill) => bill.time.year),
      if (selectedMonthFilter != null) selectedMonthFilter!.year,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    final result = await showDialog<DateTime?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: const Text(
                'Select sales month',
                style: TextStyle(
                  color: _navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedYear,
                      decoration: InputDecoration(
                        labelText: 'Year',
                        filled: true,
                        fillColor: _pageBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _border),
                        ),
                      ),
                      items: availableYears
                          .map((year) => DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      ))
                          .toList(),
                      onChanged: (year) {
                        if (year != null) {
                          setDialogState(() => selectedYear = year);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Month',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.25,
                      ),
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final selected = month == selectedMonth;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              setDialogState(() => selectedMonth = month),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? _navy : _pageBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? _navy : _border,
                              ),
                            ),
                            child: Text(
                              _shortMonths[index],
                              style: TextStyle(
                                color: selected ? Colors.white : _navy,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(DateTime(1)),
                  child: const Text(
                    'All sales',
                    style: TextStyle(color: _muted),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext)
                      .pop(DateTime(selectedYear, selectedMonth)),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      selectedMonthFilter = result.year == 1 ? null : result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final theme = Theme.of(context);

    final baseBills = selectedMonthFilter == null
        ? vm.bills
        : vm.bills
        .where(
          (bill) =>
      bill.time.year == selectedMonthFilter!.year &&
          bill.time.month == selectedMonthFilter!.month,
    )
        .toList();

    final normalizedQuery = query.trim().toLowerCase();

    final filteredBills = normalizedQuery.isEmpty
        ? baseBills
        : baseBills.where((bill) {
      return bill.id.toLowerCase().contains(normalizedQuery) ||
          bill.customer.toLowerCase().contains(normalizedQuery) ||
          bill.mobile.contains(normalizedQuery) ||
          bill.item.toLowerCase().contains(normalizedQuery);
    }).toList();

    final currentMonthTotal =
    baseBills.fold<num>(0, (sum, bill) => sum + bill.total);

    final currentMonthQty =
    baseBills.fold<int>(0, (sum, bill) => sum + bill.qty);

    return Container(
      color: _pageBackground,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(
                  title: vm.companyName,
                  subtitle: 'Sales & Invoices History',
                  unreadAlertsCount: vm.finishedStockCount,
                  onNotificationsPressed: widget.onStockAlerts,
                ),

                const SizedBox(height: 16),

                // Page title and export.
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales History',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              color: _navy,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.55,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${filteredBills.length} bills found',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ExportButton(
                      onPressed: () async {
                        final targetMonth =
                            selectedMonthFilter ?? vm.selectedMonth;

                        final path =
                        await vm.exportMonthlyBills(targetMonth);

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Exported ${_monthNames[targetMonth.month - 1]} '
                                  'sales to Excel.',
                            ),
                            action: SnackBarAction(
                              label: 'SHARE',
                              onPressed: () => vm.shareExcelFile(path),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Search with an integrated month/year calendar picker.
                _BillSearchField(
                  query: query,
                  selectedMonthLabel: selectedMonthFilter == null
                      ? 'All sales'
                      : '${_shortMonths[selectedMonthFilter!.month - 1]} '
                      '${selectedMonthFilter!.year}',
                  onChanged: (value) => setState(() => query = value),
                  onClear: () => setState(() => query = ''),
                  onPickMonth: _showMonthPicker,
                ),

                const SizedBox(height: 12),

                // Compact sales overview.
                _SalesSummaryCard(
                  title: selectedMonthFilter != null
                      ? '${_monthNames[selectedMonthFilter!.month - 1]} '
                      '${selectedMonthFilter!.year}'
                      : 'All-time sales',
                  revenue: money(currentMonthTotal),
                  billCount: baseBills.length,
                  pairCount: currentMonthQty,
                ),

                const SizedBox(height: 18),

                // Invoice section heading.
                Row(
                  children: [
                    const Text(
                      'Bills',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF1F9),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${filteredBills.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: _navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                Expanded(
                  child: filteredBills.isEmpty
                      ? _EmptyBillsState(
                    message: normalizedQuery.isEmpty
                        ? 'No sales records found for this period.'
                        : 'No matching bills found.',
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.only(
                      top: 3,
                      left: 1,
                      right: 1,
                      bottom: 100,
                    ),
                    itemCount: filteredBills.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 11),
                    itemBuilder: (context, index) {
                      final bill = filteredBills[index];

                      return _ElevatedBillCard(
                        child: BillTile(
                          bill: bill,
                          onPdf: () => widget.onPreviewPdf(bill),
                          onShare: () => widget.onShare(bill),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Floating Create Bill action.
          Positioned(
            right: 18,
            bottom: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onCreateBill,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF59A4C),
                        Color(0xFFE8751B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFFFBC80),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _orange.withOpacity(0.23),
                        blurRadius: 13,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Create Bill',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _BillsViewState._border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF142D50).withOpacity(0.035),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.file_download_outlined,
                size: 17,
                color: _BillsViewState._navy,
              ),
              SizedBox(width: 6),
              Text(
                'Export',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _BillsViewState._navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesSummaryCard extends StatelessWidget {
  const _SalesSummaryCard({
    required this.title,
    required this.revenue,
    required this.billCount,
    required this.pairCount,
  });

  final String title;
  final String revenue;
  final int billCount;
  final int pairCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _BillsViewState._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 17,
                color: _BillsViewState._muted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _BillsViewState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Text(
                'REVENUE',
                style: TextStyle(
                  color: _BillsViewState._muted,
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            revenue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _BillsViewState._navy,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _BillsViewState._border),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _CompactSummaryMetric(
                  icon: Icons.receipt_long_outlined,
                  label: 'Total bills',
                  value: '$billCount',
                ),
              ),
              Container(width: 1, height: 28, color: _BillsViewState._border),
              Expanded(
                child: _CompactSummaryMetric(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Pairs sold',
                  value: '$pairCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactSummaryMetric extends StatelessWidget {
  const _CompactSummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF718096)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _BillsViewState._muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _BillsViewState._navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillSearchField extends StatelessWidget {
  const _BillSearchField({
    required this.query,
    required this.selectedMonthLabel,
    required this.onChanged,
    required this.onClear,
    required this.onPickMonth,
  });

  final String query;
  final String selectedMonthLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _BillsViewState._border),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.mainText,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF718096),
          ),
          hintText: 'Search bills, customers or phone',
          hintStyle: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF9AA6B6),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (query.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: _BillsViewState._muted,
                  ),
                  onPressed: onClear,
                ),
              Tooltip(
                message: 'Choose month and year • $selectedMonthLabel',
                child: IconButton(
                  onPressed: onPickMonth,
                  tooltip: 'Choose month and year',
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: _BillsViewState._navy,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: _BillsViewState._navy,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ElevatedBillCard extends StatelessWidget {
  const _ElevatedBillCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE3E9F1),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withOpacity(0.065),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 1,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _EmptyBillsState extends StatelessWidget {
  const _EmptyBillsState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF2F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFDDE6F1),
                ),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 26,
                color: _BillsViewState._navy,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: _BillsViewState._navy,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Try another search or choose a different month.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: _BillsViewState._muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
