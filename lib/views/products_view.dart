// import 'dart:io';
// import 'package:flutter/material.dart';
//
// import '../app/app_colors.dart';
// import '../models/product.dart';
// import '../widgets/shop_widgets.dart';
// import 'product_details_view.dart';
//
// class ProductsView extends StatefulWidget {
//   const ProductsView({
//     super.key,
//     required this.products,
//     required this.onAddProduct,
//     this.unreadAlertsCount = 0,
//     this.onStockAlerts,
//     this.companyName = 'Ayesha Footwear',
//     this.onCreateBillWithProduct,
//   });
//
//   final List<Product> products;
//   final VoidCallback onAddProduct;
//   final int unreadAlertsCount;
//   final VoidCallback? onStockAlerts;
//   final String companyName;
//   final ValueChanged<Product>? onCreateBillWithProduct;
//
//   @override
//   State<ProductsView> createState() => _ProductsViewState();
// }
//
// class _ProductsViewState extends State<ProductsView> {
//   String query = '';
//
//   List<Product> get filteredProducts {
//     final normalized = query.toLowerCase().trim();
//     if (normalized.isEmpty) return widget.products;
//     return widget.products.where((product) {
//       final searchable =
//           '${product.id} ${product.name} ${product.category} ${product.sizes.join(' ')} ${product.colors.join(' ')}'
//               .toLowerCase();
//       return searchable.contains(normalized);
//     }).toList();
//   }
//
//   void _openProductDetails(Product product) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ProductDetailsView(
//           product: product,
//           onCreateBillWithProduct: widget.onCreateBillWithProduct,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final displayList = filteredProducts;
//
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Header(
//             title: widget.companyName,
//             subtitle: 'Footwear Inventory & Stock',
//             unreadAlertsCount: widget.unreadAlertsCount,
//             onNotificationsPressed: widget.onStockAlerts,
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'Products (${widget.products.length})',
//                   style: Theme.of(context).textTheme.headlineMedium,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               FilledButton.icon(
//                 onPressed: widget.onAddProduct,
//                 style: orangeButton(),
//                 icon: const Icon(Icons.add),
//                 label: const Text('Add Product'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Tap any product below to view available sizes, colors & full details.',
//             style: Theme.of(context).textTheme.bodyMedium,
//           ),
//           const SizedBox(height: 14),
//           TextField(
//             onChanged: (value) => setState(() => query = value),
//             decoration: InputDecoration(
//               prefixIcon: const Icon(Icons.search),
//               hintText: 'Search footwear by name or category...',
//               suffixIcon: query.isNotEmpty
//                   ? IconButton(
//                       icon: const Icon(Icons.clear, size: 18),
//                       onPressed: () => setState(() => query = ''),
//                     )
//                   : null,
//             ),
//           ),
//           const SizedBox(height: 14),
//           Expanded(
//             child: displayList.isEmpty
//                 ? Center(
//                     child: Text(
//                       query.isEmpty
//                           ? 'No products available. Click "+ Add Product" to create one.'
//                           : 'No matching products found.',
//                       style: const TextStyle(color: Color(0xFF6B7280)),
//                     ),
//                   )
//                 : ListView.separated(
//                     itemCount: displayList.length,
//                     separatorBuilder: (_, __) => const SizedBox(height: 10),
//                     itemBuilder: (_, index) {
//                       final product = displayList[index];
//                       return ProductCard(
//                         product: product,
//                         onTap: () => _openProductDetails(product),
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
// class ProductCard extends StatelessWidget {
//   const ProductCard({
//     super.key,
//     required this.product,
//     this.onTap,
//   });
//
//   final Product product;
//   final VoidCallback? onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     final isOutOfStock = product.stock <= 0;
//     final isLowStock = product.stock > 0 && product.stock <= 3;
//
//     Color stockColor = Colors.green.shade800;
//     Color stockBg = Colors.green.shade50;
//     String stockText = '${product.stock} in stock';
//
//     if (isOutOfStock) {
//       stockColor = Colors.red.shade700;
//       stockBg = Colors.red.shade50;
//       stockText = 'Out of stock';
//     } else if (isLowStock) {
//       stockColor = Colors.orange.shade900;
//       stockBg = Colors.orange.shade50;
//       stockText = '${product.stock} left';
//     }
//
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
//             if (product.imagePath.isNotEmpty &&
//                 File(product.imagePath).existsSync())
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.file(
//                   File(product.imagePath),
//                   width: 48,
//                   height: 48,
//                   fit: BoxFit.cover,
//                 ),
//               )
//             else
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   color: AppColors.deepNavy,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(
//                   Icons.checkroom_outlined,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     product.name,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w800,
//                       color: AppColors.mainText,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: stockBg,
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Text(
//                           stockText,
//                           style: TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w700,
//                             color: stockColor,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         '(${product.sizes.length} sizes, ${product.colors.length} colors)',
//                         style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   money(product.price),
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w900,
//                     color: AppColors.deepNavy,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       'Details',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: Color(0xFF2563EB),
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     Icon(
//                       Icons.chevron_right,
//                       size: 16,
//                       color: Color(0xFF2563EB),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }```dart
// import 'dart:io';
// import 'package:flutter/material.dart';
//
// import '../app/app_colors.dart';
// import '../models/product.dart';
// import '../widgets/shop_widgets.dart';
// import 'product_details_view.dart';
//
// class ProductsView extends StatefulWidget {
//   const ProductsView({
//     super.key,
//     required this.products,
//     required this.onAddProduct,
//     this.unreadAlertsCount = 0,
//     this.onStockAlerts,
//     this.companyName = 'Ayesha Footwear',
//     this.onCreateBillWithProduct,
//   });
//
//   final List<Product> products;
//   final VoidCallback onAddProduct;
//   final int unreadAlertsCount;
//   final VoidCallback? onStockAlerts;
//   final String companyName;
//   final ValueChanged<Product>? onCreateBillWithProduct;
//
//   @override
//   State<ProductsView> createState() => _ProductsViewState();
// }
//
// class _ProductsViewState extends State<ProductsView> {
//   String query = '';
//
//   List<Product> get filteredProducts {
//     final normalized = query.toLowerCase().trim();
//
//     if (normalized.isEmpty) return widget.products;
//
//     return widget.products.where((product) {
//       final searchable =
//           '${product.id} ${product.name} ${product.category} '
//           '${product.sizes.join(' ')} ${product.colors.join(' ')}'
//               .toLowerCase();
//
//       return searchable.contains(normalized);
//     }).toList();
//   }
//
//   void _openProductDetails(Product product) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ProductDetailsView(
//           product: product,
//           onCreateBillWithProduct: widget.onCreateBillWithProduct,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final displayList = filteredProducts;
//     final theme = Theme.of(context);
//
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Header(
//             title: widget.companyName,
//             subtitle: 'Footwear Inventory & Stock',
//             unreadAlertsCount: widget.unreadAlertsCount,
//             onNotificationsPressed: widget.onStockAlerts,
//           ),
//
//           const SizedBox(height: 24),
//
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Products',
//                       style: theme.textTheme.headlineMedium?.copyWith(
//                         fontSize: 23,
//                         fontWeight: FontWeight.w800,
//                         color: AppColors.mainText,
//                         letterSpacing: -0.6,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       '${widget.products.length} products in inventory',
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         fontSize: 12,
//                         color: const Color(0xFF64748B),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 10),
//               FilledButton.icon(
//                 onPressed: widget.onAddProduct,
//                 style: orangeButton().copyWith(
//                   padding: const WidgetStatePropertyAll(
//                     EdgeInsets.symmetric(
//                       horizontal: 13,
//                       vertical: 12,
//                     ),
//                   ),
//                   shape: WidgetStatePropertyAll(
//                     RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   elevation: const WidgetStatePropertyAll(0),
//                 ),
//                 icon: const Icon(Icons.add_rounded, size: 19),
//                 label: const Text(
//                   'Add Product',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 18),
//
//           TextField(
//             onChanged: (value) => setState(() => query = value),
//             style: const TextStyle(
//               fontSize: 13,
//               color: AppColors.mainText,
//               fontWeight: FontWeight.w500,
//             ),
//             decoration: InputDecoration(
//               prefixIcon: const Icon(
//                 Icons.search_rounded,
//                 size: 21,
//                 color: Color(0xFF64748B),
//               ),
//               hintText: 'Search by product name, category, size...',
//               hintStyle: const TextStyle(
//                 fontSize: 12,
//                 color: Color(0xFF94A3B8),
//               ),
//               suffixIcon: query.isNotEmpty
//                   ? IconButton(
//                       tooltip: 'Clear search',
//                       icon: const Icon(
//                         Icons.close_rounded,
//                         size: 18,
//                       ),
//                       onPressed: () => setState(() => query = ''),
//                     )
//                   : null,
//               filled: true,
//               fillColor: Colors.white,
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 14,
//                 vertical: 14,
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: const BorderSide(
//                   color: Color(0xFFDCE4ED),
//                 ),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: const BorderSide(
//                   color: Color(0xFFDCE4ED),
//                 ),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: const BorderSide(
//                   color: AppColors.deepNavy,
//                   width: 1.3,
//                 ),
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           Expanded(
//             child: displayList.isEmpty
//                 ? Center(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 24,
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Container(
//                             width: 64,
//                             height: 64,
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFEEF3FA),
//                               borderRadius: BorderRadius.circular(18),
//                             ),
//                             child: const Icon(
//                               Icons.inventory_2_outlined,
//                               size: 29,
//                               color: AppColors.deepNavy,
//                             ),
//                           ),
//                           const SizedBox(height: 14),
//                           Text(
//                             query.isEmpty
//                                 ? 'No products yet'
//                                 : 'No matching products found',
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w700,
//                               color: AppColors.mainText,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             query.isEmpty
//                                 ? 'Add your first product to get started.'
//                                 : 'Try another product name, category, or size.',
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(
//                               fontSize: 12,
//                               height: 1.5,
//                               color: Color(0xFF64748B),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 : ListView.separated(
//                     padding: const EdgeInsets.only(
//                       bottom: 24,
//                       top: 3,
//                     ),
//                     itemCount: displayList.length,
//                     separatorBuilder: (_, __) =>
//                         const SizedBox(height: 14),
//                     itemBuilder: (_, index) {
//                       final product = displayList[index];
//
//                       return ProductCard(
//                         product: product,
//                         onTap: () => _openProductDetails(product),
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
// class ProductCard extends StatelessWidget {
//   const ProductCard({
//     super.key,
//     required this.product,
//     this.onTap,
//   });
//
//   final Product product;
//   final VoidCallback? onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     final isOutOfStock = product.stock <= 0;
//     final isLowStock = product.stock > 0 && product.stock <= 3;
//
//     Color stockColor = const Color(0xFF15803D);
//     Color stockBg = const Color(0xFFDCFCE7);
//     String stockText = '${product.stock} in stock';
//     IconData stockIcon = Icons.check_circle_outline_rounded;
//
//     if (isOutOfStock) {
//       stockColor = const Color(0xFFB91C1C);
//       stockBg = const Color(0xFFFEE2E2);
//       stockText = 'Out of stock';
//       stockIcon = Icons.error_outline_rounded;
//     } else if (isLowStock) {
//       stockColor = const Color(0xFFB45309);
//       stockBg = const Color(0xFFFEF3C7);
//       stockText = '${product.stock} left';
//       stockIcon = Icons.warning_amber_rounded;
//     }
//
//     final hasImage = product.imagePath.isNotEmpty &&
//         File(product.imagePath).existsSync();
//
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           padding: const EdgeInsets.all(13),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: const Color(0xFFD7E0EB),
//               width: 1.1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF172B4D).withOpacity(0.065),
//                 blurRadius: 12,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // Product image or custom footwear placeholder.
//               Container(
//                 width: 68,
//                 height: 76,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF0F4F9),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: const Color(0xFFE4EAF2),
//                   ),
//                 ),
//                 clipBehavior: Clip.antiAlias,
//                 child: hasImage
//                     ? Image.file(
//                         File(product.imagePath),
//                         fit: BoxFit.cover,
//                         errorBuilder: (_, __, ___) =>
//                             const _FootwearPlaceholder(),
//                       )
//                     : const _FootwearPlaceholder(),
//               ),
//
//               const SizedBox(width: 13),
//
//               // Product information.
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       product.name,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 14,
//                         height: 1.35,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: 0.1,
//                         color: AppColors.mainText,
//                       ),
//                     ),
//
//                     const SizedBox(height: 8),
//
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 5,
//                       ),
//                       decoration: BoxDecoration(
//                         color: stockBg,
//                         borderRadius: BorderRadius.circular(7),
//                         border: Border.all(
//                           color: stockColor.withOpacity(0.12),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             stockIcon,
//                             size: 12,
//                             color: stockColor,
//                           ),
//                           const SizedBox(width: 4),
//                           Flexible(
//                             child: Text(
//                               stockText,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 height: 1.2,
//                                 fontWeight: FontWeight.w700,
//                                 color: stockColor,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 9),
//
//                     Wrap(
//                       spacing: 10,
//                       runSpacing: 5,
//                       children: [
//                         _ProductMeta(
//                           icon: Icons.straighten_rounded,
//                           text: '${product.sizes.length} sizes',
//                         ),
//                         _ProductMeta(
//                           icon: Icons.palette_outlined,
//                           text: '${product.colors.length} colors',
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(width: 8),
//
//               // Price and details.
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     money(product.price),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w800,
//                       letterSpacing: -0.3,
//                       color: AppColors.deepNavy,
//                     ),
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFEAF2FF),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                         color: const Color(0xFFD8E6FF),
//                       ),
//                     ),
//                     child: const Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           'Details',
//                           style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF1D4ED8),
//                           ),
//                         ),
//                         SizedBox(width: 2),
//                         Icon(
//                           Icons.chevron_right_rounded,
//                           size: 14,
//                           color: Color(0xFF1D4ED8),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /// Custom ladies' footwear-style placeholder.
// /// Drawn using Flutter Canvas; no image asset or extra package required.
// class _FootwearPlaceholder extends StatelessWidget {
//   const _FootwearPlaceholder();
//
//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: CustomPaint(
//         size: Size(56, 56),
//         painter: _SandalPainter(),
//       ),
//     );
//   }
// }
//
// class _SandalPainter extends CustomPainter {
//   const _SandalPainter();
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final sx = size.width / 56;
//     final sy = size.height / 56;
//
//     canvas.save();
//     canvas.scale(sx, sy);
//
//     final solePaint = Paint()
//       ..color = const Color(0xFFCBD5E1)
//       ..style = PaintingStyle.fill;
//
//     final shoePaint = Paint()
//       ..color = const Color(0xFF172B4D)
//       ..style = PaintingStyle.fill;
//
//     final strapPaint = Paint()
//       ..color = const Color(0xFFF29B38)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.5
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round;
//
//     // Sandal sole.
//     final sole = Path()
//       ..moveTo(13, 43)
//       ..cubicTo(10, 39, 13, 32, 18, 25)
//       ..cubicTo(22, 19, 29, 13, 34, 15)
//       ..cubicTo(39, 17, 39, 25, 36, 31)
//       ..cubicTo(33, 37, 26, 44, 20, 46)
//       ..cubicTo(17, 47, 14, 46, 13, 43)
//       ..close();
//
//     canvas.drawPath(sole, solePaint);
//
//     // Main sandal body.
//     final shoe = Path()
//       ..moveTo(15, 40)
//       ..cubicTo(13, 36, 17, 29, 21, 24)
//       ..cubicTo(25, 19, 30, 15, 33, 17)
//       ..cubicTo(36, 19, 35, 24, 32, 30)
//       ..cubicTo(29, 35, 23, 41, 19, 43)
//       ..cubicTo(17, 44, 15, 42, 15, 40)
//       ..close();
//
//     canvas.drawPath(shoe, shoePaint);
//
//     // Decorative sandal straps.
//     final strapOne = Path()
//       ..moveTo(20, 35)
//       ..quadraticBezierTo(24, 29, 29, 25);
//
//     final strapTwo = Path()
//       ..moveTo(24, 39)
//       ..quadraticBezierTo(25, 33, 25, 27);
//
//     canvas.drawPath(strapOne, strapPaint);
//     canvas.drawPath(strapTwo, strapPaint);
//
//     // Small buckle accent.
//     final bucklePaint = Paint()
//       ..color = const Color(0xFFFFC16B)
//       ..style = PaintingStyle.fill;
//
//     canvas.drawCircle(
//       const Offset(29, 25),
//       2.1,
//       bucklePaint,
//     );
//
//     canvas.restore();
//   }
//
//   @override
//   bool shouldRepaint(covariant _SandalPainter oldDelegate) => false;
// }
//
// class _ProductMeta extends StatelessWidget {
//   const _ProductMeta({
//     required this.icon,
//     required this.text,
//   });
//
//   final IconData icon;
//   final String text;
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(
//           icon,
//           size: 12,
//           color: const Color(0xFF8493A7),
//         ),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: const TextStyle(
//             fontSize: 10,
//             fontWeight: FontWeight.w500,
//             color: Color(0xFF64748B),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/product.dart';
import '../widgets/product_image_widget.dart';
import '../widgets/shop_widgets.dart';
import 'product_details_view.dart';

class ProductsView extends StatefulWidget {
const ProductsView({
super.key,
required this.products,
required this.onAddProduct,
this.unreadAlertsCount = 0,
this.onStockAlerts,
this.companyName = 'Ayesha Footwear',
this.onCreateBillWithProduct,
});

final List<Product> products;
final VoidCallback onAddProduct;
final int unreadAlertsCount;
final VoidCallback? onStockAlerts;
final String companyName;
final ValueChanged<Product>? onCreateBillWithProduct;

@override
State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
String query = '';

List<Product> get filteredProducts {
final normalized = query.toLowerCase().trim();

if (normalized.isEmpty) return widget.products;

return widget.products.where((product) {
final searchable =
'${product.id} ${product.name} ${product.category} '
'${product.sizes.join(' ')} ${product.colors.join(' ')}'
    .toLowerCase();

return searchable.contains(normalized);
}).toList();
}

void _openProductDetails(Product product) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ProductDetailsView(
product: product,
onCreateBillWithProduct: widget.onCreateBillWithProduct,
),
),
);
}

@override
Widget build(BuildContext context) {
final displayList = filteredProducts;
final theme = Theme.of(context);

return Padding(
padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Header(
title: widget.companyName,
subtitle: 'Footwear Inventory & Stock',
unreadAlertsCount: widget.unreadAlertsCount,
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
'Products',
style: theme.textTheme.headlineMedium?.copyWith(
fontSize: 23,
fontWeight: FontWeight.w800,
color: AppColors.mainText,
letterSpacing: -0.6,
),
),
const SizedBox(height: 4),
Text(
'${widget.products.length} products in inventory',
style: theme.textTheme.bodySmall?.copyWith(
fontSize: 12,
color: const Color(0xFF64748B),
fontWeight: FontWeight.w500,
),
),
],
),
),
const SizedBox(width: 10),
FilledButton.icon(
onPressed: widget.onAddProduct,
style: orangeButton().copyWith(
padding: const WidgetStatePropertyAll(
EdgeInsets.symmetric(
horizontal: 13,
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
icon: const Icon(Icons.add_rounded, size: 19),
label: const Text(
'Add Product',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
),
],
),

const SizedBox(height: 18),

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
hintText: 'Search by product name, category, size...',
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

const SizedBox(height: 16),

Expanded(
child: displayList.isEmpty
? Center(
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 24,
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 64,
height: 64,
decoration: BoxDecoration(
color: const Color(0xFFEEF3FA),
borderRadius: BorderRadius.circular(18),
),
child: const Icon(
Icons.inventory_2_outlined,
size: 29,
color: AppColors.deepNavy,
),
),
const SizedBox(height: 14),
Text(
query.isEmpty
? 'No products yet'
    : 'No matching products found',
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w700,
color: AppColors.mainText,
),
),
const SizedBox(height: 6),
Text(
query.isEmpty
? 'Add your first product to get started.'
    : 'Try another product name, category, or size.',
textAlign: TextAlign.center,
style: const TextStyle(
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
bottom: 24,
top: 3,
),
itemCount: displayList.length,
separatorBuilder: (_, __) =>
const SizedBox(height: 14),
itemBuilder: (_, index) {
final product = displayList[index];

return ProductCard(
product: product,
onTap: () => _openProductDetails(product),
);
},
),
),
],
),
);
}
}

class ProductCard extends StatelessWidget {
const ProductCard({
super.key,
required this.product,
this.onTap,
});

final Product product;
final VoidCallback? onTap;

@override
Widget build(BuildContext context) {
final isOutOfStock = product.stock <= 0;
final isLowStock = product.stock > 0 && product.stock <= 3;

Color stockColor = const Color(0xFF15803D);
Color stockBg = const Color(0xFFDCFCE7);
String stockText = '${product.stock} in stock';
IconData stockIcon = Icons.check_circle_outline_rounded;

if (isOutOfStock) {
stockColor = const Color(0xFFB91C1C);
stockBg = const Color(0xFFFEE2E2);
stockText = 'Out of stock';
stockIcon = Icons.error_outline_rounded;
} else if (isLowStock) {
stockColor = const Color(0xFFB45309);
stockBg = const Color(0xFFFEF3C7);
stockText = '${product.stock} left';
stockIcon = Icons.warning_amber_rounded;
}

return Material(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(16),
child: Container(
padding: const EdgeInsets.all(13),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: const Color(0xFFD7E0EB),
width: 1.1,
),
boxShadow: [
BoxShadow(
color: const Color(0xFF172B4D).withOpacity(0.065),
blurRadius: 12,
offset: const Offset(0, 4),
),
],
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
// Product image or custom footwear placeholder.
Container(
width: 68,
height: 76,
decoration: BoxDecoration(
color: const Color(0xFFF0F4F9),
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: const Color(0xFFE4EAF2),
),
),
clipBehavior: Clip.antiAlias,
child: ProductImageWidget(
product: product,
placeholder: const _FootwearPlaceholder(),
),
),

const SizedBox(width: 13),

// Product information.
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisSize: MainAxisSize.min,
children: [
Text(
product.name,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 14,
height: 1.35,
fontWeight: FontWeight.w700,
letterSpacing: 0.1,
color: AppColors.mainText,
),
),

const SizedBox(height: 8),

Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 5,
),
decoration: BoxDecoration(
color: stockBg,
borderRadius: BorderRadius.circular(7),
border: Border.all(
color: stockColor.withOpacity(0.12),
),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
stockIcon,
size: 12,
color: stockColor,
),
const SizedBox(width: 4),
Flexible(
child: Text(
stockText,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 10,
height: 1.2,
fontWeight: FontWeight.w700,
color: stockColor,
),
),
),
],
),
),

