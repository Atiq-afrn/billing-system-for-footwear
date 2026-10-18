
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_colors.dart';
import '../models/product.dart';
import '../models/product_draft.dart';
import '../widgets/shop_widgets.dart';
import 'qr_scanner_view.dart';

class AddProductSheet extends StatefulWidget {
const AddProductSheet({
super.key,
required this.onSave,
this.products = const [],
this.categories = const [],
this.onAddCategory,
this.onRemoveCategory,
});

final ValueChanged<ProductDraft> onSave;
final List<Product> products;
final List<String> categories;
final ValueChanged<String>? onAddCategory;
final ValueChanged<String>? onRemoveCategory;

@override
State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
final formKey = GlobalKey<FormState>();

final nameController = TextEditingController();
final priceController = TextEditingController();
final stockController = TextEditingController(text: '10');
final customSizeController = TextEditingController();
final customColorController = TextEditingController();

String category = 'Men Formal';
String? pickedImagePath;

late List<String> availableCategories;

static const defaultCategories = [
'Men Formal',
'Men Casual',
'Men Sports',
'Women Heels',
'Women Flats',
'Women Sandals',
'Kids',
'Accessories',
];

static const popularSizes = [
'5', '6', '7', '8', '9', '10', '11',
];

static const popularColors = [
'Black', 'Brown', 'Tan', 'White', 'Blue', 'Grey',
];

final Set<String> selectedSizes = {
'6', '7', '8', '9', '10',
};

final Set<String> selectedColors = {
'Black', 'Brown', 'Tan',
};

static const Color _background = Color(0xFFF6F8FB);
static const Color _border = Color(0xFFE2E8F0);
static const Color _muted = Color(0xFF64748B);
static const Color _heading = Color(0xFF172B4D);
static const Color _fieldBackground = Color(0xFFFBFCFE);

@override
void initState() {
super.initState();

final initialList = widget.categories.isNotEmpty
? widget.categories
    : defaultCategories;

availableCategories = List<String>.from(initialList);

if (!availableCategories.contains(category)) {
if (availableCategories.isNotEmpty) {
category = availableCategories.first;
} else {
availableCategories.add(category);
}
}
}

@override
void dispose() {
nameController.dispose();
priceController.dispose();
stockController.dispose();
customSizeController.dispose();
customColorController.dispose();
super.dispose();
}

InputDecoration _inputDecoration({
required String label,
String? hint,
IconData? icon,
Widget? suffixIcon,
}) {
return InputDecoration(
labelText: label,
hintText: hint,
prefixIcon: icon == null
? null
    : Icon(icon, size: 18, color: _muted),
suffixIcon: suffixIcon,
isDense: true,
filled: true,
fillColor: _fieldBackground,
contentPadding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 12,
),
labelStyle: const TextStyle(
fontSize: 12,
color: _muted,
fontWeight: FontWeight.w500,
),
floatingLabelStyle: const TextStyle(
fontSize: 12,
color: AppColors.deepNavy,
fontWeight: FontWeight.w600,
),
hintStyle: const TextStyle(
fontSize: 12,
color: Color(0xFF94A3B8),
fontWeight: FontWeight.w400,
),
errorStyle: const TextStyle(
fontSize: 10,
height: 1.2,
),
prefixIconConstraints: const BoxConstraints(
minWidth: 40,
minHeight: 40,
),
suffixIconConstraints: const BoxConstraints(
minWidth: 36,
minHeight: 36,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide: const BorderSide(color: _border),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide: const BorderSide(color: _border),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide: const BorderSide(
color: AppColors.deepNavy,
width: 1.3,
),
),
errorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide: const BorderSide(color: AppColors.error),
),
focusedErrorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide: const BorderSide(
color: AppColors.error,
width: 1.2,
),
),
);
}

Future<void> _pickImage(ImageSource source) async {
try {
final picker = ImagePicker();

final picked = await picker.pickImage(
source: source,
maxWidth: 1024,
maxHeight: 1024,
imageQuality: 85,
);

if (picked != null && mounted) {
setState(() {
pickedImagePath = picked.path;
});
}
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Could not pick image: $e'),
behavior: SnackBarBehavior.floating,
),
);
}
}

