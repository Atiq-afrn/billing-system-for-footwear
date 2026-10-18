
import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/product.dart';
import '../view_models/shop_view_model.dart';
import '../widgets/shop_widgets.dart';

class OutOfStockView extends StatefulWidget {
const OutOfStockView({
super.key,
required this.viewModel,
this.onAddProduct,
});

final ShopViewModel viewModel;

/// Connect this callback to your existing Add Product navigation.
final VoidCallback? onAddProduct;

@override
State<OutOfStockView> createState() => _OutOfStockViewState();
}

class _OutOfStockViewState extends State<OutOfStockView> {
int filterMode = 0;

static const Color _navy = AppColors.deepNavy;
static const Color _background = Color(0xFFF7F8FA);
static const Color _muted = Color(0xFF737B8C);
static const Color _border = Color(0xFFE8EBF0);
static const Color _red = Color(0xFFD94343);
static const Color _orange = Color(0xFFDA851B);
static const Color _green = Color(0xFF25845B);

@override
Widget build(BuildContext context) {
final outOfStock = widget.viewModel.outOfStockProducts;
final lowStock = widget.viewModel.lowStockProducts;

final List<Product> displayList;

if (filterMode == 1) {
displayList = outOfStock;
} else if (filterMode == 2) {
displayList = lowStock;
} else {
displayList = [...outOfStock, ...lowStock];
}

final totalAlerts = outOfStock.length + lowStock.length;

return ColoredBox(
color: _background,
child: Padding(
padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Header(
title: widget.viewModel.companyName,
subtitle: 'Inventory Stock Alerts',
unreadAlertsCount: widget.viewModel.finishedStockCount,
onNotificationsPressed: () {},
),

const SizedBox(height: 18),

// Page heading
Row(
children: [
Expanded(
child: Text(
'Stock alerts',
style: Theme.of(context).textTheme.titleLarge?.copyWith(
color: _navy,
fontWeight: FontWeight.w800,
fontSize: 21,
),
),
),
if (totalAlerts > 0)
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 5,
),
decoration: BoxDecoration(
color: const Color(0xFFFFEEEE),
borderRadius: BorderRadius.circular(20),
),
child: Text(
'$totalAlerts alerts',
style: const TextStyle(
color: _red,
fontSize: 11,
fontWeight: FontWeight.w700,
),
),
),
],
),

const SizedBox(height: 4),

const Text(
'Keep track of products that need replenishment.',
style: TextStyle(
color: _muted,
fontSize: 12,
height: 1.4,
),
),

const SizedBox(height: 16),

// Compact overview cards
Row(
children: [
Expanded(
child: _metricCard(
title: 'Out of stock',
subtitle: '0 pairs',
count: '${outOfStock.length}',
color: _red,
icon: Icons.remove_shopping_cart_outlined,
isSelected: filterMode == 1,
onTap: () => _setFilter(1),
),
),
const SizedBox(width: 10),
Expanded(
child: _metricCard(
title: 'Low stock',
subtitle: '1–3 pairs',
count: '${lowStock.length}',
color: _orange,
icon: Icons.inventory_2_outlined,
isSelected: filterMode == 2,
onTap: () => _setFilter(2),
),
),
],
),

const SizedBox(height: 18),

// Filters
Row(
children: [
const Expanded(
child: Text(
'Products',
style: TextStyle(
color: _navy,
fontSize: 14,
fontWeight: FontWeight.w800,
),
),
),
Text(
'${displayList.length} items',
style: const TextStyle(
color: _muted,
fontSize: 11,
fontWeight: FontWeight.w500,
),
),
],
),

const SizedBox(height: 10),

SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
_filterChip(
label: 'All ($totalAlerts)',
selected: filterMode == 0,
onTap: () => _setFilter(0),
),
const SizedBox(width: 8),
_filterChip(
label: 'Out of stock (${outOfStock.length})',
selected: filterMode == 1,
selectedColor: const Color(0xFFFFEEEE),
selectedTextColor: _red,
onTap: () => _setFilter(1),
),
const SizedBox(width: 8),
_filterChip(
label: 'Low stock (${lowStock.length})',
selected: filterMode == 2,
selectedColor: const Color(0xFFFFF3E4),
selectedTextColor: _orange,
onTap: () => _setFilter(2),
),
],
),
),

const SizedBox(height: 12),

// Stock alert list
Expanded(
child: displayList.isEmpty
? _buildEmptyState()
    : ListView.separated(
padding: const EdgeInsets.only(bottom: 16),
itemCount: displayList.length,
separatorBuilder: (_, __) =>
const SizedBox(height: 9),
itemBuilder: (context, index) {
final product = displayList[index];
final isFinished = product.stock <= 0;

return _productCard(
product: product,
isFinished: isFinished,
);
},
),
),
],
),
),
);
}

void _setFilter(int mode) {
setState(() => filterMode = mode);
}