const SizedBox(height: 9),

Wrap(
spacing: 10,
runSpacing: 5,
children: [
_ProductMeta(
icon: Icons.straighten_rounded,
text: '${product.sizes.length} sizes',
),
_ProductMeta(
icon: Icons.palette_outlined,
text: '${product.colors.length} colors',
),
],
),
],
),
),

const SizedBox(width: 8),

// Price and details.
Column(
crossAxisAlignment: CrossAxisAlignment.end,
mainAxisAlignment: MainAxisAlignment.center,
mainAxisSize: MainAxisSize.min,
children: [
Text(
money(product.price),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w800,
letterSpacing: -0.3,
color: AppColors.deepNavy,
),
),

const SizedBox(height: 10),

Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 6,
),
decoration: BoxDecoration(
color: const Color(0xFFEAF2FF),
borderRadius: BorderRadius.circular(8),
border: Border.all(
color: const Color(0xFFD8E6FF),
),
),
child: const Row(
mainAxisSize: MainAxisSize.min,
children: [
Text(
'Details',
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w700,
color: Color(0xFF1D4ED8),
),
),
SizedBox(width: 2),
Icon(
Icons.chevron_right_rounded,
size: 14,
color: Color(0xFF1D4ED8),
),
],
),
),
],
),
],
),
),
),
);
}
}

