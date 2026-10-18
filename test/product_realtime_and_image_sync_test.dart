import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ayesha_footwear/models/product.dart';
import 'package:ayesha_footwear/models/product_draft.dart';
import 'package:ayesha_footwear/services/product_image_service.dart';
import 'package:ayesha_footwear/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Product Model Serialization & Firestore Compatibility', () {
    test('Product handles string sizes/colors and imageBase64', () {
      final map = {
        'id': 'PROD-999',
        'name': 'Casual Oxford Shoes',
        'category': 'Men Casual',
        'stock': 12,
        'price': 1999,
        'sizes': '7,8,9,10',
        'colors': 'Black,Brown',
        'image_path': '/local/path/img.jpg',
        'image_base64': 'dGVzdF9pbWFnZV9kYXRh',
      };

      final product = Product.fromMap(map);
      expect(product.id, equals('PROD-999'));
      expect(product.name, equals('Casual Oxford Shoes'));
      expect(product.stock, equals(12));
      expect(product.price, equals(1999));
      expect(product.sizes, equals(['7', '8', '9', '10']));
      expect(product.colors, equals(['Black', 'Brown']));
      expect(product.imagePath, equals('/local/path/img.jpg'));
      expect(product.imageBase64, equals('dGVzdF9pbWFnZV9kYXRh'));

      final outMap = product.toMap();
      expect(outMap['sizes'], equals('7,8,9,10'));
      expect(outMap['colors'], equals('Black,Brown'));
      expect(outMap['image_base64'], equals('dGVzdF9pbWFnZV9kYXRh'));
    });

    test('Product safely parses Firestore List types and double numbers', () {
      final firestoreMap = {
        'id': 'PROD-100',
        'name': 'Sports Runner',
        'category': 'Men Sports',
        'stock': 25.0, // Firestore num / double
        'price': 1499.0,
        'sizes': ['8', '9', '10'], // Firestore array
        'colors': ['Blue', 'White'], // Firestore array
        'image_path': null,
        'image_base64': 'base64_payload',
      };

      final product = Product.fromMap(firestoreMap);
      expect(product.stock, equals(25));
      expect(product.price, equals(1499));
      expect(product.sizes, equals(['8', '9', '10']));
      expect(product.colors, equals(['Blue', 'White']));
      expect(product.imagePath, isEmpty);
      expect(product.imageBase64, equals('base64_payload'));
    });

    test('ProductDraft supports imageBase64 payload', () {
      const draft = ProductDraft(
        name: 'Ladies Heeled Sandal',
        category: 'Women Heels',
        stock: 5,
        price: 1299,
        sizes: ['5', '6', '7'],
        colors: ['Red', 'Black'],
        imagePath: '/path/test.jpg',
        imageBase64: 'sample_base64',
      );

      expect(draft.imageBase64, equals('sample_base64'));
      expect(draft.imagePath, equals('/path/test.jpg'));
    });
  });

  group('ProductImageService Local Storage & Restoration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ayesha_img_test_');
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('restoreImageFromBase64 writes binary data to local file', () async {
      final sampleString = 'AYESHA_FOOTWEAR_TEST_IMAGE_BYTES';
      final base64String = base64Encode(utf8.encode(sampleString));

      final restoredPath = await ProductImageService.instance.restoreImageFromBase64(
        'TEST-PROD-001',
        base64String,
      );

      expect(restoredPath, isNotEmpty);
      final restoredFile = File(restoredPath);
      expect(await restoredFile.exists(), isTrue);

      final content = await restoredFile.readAsString();
      expect(content, equals(sampleString));

      // Clean up created file
      try {
        await restoredFile.delete();
      } catch (_) {}
    });

    test('localImageExists correctly checks path validity', () {
      expect(ProductImageService.instance.localImageExists(''), isFalse);
      expect(ProductImageService.instance.localImageExists('/invalid/non_existent_file.jpg'), isFalse);
    });
  });

  group('SQLite Database Schema & image_base64 column', () {
    test('products table contains image_path and image_base64 columns', () async {
      final tempDbDir = await Directory.systemTemp.createTemp('db_test_');
      final dbService = DatabaseService('${tempDbDir.path}/test_ayesha.db');
      final db = await dbService.database;

      final info = await db.rawQuery('PRAGMA table_info(products)');
      final columnNames = info.map((r) => r['name'] as String).toList();

      expect(columnNames, contains('id'));
      expect(columnNames, contains('name'));
      expect(columnNames, contains('category'));
      expect(columnNames, contains('stock'));
      expect(columnNames, contains('price'));
      expect(columnNames, contains('sizes'));
      expect(columnNames, contains('colors'));
      expect(columnNames, contains('image_path'));
      expect(columnNames, contains('image_base64'));

      await db.close();
      try {
        await tempDbDir.delete(recursive: true);
      } catch (_) {}
    });
  });
}
