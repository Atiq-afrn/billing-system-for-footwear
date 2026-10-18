// import 'package:flutter/material.dart';
//
// import '../app/app_colors.dart';
// import '../models/bill.dart';
// import '../models/customer.dart';
// import '../view_models/shop_view_model.dart';
// import '../widgets/shop_widgets.dart';
// import 'customer_details_view.dart';
//
// class CustomersView extends StatefulWidget {
//   const CustomersView({
//     super.key,
//     required this.viewModel,
//     required this.onExportExcel,
//     required this.onSendOffer,
//     required this.onPreviewPdf,
//     required this.onShareBill,
//     this.onStockAlerts,
//   });
//
//   final ShopViewModel viewModel;
//   final VoidCallback onExportExcel;
//   final ValueChanged<Customer> onSendOffer;
//   final ValueChanged<Bill> onPreviewPdf;
//   final ValueChanged<Bill> onShareBill;
//   final VoidCallback? onStockAlerts;
//
//   @override
//   State<CustomersView> createState() => _CustomersViewState();
// }
//
// class _CustomersViewState extends State<CustomersView> {
//   String query = '';
//   DateTime? selectedMonthFilter;
//
//   static const _monthNames = [
//     'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//   ];
//
//   void _openCustomerDetails(Customer customer) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CustomerDetailsView(
//           customer: customer,
//           viewModel: widget.viewModel,
//           onPreviewPdf: widget.onPreviewPdf,
//           onShare: widget.onShareBill,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final customers = widget.viewModel.searchCustomers(query, month: selectedMonthFilter);
//     final availableMonths = widget.viewModel.availableMonths;
//
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Header(
//             title: widget.viewModel.companyName,
//             subtitle: 'Customer Database & History',
//             unreadAlertsCount: widget.viewModel.finishedStockCount,
//             onNotificationsPressed: widget.onStockAlerts,
//           ),
//           const SizedBox(height: 18),
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'Customers (${customers.length})',
//                   style: Theme.of(context).textTheme.headlineMedium,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               FilledButton.icon(
//                 onPressed: widget.onExportExcel,
//                 style: orangeButton(),
//                 icon: const Icon(Icons.table_chart_outlined, size: 18),
//                 label: const Text('Export Excel'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Tap any customer to inspect purchase records, bill history & visit frequency.',
//             style: Theme.of(context).textTheme.bodyMedium,
//           ),
//           const SizedBox(height: 14),
//
//           // Search Field
//           TextField(
//             onChanged: (value) => setState(() => query = value),
//             decoration: InputDecoration(
//               prefixIcon: const Icon(Icons.search, size: 20),
//               hintText: 'Search customer name or mobile number...',
//               suffixIcon: query.isNotEmpty
//                   ? IconButton(
//                       icon: const Icon(Icons.clear, size: 18),
//                       onPressed: () => setState(() => query = ''),
//                     )
//                   : null,
//             ),
//           ),
//           const SizedBox(height: 12),
//
//           // Month-wise Filter Pills
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 ChoiceChip(
//                   label: const Text('All Customers'),
//                   selected: selectedMonthFilter == null,
//                   onSelected: (_) => setState(() => selectedMonthFilter = null),
//                   selectedColor: AppColors.deepNavy,
//                   labelStyle: TextStyle(
//                     color: selectedMonthFilter == null ? Colors.white : AppColors.mainText,
//                     fontWeight: selectedMonthFilter == null ? FontWeight.bold : FontWeight.normal,
//                     fontSize: 12,
//                   ),
//                   visualDensity: VisualDensity.compact,
//                 ),
//                 ...availableMonths.map((m) {
//                   final isSel = selectedMonthFilter != null &&
//                       selectedMonthFilter!.year == m.year &&
//                       selectedMonthFilter!.month == m.month;
//                   final label = '${_monthNames[m.month - 1]} ${m.year}';
//                   return Padding(
//                     padding: const EdgeInsets.only(left: 6),
//                     child: ChoiceChip(
//                       label: Text(label),
//                       selected: isSel,
//                       onSelected: (_) => setState(() => selectedMonthFilter = m),
//                       selectedColor: AppColors.deepNavy,
//                       labelStyle: TextStyle(
//                         color: isSel ? Colors.white : AppColors.mainText,
//                         fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
//                         fontSize: 12,
//                       ),
//                       visualDensity: VisualDensity.compact,
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),
//
//           // Customer List
//           Expanded(
//             child: customers.isEmpty
//                 ? Center(
//                     child: Text(
//                       query.isEmpty
//                           ? 'No customers found for the selected period.'
//                           : 'No matching customers found.',
//                       style: const TextStyle(color: Color(0xFF64748B)),
//                     ),
//                   )
//                 : ListView.separated(
//                     itemCount: customers.length,
//                     separatorBuilder: (_, __) => const SizedBox(height: 10),
//                     itemBuilder: (_, index) {
//                       final customer = customers[index];
//                       return CustomerCard(
//                         customer: customer,
//                         onTap: () => _openCustomerDetails(customer),
//                         onOffer: () => widget.onSendOffer(customer),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class CustomerCard extends StatelessWidget {
//   const CustomerCard({
//     super.key,
//     required this.customer,
//     required this.onTap,
//     required this.onOffer,
//   });
//
//   final Customer customer;
//   final VoidCallback onTap;
//   final VoidCallback onOffer;
//
//   @override
//   Widget build(BuildContext context) {
//     final cleanName = customer.name.trim().isNotEmpty ? customer.name.trim() : 'Walk-in Customer';
//     final initial = cleanName.characters.first.toUpperCase();
//
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: const Color(0xFFE2E8F0)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.02),
//               blurRadius: 6,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 22,
//               backgroundColor: AppColors.deepNavy,
//               foregroundColor: Colors.white,
//               child: Text(
//                 initial,
//                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     cleanName,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w800,
//                       fontSize: 14,
//                       color: AppColors.mainText,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF64748B)),
//                       const SizedBox(width: 4),
//                       Text(
//                         customer.mobile.isNotEmpty ? customer.mobile : 'No Mobile Added',
//                         style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF1F5F9),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Text(
//                           '${customer.visits} ${customer.visits == 1 ? "visit" : "visits"}',
//                           style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         money(customer.totalSpent),
//                         style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             IconButton.filledTonal(
//               tooltip: 'Send WhatsApp offer',
//               onPressed: onOffer,
//               icon: const Icon(Icons.campaign_outlined, size: 20),
//             ),
//             const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import '../view_models/shop_view_model.dart';
import '../widgets/shop_widgets.dart';
import 'customer_details_view.dart';

