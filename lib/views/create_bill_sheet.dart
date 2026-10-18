import 'dart:io';

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/bill_draft.dart';
import '../models/bill_item.dart';
import '../models/product.dart';
import '../widgets/shop_widgets.dart';
import 'qr_scanner_view.dart';

class CreateBillSheet extends StatefulWidget {
  const CreateBillSheet({
    super.key,
    required this.products,
    required this.onSave,
    this.preselectedProduct,
    this.categories = const [],
  });

  final List<Product> products;
  final ValueChanged<BillDraft> onSave;
  final Product? preselectedProduct;
  final List<String> categories;

  @override
  State<CreateBillSheet> createState() => _CreateBillSheetState();
}

class _CreateBillSheetState extends State<CreateBillSheet> {
  // Retain customer details when the sheet is closed and reopened.
  // Clear them after successfully invoking the save callback.
  static String _savedCustomerName = '';
  static String _savedCustomerMobile = '';

  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController mobileController;

  final discountController = TextEditingController(text: '0');
  final noteController = TextEditingController();
  final itemSizeController = TextEditingController();
  final itemColorController = TextEditingController();
  final itemPriceController = TextEditingController();

  String payMode = 'UPI';
  String stockSearchQuery = '';
  String selectedCategoryFilter = 'All';

  final List<BillItem> billItems = [];

  Product? selectedProduct;
  int itemQty = 1;

