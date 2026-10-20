import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/product.dart';
import '../widgets/product_image_widget.dart';
import '../widgets/shop_widgets.dart';

class ProductDetailsView extends StatelessWidget {
  const ProductDetailsView({
    super.key,
    required this.product,
    this.companyName,
    this.onCreateBillWithProduct,
    this.onDeleteProduct,
  });

  final Product product;
  final String? companyName;
  final ValueChanged<Product>? onCreateBillWithProduct;
  final Future<void> Function(Product product)? onDeleteProduct;

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
    final isOutOfStock = product.stock <= 0;
    final isLowStock = product.stock > 0 && product.stock <= 3;

    Color stockColor = const Color(0xFF16A34A); // Green
    Color stockBg = const Color(0xFFDCFCE7); // Light Green
    String stockStatusText = '${product.stock} In Stock';

    if (isOutOfStock) {
      stockColor = const Color(0xFFDC2626); // Red
      stockBg = const Color(0xFFFEE2E2); // Light Red
      stockStatusText = 'Out of Stock';
    } else if (isLowStock) {
      stockColor = const Color(0xFFD97706); // Amber
      stockBg = const Color(0xFFFEF3C7); // Light Amber
      stockStatusText = 'Low Stock (${product.stock})';
    }

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
          'Product Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        actions: [
          if (onDeleteProduct != null)
            IconButton(
              tooltip: 'Delete Product',
              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              onPressed: () => _confirmDelete(context),
            ),
          IconButton(
            tooltip: 'Share Product',
            icon: const Icon(Icons.share_outlined, color: Color(0xFF0F172A)),
            onPressed: () {
              final storeDisplay = companyName?.isNotEmpty == true ? companyName! : 'our store';
              final shareText = '''
👟 ${product.name}
💰 Price: ${money(product.price)}
📦 Stock: ${product.stock} pairs available
🏷 Category: ${product.category}
📏 Sizes: ${product.sizes.join(', ')}
🎨 Colors: ${product.colors.join(', ')}

Available at $storeDisplay!
''';
              Share.share(shareText);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14), // Reduced from 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. SINGLE MAIN CARD (Image + Details)
              // ==========================================
              Container(
                decoration: _cardDecoration(),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image (if available)
                    if (product.imagePath.isNotEmpty || product.imageBase64.isNotEmpty)
                      Container(
                        height: 200, // Kept as requested
                        width: double.infinity,
                        color: const Color(0xFFF8FAFC),
                        child: ProductImageWidget(
                          product: product,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                    // Product Details Section (Compact)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category & Stock Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  product.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: stockBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  stockStatusText,
                                  style: TextStyle(
                                    color: stockColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8), // Reduced from 12

                          // Product Name
                          Text(
                            product.name,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18, // Reduced from 20
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12), // Reduced from 16

                          // Price & Action Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                money(product.price),
                                style: const TextStyle(
                                  color: Color(0xFF1E3A8A), // Brand Blue
                                  fontSize: 22, // Reduced from 24
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8), // Reduced from 10
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.checkroom, color: Color(0xFF2563EB), size: 20), // Reduced from 24
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12), // Reduced from 16

              // ==========================================
              // 2. ATTRIBUTES CARD (Sizes & Colors)
              // ==========================================
              Container(
                padding: const EdgeInsets.all(14), // Reduced from 16
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sizes
                    Row(
                      children: [
                        const Icon(Icons.straighten, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Available Sizes (${product.sizes.length})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        const Spacer(),
                        Text(
                          '${product.sizes.length} options',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    product.sizes.isEmpty
                        ? const Text('Standard / Free Size', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
                        : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: product.sizes.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            'Size $s',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12), // Reduced from 16
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),

                    // Colors
                    Row(
                      children: [
                        const Icon(Icons.palette_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Available Colors (${product.colors.length})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        const Spacer(),
                        Text(
                          '${product.colors.length} options',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    product.colors.isEmpty
                        ? const Text('Standard Color', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
                        : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: product.colors.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _guessColor(c),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black12),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================
              // 3. QR & ARTICLE ID CARD
              // ==========================================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: QrImageView(
                        data: product.id,
                        version: QrVersions.auto,
                        size: 60.0, // Reduced from 70
                        gapless: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Barcode & Article ID',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            product.id,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15, // Reduced from 16
                              color: Color(0xFF1E3A8A),
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Scan with app camera during billing or inventory count.',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20), // Reduced from 24

              // ==========================================
              // 4. ACTION BUTTON
              // ==========================================
              if (onCreateBillWithProduct != null)
                SizedBox(
                  width: double.infinity,
                  height: 50, // Reduced from 52
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onCreateBillWithProduct!(product);
                    },
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text(
                      'CREATE BILL WITH THIS PRODUCT',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, letterSpacing: 0.3),
                    ),
                  ),
                ),
              if (onDeleteProduct != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                      backgroundColor: const Color(0xFFFEF2F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text(
                      'DELETE PRODUCT FROM CATALOG',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Product?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${product.name}"?',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This product will be permanently removed from your inventory, local database, and cloud sync across all connected devices.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await onDeleteProduct?.call(product);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Product "${product.name}" deleted from inventory and cloud.'),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade700,
              content: Text('Failed to delete product: $e'),
            ),
          );
        }
      }
    }
  }

  Color _guessColor(String colorName) {
    final lower = colorName.toLowerCase().trim();
    if (lower.contains('black')) return Colors.black;
    if (lower.contains('brown')) return const Color(0xFF5D4037);
    if (lower.contains('tan')) return const Color(0xFFD2B48C);
    if (lower.contains('white')) return Colors.white;
    if (lower.contains('red')) return Colors.red;
    if (lower.contains('blue')) return Colors.blue;
    if (lower.contains('green')) return Colors.green;
    if (lower.contains('grey') || lower.contains('gray')) return Colors.grey;
    if (lower.contains('navy')) return const Color(0xFF002E6E);
    if (lower.contains('pink')) return Colors.pink;
    if (lower.contains('yellow')) return Colors.yellow;
    if (lower.contains('gold')) return const Color(0xFFFFD700);
    return Colors.blueGrey;
  }
}