class CustomersView extends StatefulWidget {
const CustomersView({
super.key,
required this.viewModel,
required this.onExportExcel,
required this.onSendOffer,
required this.onPreviewPdf,
required this.onShareBill,
this.onStockAlerts,
});

final ShopViewModel viewModel;
final VoidCallback onExportExcel;
final ValueChanged<Customer> onSendOffer;
final ValueChanged<Bill> onPreviewPdf;
final ValueChanged<Bill> onShareBill;
final VoidCallback? onStockAlerts;

@override
State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
String query = '';
DateTime? selectedMonthFilter;

static const _monthNames = [
'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

void _openCustomerDetails(Customer customer) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => CustomerDetailsView(
customer: customer,
viewModel: widget.viewModel,
onPreviewPdf: widget.onPreviewPdf,
onShare: widget.onShareBill,
),
),
);
}

@override
Widget build(BuildContext context) {
final customers = widget.viewModel.searchCustomers(
query,
month: selectedMonthFilter,
);
final availableMonths = widget.viewModel.availableMonths;
final theme = Theme.of(context);

return Padding(
padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Header(
title: widget.viewModel.companyName,
subtitle: 'Customer Database & History',
unreadAlertsCount: widget.viewModel.finishedStockCount,
onNotificationsPressed: widget.onStockAlerts,
),

const SizedBox(height: 24),

Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Customers',
style: theme.textTheme.headlineMedium?.copyWith(
fontSize: 23,
fontWeight: FontWeight.w800,
color: AppColors.mainText,
letterSpacing: -0.6,
),
),
const SizedBox(height: 5),
Text(
'${customers.length} customers found',
style: const TextStyle(
fontSize: 12,
color: Color(0xFF64748B),
fontWeight: FontWeight.w500,
),
),
],
),
),
const SizedBox(width: 10),
FilledButton.icon(
onPressed: widget.onExportExcel,
style: orangeButton().copyWith(
padding: const WidgetStatePropertyAll(
EdgeInsets.symmetric(
horizontal: 12,
vertical: 12,
),
),
shape: WidgetStatePropertyAll(
RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10),
),
),
elevation: const WidgetStatePropertyAll(0),
),
icon: const Icon(
Icons.table_chart_outlined,
size: 17,
),
label: const Text(
'Export Excel',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
),
],
),

const SizedBox(height: 8),

Text(
'View customer purchase history, spending and visits.',
style: theme.textTheme.bodyMedium?.copyWith(
fontSize: 12,
height: 1.5,
color: const Color(0xFF64748B),
),
),