void _showImageSourceDialog() {
showModalBottomSheet(
context: context,
backgroundColor: Colors.white,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(
top: Radius.circular(20),
),
),
builder: (ctx) => SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
_buildHandle(),
const SizedBox(height: 16),
const Align(
alignment: Alignment.centerLeft,
child: Text(
'Product photo',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.w800,
color: _heading,
),
),
),
const SizedBox(height: 10),
ListTile(
contentPadding: const EdgeInsets.symmetric(
horizontal: 4,
),
leading: _iconTile(
Icons.camera_alt_outlined,
const Color(0xFFEFF6FF),
const Color(0xFF2563EB),
),
title: const Text(
'Take a photo',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w700,
),
),
subtitle: const Text(
'Use your device camera',
style: TextStyle(fontSize: 11),
),
onTap: () {
Navigator.pop(ctx);
_pickImage(ImageSource.camera);
},
),
ListTile(
contentPadding: const EdgeInsets.symmetric(
horizontal: 4,
),
leading: _iconTile(
Icons.photo_library_outlined,
const Color(0xFFF0FDF4),
const Color(0xFF16A34A),
),
title: const Text(
'Choose from gallery',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w700,
),
),
subtitle: const Text(
'Select an existing image',
style: TextStyle(fontSize: 11),
),
onTap: () {
Navigator.pop(ctx);
_pickImage(ImageSource.gallery);
},
),
],
),
),
),
);
}

Widget _buildHandle() {
return Container(
width: 34,
height: 4,
decoration: BoxDecoration(
color: const Color(0xFFD1D5DB),
borderRadius: BorderRadius.circular(99),
),
);
}

Widget _iconTile(
IconData icon,
Color background,
Color foreground,
) {
return Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: background,
borderRadius: BorderRadius.circular(11),
),
child: Icon(icon, color: foreground, size: 19),
);
}

void _showAddCategoryDialog() {
final catController = TextEditingController();

showDialog(
context: context,
builder: (ctx) => AlertDialog(
backgroundColor: Colors.white,
surfaceTintColor: Colors.transparent,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
title: const Text(
'New category',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w800,
color: _heading,
),
),
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Create a category for your inventory.',
style: TextStyle(
fontSize: 12,
color: _muted,
),
),
const SizedBox(height: 14),
TextField(
controller: catController,
autofocus: true,
textCapitalization: TextCapitalization.words,
style: const TextStyle(fontSize: 13),
decoration: _inputDecoration(
label: 'Category name',
hint: 'e.g. School Shoes',
icon: Icons.category_outlined,
),
),
],
),
actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx),
child: const Text(
'Cancel',
style: TextStyle(
fontSize: 12,
color: _muted,
),
),
),
FilledButton(
style: orangeButton().copyWith(
padding: const WidgetStatePropertyAll(
EdgeInsets.symmetric(horizontal: 16, vertical: 11),
),
shape: WidgetStatePropertyAll(
RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10),
),
),
),
onPressed: () {
final val = catController.text.trim();

if (val.isNotEmpty) {
final existing = availableCategories.firstWhere(
(item) => item.toLowerCase() == val.toLowerCase(),
orElse: () => '',
);

if (existing.isEmpty) {
setState(() {
availableCategories.add(val);
category = val;
});

widget.onAddCategory?.call(val);
} else {
setState(() {
category = existing;
});
}
}

Navigator.pop(ctx);
catController.dispose();
},
child: const Text(
'Add category',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
),
],
),
).then((_) {
catController.dispose();
});
}

