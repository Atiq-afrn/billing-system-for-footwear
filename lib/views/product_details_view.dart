import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_colors.dart';
import '../models/product.dart';
import '../widgets/shop_widgets.dart';

class ProductDetailsView extends StatelessWidget {
  const ProductDetailsView({
    super.key,
    required this.product,
    this.onCreateBillWithProduct,
  });

  final Product product;
  final ValueChanged<Product>? onCreateBillWithProduct;

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock <= 0;
    final isLowStock = product.stock > 0 && product.stock <= 3;

    Color stockColor = Colors.green.shade700;
    Color stockBg = Colors.green.shade50;
    String stockStatusText = '${product.stock} In Stock';

    if (isOutOfStock) {
      stockColor = Colors.red.shade700;
      stockBg = Colors.red.shade50;
      stockStatusText = 'Out of Stock (0)';
    } else if (isLowStock) {
      stockColor = Colors.orange.shade800;
      stockBg = Colors.orange.shade50;
      stockStatusText = 'Low Stock (${product.stock} left)';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.deepNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            color: AppColors.deepNavy,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Share Product',
            icon: const Icon(Icons.share_outlined, color: AppColors.deepNavy),
            onPressed: () {
              final shareText = '''
👟 ${product.name}
💰 Price: ${money(product.price)}
📦 Stock: ${product.stock} pairs available
🏷 Category: ${product.category}
📏 Sizes: ${product.sizes.join(', ')}
🎨 Colors: ${product.colors.join(', ')}

Available at Ayesha Footwear!
''';
              Share.share(shareText);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Preview if available
              if (product.imagePath.isNotEmpty &&
                  File(product.imagePath).existsSync()) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.white,
                    child: Image.file(
                      File(product.imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Hero Product Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.checkroom_outlined, color: AppColors.accent, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  product.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                product.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selling Price',
                              style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              money(product.price),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: stockBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOutOfStock ? Icons.cancel : Icons.check_circle,
                                size: 14,
                                color: stockColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                stockStatusText,
                                style: TextStyle(
                                  color: stockColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Available Sizes Section
              _buildSectionCard(
                title: 'Available Sizes (${product.sizes.length})',
                icon: Icons.straighten,
                child: product.sizes.isEmpty
                    ? const Text('Standard / Free Size', style: TextStyle(color: Colors.black54))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.sizes.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.straighten, size: 14, color: AppColors.deepNavy),
                                const SizedBox(width: 6),
                                Text(
                                  'Size $s',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.deepNavy,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 14),

              // Available Colors Section
              _buildSectionCard(
                title: 'Available Colors (${product.colors.length})',
                icon: Icons.palette_outlined,
                child: product.colors.isEmpty
                    ? const Text('Standard Color', style: TextStyle(color: Colors.black54))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.colors.map((c) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: _guessColor(c),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black26),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.deepNavy,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 14),

              // Article ID & Barcode QR Section
              _buildSectionCard(
                title: 'Product Barcode & Article ID',
                icon: Icons.qr_code_2,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: QrImageView(
                        data: product.id,
                        version: QrVersions.auto,
                        size: 90.0,
                        gapless: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Article / Item Code',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            product.id,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.deepNavy,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Scan with app camera to auto-fetch during billing or inventory count.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action button to bill with this product
              if (onCreateBillWithProduct != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: orangeButton(),
                    onPressed: () {
                      Navigator.pop(context);
                      onCreateBillWithProduct!(product);
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text(
                      'CREATE BILL WITH THIS PRODUCT',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
            children: [
              Icon(icon, size: 18, color: AppColors.deepNavy),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
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