const SizedBox(height: 18),

// Customer search.
TextField(
onChanged: (value) => setState(() => query = value),
style: const TextStyle(
fontSize: 13,
color: AppColors.mainText,
fontWeight: FontWeight.w500,
),
decoration: InputDecoration(
prefixIcon: const Icon(
Icons.search_rounded,
size: 21,
color: Color(0xFF64748B),
),
hintText: 'Search customer name or mobile number...',
hintStyle: const TextStyle(
fontSize: 12,
color: Color(0xFF94A3B8),
),
suffixIcon: query.isNotEmpty
? IconButton(
tooltip: 'Clear search',
icon: const Icon(
Icons.close_rounded,
size: 18,
),
onPressed: () => setState(() => query = ''),
)
    : null,
filled: true,
fillColor: Colors.white,
contentPadding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 14,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(
color: Color(0xFFDCE4ED),
),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(
color: Color(0xFFDCE4ED),
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(
color: AppColors.deepNavy,
width: 1.3,
),
),
),
),

const SizedBox(height: 14),

// Month filter chips.
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
_MonthFilterChip(
label: 'All Customers',
selected: selectedMonthFilter == null,
onSelected: () {
setState(() => selectedMonthFilter = null);
},
),
...availableMonths.map((month) {
final isSelected = selectedMonthFilter != null &&
selectedMonthFilter!.year == month.year &&
selectedMonthFilter!.month == month.month;

final label =
'${_monthNames[month.month - 1]} ${month.year}';

return Padding(
padding: const EdgeInsets.only(left: 7),
child: _MonthFilterChip(
label: label,
selected: isSelected,
onSelected: () {
setState(() => selectedMonthFilter = month);
},
),
);
}),
],
),
),

const SizedBox(height: 16),

// Customer list.
Expanded(
child: customers.isEmpty
? Center(
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 24,
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 62,
height: 62,
decoration: BoxDecoration(
color: const Color(0xFFEEF3FA),
borderRadius: BorderRadius.circular(16),
),
child: const Icon(
Icons.people_outline_rounded,
size: 29,
color: AppColors.deepNavy,
),
),
const SizedBox(height: 14),
Text(
query.isEmpty
? 'No customers found for the selected period.'
    : 'No matching customers found.',
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 14,
height: 1.5,
fontWeight: FontWeight.w700,
color: AppColors.mainText,
),
),
const SizedBox(height: 6),
const Text(
'Try another search or select a different month.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 12,
height: 1.5,
color: Color(0xFF64748B),
),
),
],
),
),
)
    : ListView.separated(
padding: const EdgeInsets.only(
top: 5,
bottom: 24,
left: 2,
right: 2,
),
itemCount: customers.length,
separatorBuilder: (_, __) =>
const SizedBox(height: 14),
itemBuilder: (_, index) {
final customer = customers[index];

return CustomerCard(
customer: customer,
onTap: () => _openCustomerDetails(customer),
onOffer: () => widget.onSendOffer(customer),
);
},
),
),
],
),
);
}
}

class _MonthFilterChip extends StatelessWidget {
const _MonthFilterChip({
required this.label,
required this.selected,
required this.onSelected,
});

final String label;
final bool selected;
final VoidCallback onSelected;

@override
Widget build(BuildContext context) {
return ChoiceChip(
label: Text(label),
selected: selected,
onSelected: (_) => onSelected(),
selectedColor: AppColors.deepNavy,
backgroundColor: Colors.white,
side: BorderSide(
color: selected
? AppColors.deepNavy
    : const Color(0xFFDCE4ED),
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(9),
),
labelStyle: TextStyle(
color: selected ? Colors.white : AppColors.mainText,
fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
fontSize: 11,
),
visualDensity: VisualDensity.compact,
padding: const EdgeInsets.symmetric(
horizontal: 5,
vertical: 3,
),
showCheckmark: false,
);
}
}