void _showManageCategoriesDialog() {
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: Color(0xFF1E3A8A), size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Manage Categories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _heading),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Remove unwanted categories from the database. Tap the trash icon to delete.',
                style: TextStyle(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableCategories.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = availableCategories[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      leading: const Icon(Icons.category_outlined, size: 18, color: Color(0xFF1E3A8A)),
                      title: Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        tooltip: 'Remove $item',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: const Text('Remove Category?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              content: Text('Are you sure you want to delete "$item" from the database?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            widget.onRemoveCategory?.call(item);
                            setState(() {
                              availableCategories.remove(item);
                              if (category == item) {
                                category = availableCategories.isNotEmpty ? availableCategories.first : 'General';
                              }
                            });
                            setDialogState(() {});
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Category "$item" removed from database.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

void _openCameraScanner() {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => QrScannerView(
products: widget.products,
onProductScanned: (prod) {
setState(() {
nameController.text = prod.name;
priceController.text = prod.price.toString();
stockController.text = prod.stock.toString();

if (availableCategories.contains(prod.category)) {
category = prod.category;
} else {
availableCategories.add(prod.category);
category = prod.category;
widget.onAddCategory?.call(prod.category);
}

if (prod.imagePath.isNotEmpty) {
pickedImagePath = prod.imagePath;
}

if (prod.sizes.isNotEmpty) {
selectedSizes
..clear()
..addAll(prod.sizes);
}

if (prod.colors.isNotEmpty) {
selectedColors
..clear()
..addAll(prod.colors);
}
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Auto-filled "${prod.name}" from barcode.',
),
behavior: SnackBarBehavior.floating,
),
);
},
onRawCodeScanned: (rawCode) {
setState(() {
if (nameController.text.isEmpty) {
nameController.text = 'Product ($rawCode)';
}
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Scanned code "$rawCode" saved.'),
behavior: SnackBarBehavior.floating,
),
);
},
),
),
);
}

void _toggleSize(String size) {
setState(() {
if (selectedSizes.contains(size)) {
if (selectedSizes.length > 1) {
selectedSizes.remove(size);
}
} else {
selectedSizes.add(size);
}
});
}

void _toggleColor(String color) {
setState(() {
if (selectedColors.contains(color)) {
if (selectedColors.length > 1) {
selectedColors.remove(color);
}
} else {
selectedColors.add(color);
}
});
}

void _addCustomSize() {
final value = customSizeController.text.trim();

if (value.isNotEmpty) {
setState(() {
selectedSizes.add(value);
customSizeController.clear();
});
}
}

void _addCustomColor() {
final value = customColorController.text.trim();

if (value.isNotEmpty) {
setState(() {
selectedColors.add(value);
customColorController.clear();
});
}
}

void save() {
if (!formKey.currentState!.validate()) return;

final parsedPrice = double.tryParse(priceController.text.trim());
final priceVal = parsedPrice != null ? parsedPrice.round() : 0;
final parsedStock = int.tryParse(stockController.text.trim()) ?? 0;

widget.onSave(
ProductDraft(
name: nameController.text.trim(),
category: category,
stock: parsedStock,
price: priceVal,
sizes: selectedSizes.isEmpty
? ['6', '7', '8', '9']
    : selectedSizes.toList(),
colors: selectedColors.isEmpty
? ['Black', 'Tan']
    : selectedColors.toList(),
imagePath: pickedImagePath ?? '',
),
);

Navigator.pop(context);
}