Widget _metricCard({
required String title,
required String subtitle,
required String count,
required Color color,
required IconData icon,
required bool isSelected,
required VoidCallback onTap,
}) {
return Material(
color: Colors.white,
borderRadius: BorderRadius.circular(13),
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(13),
child: AnimatedContainer(
duration: const Duration(milliseconds: 180),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(13),
border: Border.all(
color: isSelected ? color.withOpacity(0.65) : _border,
width: isSelected ? 1.4 : 1,
),
color: isSelected ? color.withOpacity(0.045) : Colors.white,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 31,
height: 31,
decoration: BoxDecoration(
color: color.withOpacity(0.10),
borderRadius: BorderRadius.circular(9),
),
child: Icon(icon, color: color, size: 17),
),
const Spacer(),
Icon(
Icons.arrow_outward_rounded,
size: 15,
color: color.withOpacity(0.75),
),
],
),
const SizedBox(height: 10),
Text(
count,
style: TextStyle(
color: color,
fontSize: 23,
fontWeight: FontWeight.w800,
height: 1,
),
),
const SizedBox(height: 5),
Text(
title,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: _navy,
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 2),
Text(
subtitle,
style: const TextStyle(
color: _muted,
fontSize: 10,
),
),
],
),
),
),
);
}

Widget _filterChip({
required String label,
required bool selected,
required VoidCallback onTap,
Color selectedColor = _navy,
Color selectedTextColor = Colors.white,
}) {
return Material(
color: selected ? selectedColor : Colors.white,
borderRadius: BorderRadius.circular(9),
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(9),
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 9,
),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(9),
border: Border.all(
color: selected ? selectedColor : _border,
),
),
child: Text(
label,
style: TextStyle(
color: selected ? selectedTextColor : _muted,
fontSize: 11,
fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
),
),
),
),
);
}

Widget _productCard({
required Product product,
required bool isFinished,
}) {
final statusColor = isFinished ? _red : _orange;
final statusBackground = isFinished
? const Color(0xFFFFEEEE)
    : const Color(0xFFFFF3E4);

return Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(13),
border: Border.all(color: _border),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Product status icon
Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: statusBackground,
borderRadius: BorderRadius.circular(11),
),
child: Icon(
isFinished
? Icons.remove_shopping_cart_outlined
    : Icons.warning_amber_rounded,
color: statusColor,
size: 21,
),
),

const SizedBox(width: 10),

// Flexible product details prevent long names overflowing.
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
product.name,
softWrap: true,
style: const TextStyle(
color: _navy,
fontSize: 13,
height: 1.3,
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 4),

Text(
'${product.category} · ID: ${product.id}',
softWrap: true,
style: const TextStyle(
color: _muted,
fontSize: 10,
height: 1.4,
),
),

const SizedBox(height: 8),

Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 5,
),
decoration: BoxDecoration(
color: statusBackground,
borderRadius: BorderRadius.circular(6),
),
child: Text(
isFinished
? 'OUT OF STOCK'
    : 'LOW STOCK · ${product.stock} PAIRS LEFT',
softWrap: true,
style: TextStyle(
color: statusColor,
fontSize: 9,
height: 1.2,
fontWeight: FontWeight.w800,
),
),
),

const SizedBox(height: 10),

// Restock action
SizedBox(
height: 32,
child: OutlinedButton.icon(
onPressed: () => _openAddProduct(context, product),
icon: const Icon(
Icons.add_rounded,
size: 15,
),
label: const Text(
'Restock',
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.w700,
),
),
style: OutlinedButton.styleFrom(
foregroundColor: _navy,
backgroundColor: const Color(0xFFF6F8FC),
side: const BorderSide(color: _border),
padding: const EdgeInsets.symmetric(horizontal: 10),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(8),
),
visualDensity: VisualDensity.compact,
),
),
),
],
),
),

const SizedBox(width: 8),

// Price stays in a separate compact column.
ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 90),
child: Text(
money(product.price),
textAlign: TextAlign.end,
softWrap: true,
style: const TextStyle(
color: _navy,
fontSize: 13,
fontWeight: FontWeight.w800,
),
),
),
],
),
);
}

void _openAddProduct(BuildContext context, Product product) {
if (widget.onAddProduct != null) {
widget.onAddProduct!();
return;
}

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Connect onAddProduct to your existing Add Product navigation.',
),
behavior: SnackBarBehavior.floating,
),
);
}

Widget _buildEmptyState() {
return Center(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 20),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
width: 64,
height: 64,
decoration: BoxDecoration(
color: const Color(0xFFE8F6EF),
borderRadius: BorderRadius.circular(20),
),
child: const Icon(
Icons.inventory_2_outlined,
size: 30,
color: _green,
),
),
const SizedBox(height: 14),
const Text(
'All stock looks good!',
textAlign: TextAlign.center,
style: TextStyle(
color: _navy,
fontSize: 16,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 5),
const Text(
'No products need restocking right now.',
textAlign: TextAlign.center,
style: TextStyle(
color: _muted,
fontSize: 12,
height: 1.5,
),
),
],
),
),
);
}
}