class CustomerCard extends StatelessWidget {
const CustomerCard({
super.key,
required this.customer,
required this.onTap,
required this.onOffer,
});

final Customer customer;
final VoidCallback onTap;
final VoidCallback onOffer;

@override
Widget build(BuildContext context) {
final cleanName = customer.name.trim().isNotEmpty
? customer.name.trim()
    : 'Walk-in Customer';

final initial = cleanName.substring(0, 1).toUpperCase();

return Container(
// The outer layer creates the subtle raised-card effect.
decoration: BoxDecoration(
color: const Color(0xFFE3E9F1),
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: const Color(0xFF172B4D).withOpacity(0.09),
blurRadius: 13,
spreadRadius: 0,
offset: const Offset(0, 5),
),
BoxShadow(
color: Colors.white.withOpacity(0.9),
blurRadius: 2,
offset: const Offset(-1, -1),
),
],
),
child: Material(
color: Colors.white,
borderRadius: BorderRadius.circular(15),
clipBehavior: Clip.antiAlias,
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(15),
child: Container(
padding: const EdgeInsets.all(13),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(15),
border: Border.all(
color: const Color(0xFFE0E7F0),
width: 1,
),
gradient: const LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
Color(0xFFFFFFFF),
Color(0xFFFBFCFE),
],
),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
// Elevated, compact avatar.
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(13),
gradient: const LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
Color(0xFFF0F5FC),
Color(0xFFDCE7F6),
],
),
border: Border.all(
color: const Color(0xFFD7E2F0),
),
boxShadow: [
BoxShadow(
color: const Color(0xFF19375D)
    .withOpacity(0.08),
blurRadius: 5,
offset: const Offset(0, 2),
),
],
),
alignment: Alignment.center,
child: Text(
initial,
style: const TextStyle(
fontSize: 17,
fontWeight: FontWeight.w800,
color: AppColors.deepNavy,
),
),
),

const SizedBox(width: 12),

// Customer details.
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(
cleanName,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 13,
height: 1.35,
fontWeight: FontWeight.w800,
letterSpacing: 0.05,
color: AppColors.mainText,
),
),

const SizedBox(height: 5),

Row(
children: [
const Icon(
Icons.phone_outlined,
size: 13,
color: Color(0xFF8291A5),
),
const SizedBox(width: 5),
Expanded(
child: Text(
customer.mobile.isNotEmpty
? customer.mobile
    : 'No Mobile Added',
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.w500,
color: Color(0xFF64748B),
),
),
),
],
),

const SizedBox(height: 10),

Wrap(
spacing: 7,
runSpacing: 6,
crossAxisAlignment: WrapCrossAlignment.center,
children: [
_CustomerInfoTag(
icon: Icons.shopping_bag_outlined,
label:
'${customer.visits} ${customer.visits == 1 ? "visit" : "visits"}',
),
_CustomerInfoTag(
icon: Icons.currency_rupee_rounded,
label: money(customer.totalSpent),
isSpending: true,
),
],
),
],
),
),

const SizedBox(width: 9),

// Separate offer button.
Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
decoration: BoxDecoration(
color: const Color(0xFFEAF7EF),
borderRadius: BorderRadius.circular(10),
border: Border.all(
color: const Color(0xFFCBEBD7),
),
boxShadow: [
BoxShadow(
color: const Color(0xFF16803D)
    .withOpacity(0.07),
blurRadius: 5,
offset: const Offset(0, 2),
),
],
),
child: Material(
color: Colors.transparent,
borderRadius: BorderRadius.circular(10),
child: InkWell(
onTap: onOffer,
borderRadius: BorderRadius.circular(10),
child: const SizedBox(
width: 36,
height: 36,
child: Icon(
Icons.campaign_outlined,
size: 19,
color: Color(0xFF16803D),
),
),
),
),
),
const SizedBox(height: 5),
const Text(
'Offer',
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w700,
color: Color(0xFF64748B),
),
),
],
),

const SizedBox(width: 1),

const Icon(
Icons.chevron_right_rounded,
size: 20,
color: Color(0xFF9AA8B9),
),
],
),
),
),
),
);
}
}

class _CustomerInfoTag extends StatelessWidget {
const _CustomerInfoTag({
required this.icon,
required this.label,
this.isSpending = false,
});

final IconData icon;
final String label;
final bool isSpending;

@override
Widget build(BuildContext context) {
final foreground = isSpending
? AppColors.deepNavy
    : const Color(0xFF526174);

return Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 5,
),
decoration: BoxDecoration(
color: isSpending
? const Color(0xFFEAF1FC)
    : const Color(0xFFF4F6F9),
borderRadius: BorderRadius.circular(7),
border: Border.all(
color: isSpending
? const Color(0xFFD7E4F6)
    : const Color(0xFFE5EAF0),
),
boxShadow: [
BoxShadow(
color: const Color(0xFF172B4D).withOpacity(0.025),
blurRadius: 2,
offset: const Offset(0, 1),
),
],
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 11,
color: foreground,
),
const SizedBox(width: 4),
Text(
label,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w800,
color: foreground,
),
),
],
),
);
}
}