@override
Widget build(BuildContext context) {
final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

return DraggableScrollableSheet(
initialChildSize: 0.92,
minChildSize: 0.55,
maxChildSize: 0.96,
expand: false,
builder: (_, scrollController) {
return Container(
decoration: const BoxDecoration(
color: _background,
borderRadius: BorderRadius.vertical(
top: Radius.circular(22),
),
),
child: Column(
children: [
_buildHeader(),
Expanded(
child: Form(
key: formKey,
child: ListView(
controller: scrollController,
keyboardDismissBehavior:
ScrollViewKeyboardDismissBehavior.onDrag,
padding: EdgeInsets.fromLTRB(
16,
2,
16,
keyboardSpace + 20,
),
children: [
_buildPhotoCard(),
const SizedBox(height: 10),
_buildScannerAction(),
const SizedBox(height: 12),

_buildCleanCard(
title: 'Product details',
icon: Icons.inventory_2_outlined,
child: Column(
children: [
TextFormField(
controller: nameController,
style: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.w500,
),
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'Product name is required';
}
return null;
},
decoration: _inputDecoration(
label: 'Product name',
hint: 'e.g. Leather Oxford Shoes',
icon: Icons.shopping_bag_outlined,
),
),
const SizedBox(height: 12),
Row(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
Expanded(
child: DropdownButtonFormField<String>(
value: availableCategories.contains(category)
? category
    : null,
isExpanded: true,
icon: const Icon(
Icons.keyboard_arrow_down_rounded,
size: 20,
color: _muted,
),
dropdownColor: Colors.white,
borderRadius: BorderRadius.circular(12),
menuMaxHeight: 320,
style: const TextStyle(
fontSize: 12,
color: _heading,
fontWeight: FontWeight.w500,
),
items: availableCategories.map((item) {
return DropdownMenuItem<String>(
value: item,
child: Text(
item,
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
);
}).toList(),
onChanged: (value) {
if (value != null) {
setState(() => category = value);
}
},
decoration: _inputDecoration(
label: 'Category',
icon: Icons.category_outlined,
),
),
),
const SizedBox(width: 8),
Material(
color: Colors.white,
borderRadius: BorderRadius.circular(10),
child: InkWell(
onTap: _showAddCategoryDialog,
borderRadius: BorderRadius.circular(10),
child: Container(
height: 46,
padding: const EdgeInsets.symmetric(
horizontal: 10,
),
decoration: BoxDecoration(
border: Border.all(
color: _border,
),
borderRadius:
BorderRadius.circular(10),
),
child: const Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.add,
size: 17,
color: AppColors.deepNavy,
),
SizedBox(width: 3),
Text(
'Add',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
color: AppColors.deepNavy,
),
),
],
),
),
),
),
const SizedBox(width: 6),
Material(
color: Colors.white,
borderRadius: BorderRadius.circular(10),
child: InkWell(
onTap: _showManageCategoriesDialog,
borderRadius: BorderRadius.circular(10),
child: Container(
height: 46,
padding: const EdgeInsets.symmetric(
horizontal: 10,
),
decoration: BoxDecoration(
border: Border.all(
color: Colors.red.shade200,
),
borderRadius:
BorderRadius.circular(10),
),
child: const Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.delete_outline,
size: 17,
color: Colors.red,
),
SizedBox(width: 3),
Text(
'Remove',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
color: Colors.red,
),
),
],
),
),
),
),
],
),
],
),
),
const SizedBox(height: 12),

_buildCleanCard(
title: 'Pricing & stock',
icon: Icons.payments_outlined,
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: TextFormField(
controller: priceController,
style: const TextStyle(fontSize: 13),
keyboardType:
const TextInputType.numberWithOptions(
decimal: true,
),
inputFormatters: [
NoLeadingDotNumberFormatter(
allowDecimals: true,
),
],
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'Required';
}
if (double.tryParse(value.trim()) == null) {
return 'Enter a valid price';
}
return null;
},
decoration: _inputDecoration(
label: 'Price (₹)',
hint: 'e.g. 999',
icon: Icons.currency_rupee,
),
),
),
const SizedBox(width: 10),
Expanded(
child: TextFormField(
controller: stockController,
style: const TextStyle(fontSize: 13),
keyboardType: TextInputType.number,
inputFormatters: [
NoLeadingDotNumberFormatter(
allowDecimals: false,
),
],
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'Required';
}
if (int.tryParse(value.trim()) == null) {
return 'Whole number required';
}
return null;
},
decoration: _inputDecoration(
label: 'Stock (pairs)',
hint: 'e.g. 15',
icon: Icons.inventory_2_outlined,
),
),
),
],
),
),
const SizedBox(height: 12),