  static const Color _background = Color(0xFFF6F8FB);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _muted = Color(0xFF64748B);
  static const Color _heading = Color(0xFF172B4D);
  static const Color _fieldBackground = Color(0xFFFBFCFE);
  static const Color _green = Color(0xFF16845B);
  static const Color _softBlue = Color(0xFFEFF6FF);

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: _savedCustomerName);
    mobileController = TextEditingController(text: _savedCustomerMobile);

    nameController.addListener(_rememberCustomerDetails);
    mobileController.addListener(_rememberCustomerDetails);

    if (widget.products.isNotEmpty) {
      Product? initial;

      if (widget.preselectedProduct != null) {
        for (final product in widget.products) {
          if (product.id == widget.preselectedProduct!.id) {
            initial = product;
            break;
          }
        }
      }

      initial ??= widget.products.first;
      _selectProduct(initial);

      if (widget.preselectedProduct != null && initial.stock > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _addItemToBill();
        });
      }
    }
  }

  void _rememberCustomerDetails() {
    _savedCustomerName = nameController.text;
    _savedCustomerMobile = mobileController.text;
  }

  @override
  void dispose() {
    nameController.removeListener(_rememberCustomerDetails);
    mobileController.removeListener(_rememberCustomerDetails);

    nameController.dispose();
    mobileController.dispose();
    discountController.dispose();
    noteController.dispose();
    itemSizeController.dispose();
    itemColorController.dispose();
    itemPriceController.dispose();

    super.dispose();
  }

  List<String> get availableCategories {
    final result = <String>{'All'};

    result.addAll(
      widget.categories.where((category) => category.trim().isNotEmpty),
    );

    for (final product in widget.products) {
      if (product.category.trim().isNotEmpty) {
        result.add(product.category);
      }
    }

    return result.toList();
  }

  void _selectProduct(Product product) {
    setState(() {
      selectedProduct = product;
      itemPriceController.text = product.price.toString();
      itemSizeController.text =
      product.sizes.isNotEmpty ? product.sizes.first : '7';
      itemColorController.text =
      product.colors.isNotEmpty ? product.colors.first : 'Black';
      itemQty = 1;
    });
  }

  int _getInCartQtyForProduct(String productId) {
    return billItems
        .where((item) => item.productId == productId)
        .fold(0, (sum, item) => sum + item.qty);
  }

  int get availableStockForSelected {
    final product = selectedProduct;
    if (product == null) return 0;

    final remaining =
        product.stock - _getInCartQtyForProduct(product.id);

    return remaining > 0 ? remaining : 0;
  }

  int _getProductStock(String productId) {
    for (final product in widget.products) {
      if (product.id == productId) return product.stock;
    }

    return 0;
  }

  int get subtotal {
    return billItems.fold(0, (sum, item) => sum + item.total);
  }

  int get discountAmount {
    final value = double.tryParse(discountController.text.trim());

    if (value == null || value <= 0) return 0;

    return value.round();
  }

  int get total {
    final value = subtotal - discountAmount;
    return value > 0 ? value : 0;
  }

  int get totalQty {
    return billItems.fold(0, (sum, item) => sum + item.qty);
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : _heading,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
        ),
      );
  }

  void _addItemToBill() {
    final product = selectedProduct;

    if (product == null) {
      _showMessage('Select a product first.', error: true);
      return;
    }

    if (availableStockForSelected <= 0) {
      _showMessage(
        'No stock available for "${product.name}".',
        error: true,
      );
      return;
    }

    final parsedPrice = double.tryParse(itemPriceController.text.trim());
    final size = itemSizeController.text.trim();
    final color = itemColorController.text.trim();

    if (parsedPrice == null ||
        !parsedPrice.isFinite ||
        parsedPrice <= 0 ||
        size.isEmpty ||
        color.isEmpty ||
        itemQty <= 0) {
      _showMessage(
        'Enter a valid size, color, price and quantity.',
        error: true,
      );
      return;
    }

    final unitPrice = parsedPrice.round();

    if (unitPrice <= 0) {
      _showMessage('Price must be at least ₹1.', error: true);
      return;
    }

    if (itemQty > availableStockForSelected) {
      _showMessage(
        'Only $availableStockForSelected pairs are available.',
        error: true,
      );
      return;
    }

    final index = billItems.indexWhere(
          (item) =>
      item.productId == product.id &&
          item.size == size &&
          item.color == color,
    );

    setState(() {
      if (index >= 0) {
        final existing = billItems[index];

        billItems[index] = existing.copyWith(
          qty: existing.qty + itemQty,
          price: unitPrice,
        );
      } else {
        billItems.add(
          BillItem(
            productId: product.id,
            productName: product.name,
            size: size,
            color: color,
            qty: itemQty,
            price: unitPrice,
          ),
        );
      }

      itemQty = 1;
    });

    _showMessage('${product.name} added to bill.');
  }

  void _removeItemFromBill(int index) {
    setState(() {
      billItems.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, int delta) {
    final item = billItems[index];
    final stock = _getProductStock(item.productId);
    final totalInCart = _getInCartQtyForProduct(item.productId);

    if (delta > 0 && totalInCart >= stock) {
      _showMessage(
        'Maximum stock limit reached ($stock pairs).',
        error: true,
      );
      return;
    }

    setState(() {
      final nextQty = item.qty + delta;

      if (nextQty <= 0) {
        billItems.removeAt(index);
      } else {
        billItems[index] = item.copyWith(qty: nextQty);
      }
    });
  }

  void _openCameraScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerView(
          products: widget.products,
          onProductScanned: (product) {
            if (!mounted) return;

            _selectProduct(product);

            if (product.stock > 0) {
              _addItemToBill();
            } else {
              _showMessage(
                '"${product.name}" is out of stock.',
                error: true,
              );
            }
          },
          onRawCodeScanned: (code) {
            if (!mounted) return;
            setState(() => stockSearchQuery = code);
          },
        ),
      ),
    );
  }

  void _saveBill() {
    FocusScope.of(context).unfocus();

    if (!(formKey.currentState?.validate() ?? false)) return;

    if (billItems.isEmpty) {
      _showMessage(
        'Add at least one product before generating the bill.',
        error: true,
      );
      return;
    }

    if (discountAmount > subtotal) {
      _showMessage(
        'Discount cannot exceed the subtotal.',
        error: true,
      );
      return;
    }

    final draft = BillDraft(
      customer: nameController.text.trim(),
      mobile: mobileController.text.trim(),
      items: List<BillItem>.from(billItems),
      discount: discountAmount,
      payMode: payMode,
      note: noteController.text.trim(),
    );

    widget.onSave(draft);

    _savedCustomerName = '';
    _savedCustomerMobile = '';

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardSpace),
      child: DraggableScrollableSheet(
        initialChildSize: 0.94,
        minChildSize: 0.55,
        maxChildSize: 0.98,
        expand: false,
        builder: (context, scrollController) {
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
                        keyboardSpace > 0 ? 16 : 20,
                      ),
                      children: [
                        _buildCustomerSection(),
                        const SizedBox(height: 10),
                        _buildSection(
                          title: 'Select footwear',
                          subtitle: 'Choose products from your inventory',
                          icon: Icons.inventory_2_outlined,
                          trailing: _scannerButton(),
                          child: _buildStockSelectorContent(),
                        ),
                        const SizedBox(height: 10),
                        _buildSection(
                          title: 'Bill items',
                          subtitle: billItems.isEmpty
                              ? 'Your selected items appear here'
                              : '$totalQty pairs in your bill',
                          icon: Icons.shopping_bag_outlined,
                          trailing: _countBadge(billItems.length),
                          child: _buildCartItemsContent(),
                        ),
                        const SizedBox(height: 10),
                        _buildSection(
                          title: 'Payment & summary',
                          subtitle: 'Choose payment and review the total',
                          icon: Icons.receipt_long_outlined,
                          child: _buildPaymentAndSummaryContent(),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _saveBill,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.deepNavy,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 19,
                            ),
                            label: Flexible(
                              child: Text(
                                billItems.isEmpty
                                    ? 'ADD ITEMS TO GENERATE BILL'
                                    : 'SAVE BILL  ·  ${money(total)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 9, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      child: Column(
        children: [
          _buildHandle(),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.deepNavy,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create bill',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _heading,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Customer · Items · Payment',
                      style: TextStyle(
                        fontSize: 11,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: _fieldBackground,
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

  Widget _buildCustomerSection() {
    return _buildSection(
      title: 'Customer details',
      subtitle: 'Required for billing and WhatsApp offers',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              fontSize: 13,
              color: _heading,
              fontWeight: FontWeight.w500,
            ),
            scrollPadding: const EdgeInsets.only(bottom: 220),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Customer name is required';
              }
              return null;
            },
            decoration: _inputDecoration(
              label: 'Customer name',
              hint: 'e.g. Imran Khan',
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 11),
          TextFormField(
            controller: mobileController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            maxLength: 15,
            style: const TextStyle(
              fontSize: 13,
              color: _heading,
              fontWeight: FontWeight.w500,
            ),
            scrollPadding: const EdgeInsets.only(bottom: 220),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Mobile number is required';
              }

              final digits = value.replaceAll(RegExp(r'\D'), '');

              if (digits.length < 10 || digits.length > 15) {
                return 'Enter a valid mobile number';
              }

              return null;
            },
            decoration: _inputDecoration(
              label: 'WhatsApp mobile number',
              hint: '10-digit mobile number',
              icon: Icons.phone_outlined,
            ).copyWith(counterText: ''),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
    Widget? trailing,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _heading,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _scannerButton() {
    return InkWell(
      onTap: _openCameraScanner,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: _fieldBackground,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 16,
              color: AppColors.deepNavy,
            ),
            SizedBox(width: 5),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _heading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _softBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.deepNavy,
        ),
      ),
    );
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

  Widget _buildStockSelectorContent() {
    final query = stockSearchQuery.trim().toLowerCase();

    final filtered = widget.products.where((product) {
      if (selectedCategoryFilter != 'All' &&
          product.category != selectedCategoryFilter) {
        return false;
      }

      if (query.isEmpty) return true;

      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.id.toLowerCase().contains(query);
    }).toList();

    final categories = availableCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = selectedCategoryFilter == category;

              return ChoiceChip(
                label: Text(category),
                selected: selected,
                onSelected: (_) {
                  setState(() => selectedCategoryFilter = category);
                },
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _muted,
                ),
                backgroundColor: _fieldBackground,
                selectedColor: AppColors.deepNavy,
                side: BorderSide(
                  color: selected ? AppColors.deepNavy : _border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 11),
        TextField(
          onChanged: (value) {
            setState(() => stockSearchQuery = value);
          },
          style: const TextStyle(
            fontSize: 12,
            color: _heading,
          ),
          decoration: _inputDecoration(
            label: 'Search products',
            hint: 'Product name, category or ID',
            icon: Icons.search_rounded,
            suffixIcon: stockSearchQuery.isNotEmpty
                ? IconButton(
              tooltip: 'Clear search',
              onPressed: () {
                setState(() => stockSearchQuery = '');
              },
              icon: const Icon(Icons.close, size: 17),
            )
                : null,
          ),
        ),
        const SizedBox(height: 11),
        if (filtered.isEmpty)
          _buildEmptyProducts()
        else
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final product = filtered[index];
                final selected = selectedProduct?.id == product.id;
                final remaining =
                    product.stock - _getInCartQtyForProduct(product.id);

                final hasImage = product.imagePath.isNotEmpty &&
                    File(product.imagePath).existsSync();

                final screenWidth = MediaQuery.sizeOf(context).width;
                final cardWidth =
                (screenWidth - 64).clamp(155.0, 220.0).toDouble();

                return InkWell(
                  onTap: () => _selectProduct(product),
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected ? _softBlue : Colors.white,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: selected
                            ? AppColors.deepNavy
                            : _border,
                        width: selected ? 1.3 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 47,
                            height: 56,
                            child: hasImage
                                ? Image.file(
                              File(product.imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _productPlaceholder(),
                            )
                                : _productPlaceholder(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: _heading,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                money(product.price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                remaining <= 0
                                    ? 'Out of stock'
                                    : '$remaining pairs left',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: remaining <= 0
                                      ? Colors.red.shade700
                                      : _green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (selectedProduct != null) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: _border),
          ),
          _buildSelectedProductDetails(),
        ],
      ],
    );
  }

  Widget _buildEmptyProducts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: _fieldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 26,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 7),
          Text(
            'No matching products found',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _heading,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Try another name or category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedProductDetails() {
    final product = selectedProduct!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _heading,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _stockBadge(availableStockForSelected),
          ],
        ),
        const SizedBox(height: 13),
        _buildOptionSelector(
          label: 'Size',
          values: product.sizes,
          controller: itemSizeController,
        ),
        const SizedBox(height: 11),
        _buildOptionSelector(
          label: 'Color',
          values: product.colors,
          controller: itemColorController,
        ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 340;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: itemPriceController,
                    keyboardType:
                    const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [
                      NoLeadingDotNumberFormatter(
                        allowDecimals: true,
                      ),
                    ],
                    scrollPadding: const EdgeInsets.only(bottom: 220),
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration(
                      label: 'Price (₹)',
                      icon: Icons.currency_rupee,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 7 : 10),
                Expanded(
                  child: _buildQuantitySelector(),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 43,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
            availableStockForSelected > 0 ? _addItemToBill : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deepNavy,
              disabledForegroundColor: _muted,
              side: const BorderSide(color: _border),
              backgroundColor: _fieldBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.add_shopping_cart_rounded,
              size: 17,
            ),
            label: Text(
              availableStockForSelected <= 0
                  ? 'Out of stock'
                  : 'Add item to bill',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _fieldBackground,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _smallIconButton(
            icon: Icons.remove,
            onTap: itemQty > 1 ? () => setState(() => itemQty--) : null,
          ),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$itemQty',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _heading,
                  ),
                ),
                const Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 9,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          _smallIconButton(
            icon: Icons.add,
            onTap: itemQty < availableStockForSelected
                ? () => setState(() => itemQty++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      color: _softBlue,
      alignment: Alignment.center,
      child: const Icon(
        Icons.shopping_bag_outlined,
        size: 23,
        color: AppColors.deepNavy,
      ),
    );
  }

  Widget _stockBadge(int stock) {
    final available = stock > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: available
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        available ? '$stock available' : 'Out of stock',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: available ? _green : Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _buildOptionSelector({
    required String label,
    required List<String> values,
    required TextEditingController controller,
  }) {
    final isSize = label == 'Size';

    if (values.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 11,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              scrollPadding: const EdgeInsets.only(bottom: 220),
              style: const TextStyle(fontSize: 12, color: _heading),
              decoration: _inputDecoration(
                label: label,
                icon: isSize
                    ? Icons.straighten_rounded
                    : Icons.palette_outlined,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 11,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values.map((value) {
              final selected = controller.text == value;

              return InkWell(
                onTap: () {
                  setState(() => controller.text = value);
                },
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.deepNavy : _fieldBackground,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: selected ? AppColors.deepNavy : _border,
                    ),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _heading,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _smallIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(
        minWidth: 30,
        minHeight: 34,
      ),
      padding: EdgeInsets.zero,
      iconSize: 18,
      color: AppColors.deepNavy,
      disabledColor: const Color(0xFFCBD5E1),
      icon: Icon(icon),
    );
  }

  Widget _buildCartItemsContent() {
    if (billItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: _fieldBackground,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 28,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 7),
            Text(
              'Your bill is empty',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _heading,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Select a product and tap Add item to bill.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: _muted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: billItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        final stock = _getProductStock(item.productId);
        final inCart = _getInCartQtyForProduct(item.productId);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _fieldBackground,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(11),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 350;

              final number = Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepNavy,
                  ),
                ),
              );

              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: _heading,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Size ${item.size} · ${item.color}',
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${money(item.price)} × ${item.qty}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: _muted,
                    ),
                  ),
                ],
              );

              final quantityControl = Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _cartQtyButton(
                      icon: Icons.remove,
                      onTap: () => _updateItemQuantity(index, -1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        '${item.qty}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _heading,
                        ),
                      ),
                    ),
                    _cartQtyButton(
                      icon: Icons.add,
                      onTap: inCart < stock
                          ? () => _updateItemQuantity(index, 1)
                          : null,
                    ),
                  ],
                ),
              );

              final priceAndRemove = Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    money(item.total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: () => _removeItemFromBill(index),
                    borderRadius: BorderRadius.circular(5),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 13,
                            color: Colors.red,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        number,
                        const SizedBox(width: 8),
                        Expanded(child: details),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        quantityControl,
                        const Spacer(),
                        Flexible(child: priceAndRemove),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  number,
                  const SizedBox(width: 8),
                  Expanded(child: details),
                  const SizedBox(width: 7),
                  quantityControl,
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 72,
                    child: priceAndRemove,
                  ),
                ],
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _cartQtyButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 27,
      height: 29,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        iconSize: 15,
        color: AppColors.deepNavy,
        disabledColor: const Color(0xFFCBD5E1),
        icon: Icon(icon),
      ),
    );
  }

  Widget _buildPaymentAndSummaryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment method',
          style: TextStyle(
            fontSize: 11,
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: ['UPI', 'Cash', 'Card', 'Khata / Credit'].map((mode) {
            final selected = payMode == mode;

            return ChoiceChip(
              label: Text(mode),
              selected: selected,
              onSelected: (_) => setState(() => payMode = mode),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _heading,
              ),
              selectedColor: AppColors.deepNavy,
              backgroundColor: _fieldBackground,
              side: BorderSide(
                color: selected ? AppColors.deepNavy : _border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 340;

            final discountField = TextFormField(
              controller: discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [
                NoLeadingDotNumberFormatter(
                  allowDecimals: true,
                ),
              ],
              textInputAction: TextInputAction.next,
              scrollPadding: const EdgeInsets.only(bottom: 260),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final discount = double.tryParse(value?.trim() ?? '');

                if (discount == null || !discount.isFinite) {
                  return 'Enter a valid discount';
                }

                if (discount < 0) {
                  return 'Cannot be negative';
                }

                if (discount > subtotal) {
                  return 'Exceeds subtotal';
                }

                return null;
              },
              decoration: _inputDecoration(
                label: 'Discount (₹)',
                icon: Icons.local_offer_outlined,
              ),
            );

            final noteField = TextFormField(
              controller: noteController,
              textInputAction: TextInputAction.done,
              scrollPadding: const EdgeInsets.only(bottom: 260),
              style: const TextStyle(fontSize: 12, color: _heading),
              decoration: _inputDecoration(
                label: 'Note (optional)',
                icon: Icons.notes_outlined,
              ),
            );

            if (compact) {
              return Column(
                children: [
                  discountField,
                  const SizedBox(height: 10),
                  noteField,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: discountField,
                ),
                const SizedBox(width: 9),
                Expanded(
                  flex: 5,
                  child: noteField,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _fieldBackground,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _summaryRow(
                'Subtotal · $totalQty pairs',
                money(subtotal),
              ),
              if (discountAmount > 0) ...[
                const SizedBox(height: 10),
                _summaryRow(
                  'Discount',
                  '- ${money(discountAmount)}',
                  color: _green,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: _border),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grand total',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _heading,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Final payable amount',
                          style: TextStyle(
                            fontSize: 10,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        money(total),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: AppColors.deepNavy,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(
      String label,
      String value, {
        Color color = _heading,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}