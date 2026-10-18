import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_image_service.dart';

class ProductImageWidget extends StatelessWidget {
  const ProductImageWidget({
    super.key,
    required this.product,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  final Product product;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    Widget content;

    final hasLocalFile = product.imagePath.isNotEmpty &&
        ProductImageService.instance.localImageExists(product.imagePath);

    if (hasLocalFile) {
      content = Image.file(
        File(product.imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallbackOrMemory(),
      );
    } else if (product.imageBase64.isNotEmpty) {
      content = _buildFromMemory();
    } else {
      content = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }
    return content;
  }

  Widget _buildFallbackOrMemory() {
    if (product.imageBase64.isNotEmpty) {
      return _buildFromMemory();
    }
    return _buildFallback();
  }

  Widget _buildFromMemory() {
    try {
      final bytes = base64Decode(product.imageBase64);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } catch (_) {
      return _buildFallback();
    }
  }

  Widget _buildFallback() {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.checkroom_outlined,
          size: 22,
          color: Color(0xFF0F2648),
        ),
      ),
    );
  }
}