_buildCleanCard(
title: 'Sizes & colors',
icon: Icons.tune_rounded,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_buildFieldLabel(
'Available sizes',
'${selectedSizes.length} selected',
),
const SizedBox(height: 8),
Wrap(
spacing: 6,
runSpacing: 6,
children: [
...popularSizes.map((size) {
return _buildSelectionChip(
label: size,
selected: selectedSizes.contains(size),
onSelected: () => _toggleSize(size),
);
}),
...selectedSizes
    .where(
(size) =>
!popularSizes.contains(size),
)
    .map(
(size) => _buildCustomChip(
label: size,
onDeleted: () {
if (selectedSizes.length > 1) {
setState(() {
selectedSizes.remove(size);
});
}
},
),
),
],
),
const SizedBox(height: 10),
_buildCustomEntry(
controller: customSizeController,
hint: 'Custom size',
onAdd: _addCustomSize,
),
const Padding(
padding: EdgeInsets.symmetric(vertical: 14),
child: Divider(
height: 1,
color: _border,
),
),
_buildFieldLabel(
'Available colors',
'${selectedColors.length} selected',
),
const SizedBox(height: 8),
Wrap(
spacing: 6,
runSpacing: 6,
children: [
...popularColors.map((color) {
return _buildSelectionChip(
label: color,
selected: selectedColors.contains(color),
onSelected: () => _toggleColor(color),
);
}),
...selectedColors
    .where(
(color) =>
!popularColors.contains(color),
)
    .map(
(color) => _buildCustomChip(
label: color,
onDeleted: () {
if (selectedColors.length > 1) {
setState(() {
selectedColors.remove(color);
});
}
},
),
),
],
),
const SizedBox(height: 10),
_buildCustomEntry(
controller: customColorController,
hint: 'Custom color',
onAdd: _addCustomColor,
),
],
),
),
const SizedBox(height: 16),

SizedBox(
height: 48,
child: FilledButton.icon(
onPressed: save,
style: orangeButton().copyWith(
shape: WidgetStatePropertyAll(
RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
icon: const Icon(
Icons.check_circle_outline,
size: 19,
),
label: const Text(
'Save product',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w800,
),
),
),
),
const SizedBox(height: 8),
],
),
),
),
],
),
);
},
);
}

Widget _buildHeader() {
return Padding(
padding: const EdgeInsets.fromLTRB(16, 9, 12, 12),
child: Column(
children: [
_buildHandle(),
const SizedBox(height: 13),
Row(
children: [
Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: AppColors.deepNavy,
borderRadius: BorderRadius.circular(11),
),
child: const Icon(
Icons.add_shopping_cart_outlined,
color: AppColors.accent,
size: 19,
),
),
const SizedBox(width: 11),
const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Add product',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w800,
color: _heading,
letterSpacing: -0.3,
),
),
SizedBox(height: 2),
Text(
'Add an item to your inventory',
style: TextStyle(
fontSize: 11,
color: _muted,
),
),
],
),
),
IconButton(
onPressed: () => Navigator.pop(context),
style: IconButton.styleFrom(
backgroundColor: Colors.white,
foregroundColor: _muted,
side: const BorderSide(color: _border),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10),
),
minimumSize: const Size(36, 36),
maximumSize: const Size(36, 36),
padding: EdgeInsets.zero,
),
icon: const Icon(Icons.close, size: 18),
),
],
),
],
),
);
}

Widget _buildScannerAction() {
return Material(
color: Colors.white,
borderRadius: BorderRadius.circular(12),
child: InkWell(
onTap: _openCameraScanner,
borderRadius: BorderRadius.circular(12),
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 11,
),
decoration: BoxDecoration(
border: Border.all(color: _border),
borderRadius: BorderRadius.circular(12),
),
child: const Row(
children: [
Icon(
Icons.qr_code_scanner_rounded,
color: AppColors.deepNavy,
size: 20,
),
SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Scan barcode / QR',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
color: _heading,
),
),
SizedBox(height: 2),
Text(
'Auto-fill existing product details',
style: TextStyle(
fontSize: 10,
color: _muted,
),
),
],
),
),
Icon(
Icons.chevron_right_rounded,
size: 20,
color: _muted,
),
],
),
),
),
);
}