/// Custom ladies' footwear-style placeholder.
/// Drawn using Flutter Canvas; no image asset or extra package required.
class _FootwearPlaceholder extends StatelessWidget {
const _FootwearPlaceholder();

@override
Widget build(BuildContext context) {
return const Center(
child: CustomPaint(
size: Size(56, 56),
painter: _SandalPainter(),
),
);
}
}

class _SandalPainter extends CustomPainter {
const _SandalPainter();

@override
void paint(Canvas canvas, Size size) {
final sx = size.width / 56;
final sy = size.height / 56;

canvas.save();
canvas.scale(sx, sy);

final solePaint = Paint()
..color = const Color(0xFFCBD5E1)
..style = PaintingStyle.fill;

final shoePaint = Paint()
..color = const Color(0xFF172B4D)
..style = PaintingStyle.fill;

final strapPaint = Paint()
..color = const Color(0xFFF29B38)
..style = PaintingStyle.stroke
..strokeWidth = 3.5
..strokeCap = StrokeCap.round
..strokeJoin = StrokeJoin.round;

// Sandal sole.
final sole = Path()
..moveTo(13, 43)
..cubicTo(10, 39, 13, 32, 18, 25)
..cubicTo(22, 19, 29, 13, 34, 15)
..cubicTo(39, 17, 39, 25, 36, 31)
..cubicTo(33, 37, 26, 44, 20, 46)
..cubicTo(17, 47, 14, 46, 13, 43)
..close();

canvas.drawPath(sole, solePaint);

// Main sandal body.
final shoe = Path()
..moveTo(15, 40)
..cubicTo(13, 36, 17, 29, 21, 24)
..cubicTo(25, 19, 30, 15, 33, 17)
..cubicTo(36, 19, 35, 24, 32, 30)
..cubicTo(29, 35, 23, 41, 19, 43)
..cubicTo(17, 44, 15, 42, 15, 40)
..close();

canvas.drawPath(shoe, shoePaint);

// Decorative sandal straps.
final strapOne = Path()
..moveTo(20, 35)
..quadraticBezierTo(24, 29, 29, 25);

final strapTwo = Path()
..moveTo(24, 39)
..quadraticBezierTo(25, 33, 25, 27);

canvas.drawPath(strapOne, strapPaint);
canvas.drawPath(strapTwo, strapPaint);

// Small buckle accent.
final bucklePaint = Paint()
..color = const Color(0xFFFFC16B)
..style = PaintingStyle.fill;

canvas.drawCircle(
const Offset(29, 25),
2.1,
bucklePaint,
);

canvas.restore();
}

@override
bool shouldRepaint(covariant _SandalPainter oldDelegate) => false;
}

class _ProductMeta extends StatelessWidget {
const _ProductMeta({
required this.icon,
required this.text,
});

final IconData icon;
final String text;

@override
Widget build(BuildContext context) {
return Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 12,
color: const Color(0xFF8493A7),
),
const SizedBox(width: 4),
Text(
text,
style: const TextStyle(
fontSize: 10,
fontWeight: FontWeight.w500,
color: Color(0xFF64748B),
),
),
],
);
}
}

