import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProductImageService {
  ProductImageService._();
  static final ProductImageService instance = ProductImageService._();

  Directory? _imagesDir;

  void setCustomDirectory(Directory? dir) {
    _imagesDir = dir;
  }

  /// Returns the permanent local directory where product photos are stored.
  Future<Directory> getImagesDirectory() async {
    if (_imagesDir != null) return _imagesDir!;
    Directory baseDir;
    try {
      baseDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir = Directory.systemTemp;
    }
    final dir = Directory(p.join(baseDir.path, 'product_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _imagesDir = dir;
    return dir;
  }

  /// Copies an image from a temporary location (e.g., camera/gallery cache)
  /// permanently to the local app documents directory, and generates a Base64 string
  /// to enable cloud synchronization with Firestore.
  Future<Map<String, String>> saveImageLocally(String sourcePath, {String? customId}) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return {'localPath': '', 'base64': ''};
      }

      final dir = await getImagesDirectory();
      final id = customId ?? 'IMG_${DateTime.now().millisecondsSinceEpoch}';
      final ext = p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
      final cleanId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetPath = p.join(dir.path, '$cleanId$ext');

      // Copy permanently to local device storage
      final savedFile = await sourceFile.copy(targetPath);

      // Read bytes and create Base64 string for Firestore
      final bytes = await savedFile.readAsBytes();
      final base64String = base64Encode(bytes);

      return {
        'localPath': savedFile.path,
        'base64': base64String,
      };
    } catch (e) {
      debugPrint('Error saving product image locally: $e');
      return {'localPath': sourcePath, 'base64': ''};
    }
  }

  /// Restores an image from a Firestore Base64 payload to the local device storage.
  /// Returns the absolute path to the saved local file.
  Future<String> restoreImageFromBase64(String productId, String base64Data) async {
    if (base64Data.trim().isEmpty) return '';
    try {
      final dir = await getImagesDirectory();
      final cleanId = productId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final targetPath = p.join(dir.path, '$cleanId.jpg');
      final targetFile = File(targetPath);

      // If already restored on this device and non-empty, use existing file
      if (await targetFile.exists() && await targetFile.length() > 0) {
        return targetFile.path;
      }

      final bytes = base64Decode(base64Data.trim());
      await targetFile.writeAsBytes(bytes, flush: true);
      return targetFile.path;
    } catch (e) {
      debugPrint('Error restoring image from base64 for $productId: $e');
      return '';
    }
  }

  /// Verifies if a local file exists for the given path.
  bool localImageExists(String path) {
    if (path.trim().isEmpty) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}