Widget _buildPhotoCard() {
final hasImage = pickedImagePath != null &&
File(pickedImagePath!).existsSync();

return _buildCleanCard(
title: 'Product photo',
icon: Icons.photo_camera_outlined,
child: hasImage
? Row(
children: [
ClipRRect(
borderRadius: BorderRadius.circular(10),
child: Image.file(
File(pickedImagePath!),
width: 76,
height: 76,
fit: BoxFit.cover,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Photo attached',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
color: _heading,
),
),
const SizedBox(height: 3),
const Text(
'Product image is ready.',
style: TextStyle(
fontSize: 10,
color: _muted,
),
),
const SizedBox(height: 8),
Wrap(
spacing: 8,
children: [
_smallAction(
label: 'Change',
icon: Icons.edit_outlined,
onTap: _showImageSourceDialog,
),
_smallAction(
label: 'Remove',
icon: Icons.delete_outline,
color: AppColors.error,
onTap: () {
setState(() => pickedImagePath = null);
},
),
],
),
],
),
),
],
)
    : InkWell(
onTap: _showImageSourceDialog,
borderRadius: BorderRadius.circular(10),
child: Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(vertical: 15),
decoration: BoxDecoration(
color: _fieldBackground,
border: Border.all(
color: _border,
style: BorderStyle.solid,
),
borderRadius: BorderRadius.circular(10),
),
child: const Column(
children: [
Icon(
Icons.add_photo_alternate_outlined,
size: 27,
color: AppColors.deepNavy,
),
SizedBox(height: 6),
Text(
'Add product image',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
color: _heading,
),
),
SizedBox(height: 3),
Text(
'Camera or gallery',
style: TextStyle(
fontSize: 10,
color: _muted,
),
),
],
),
),
),
);
}

Widget _smallAction({
required String label,
required IconData icon,
required VoidCallback onTap,
Color color = _heading,
}) {
return InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(7),
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 2,
vertical: 3,
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, size: 13, color: color),
const SizedBox(width: 4),
Text(
label,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w600,
color: color,
),
),
],
),
),
);
}

Widget _buildCleanCard({
required String title,
required IconData icon,
required Widget child,
}) {
return Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(14),
border: Border.all(color: _border),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(icon, size: 17, color: AppColors.deepNavy),
const SizedBox(width: 8),
Text(
title,
style: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.w800,
color: _heading,
letterSpacing: -0.1,
),
),
],
),
const SizedBox(height: 13),
child,
],
),
);
}

Widget _buildFieldLabel(String title, String trailing) {
return Row(
children: [
Text(
title,
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.w700,
color: _heading,
),
),
const Spacer(),
Text(
trailing,
style: const TextStyle(
fontSize: 10,
color: _muted,
),
),
],
);
}

Widget _buildSelectionChip({
required String label,
required bool selected,
required VoidCallback onSelected,
}) {
return Material(
color: selected ? AppColors.deepNavy : Colors.white,
borderRadius: BorderRadius.circular(8),
child: InkWell(
onTap: onSelected,
borderRadius: BorderRadius.circular(8),
child: Container(
constraints: const BoxConstraints(minWidth: 36),
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 7,
),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(8),
border: Border.all(
color: selected ? AppColors.deepNavy : _border,
),
),
child: Text(
label,
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 11,
fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
color: selected ? Colors.white : _heading,
),
),
),
),
);
}

Widget _buildCustomChip({
required String label,
required VoidCallback onDeleted,
}) {
return Container(
padding: const EdgeInsets.only(left: 10, right: 4),
decoration: BoxDecoration(
color: const Color(0xFFEFF6FF),
borderRadius: BorderRadius.circular(8),
border: Border.all(color: const Color(0xFFDBEAFE)),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Text(
label,
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.w600,
color: AppColors.deepNavy,
),
),
const SizedBox(width: 3),
InkWell(
onTap: onDeleted,
borderRadius: BorderRadius.circular(20),
child: const Padding(
padding: EdgeInsets.all(4),
child: Icon(
Icons.close,
size: 13,
color: AppColors.deepNavy,
),
),
),
],
),
);
}

Widget _buildCustomEntry({
required TextEditingController controller,
required String hint,
required VoidCallback onAdd,
}) {
return Row(
children: [
Expanded(
child: TextField(
controller: controller,
style: const TextStyle(
fontSize: 12,
color: _heading,
),
decoration: _inputDecoration(
label: hint,
hint: 'Enter value',
),
onSubmitted: (_) => onAdd(),
),
),
const SizedBox(width: 8),
SizedBox(
height: 42,
child: OutlinedButton(
onPressed: onAdd,
style: OutlinedButton.styleFrom(
foregroundColor: AppColors.deepNavy,
padding: const EdgeInsets.symmetric(horizontal: 12),
side: const BorderSide(color: _border),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10),
),
),
child: const Text(
'Add',
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.w700,
),
),
),
),
],
);
}
}

