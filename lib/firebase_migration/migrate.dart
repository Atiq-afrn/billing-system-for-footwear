import 'dart:convert';
import 'dart:io';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';

Future<void> main() async {
  print('🚀 Starting migration...\n');

  // IMPORTANT: Replace 'smart-app-platform' with your actual Firebase Project ID
  // (You can find this in your Firebase Console Project Settings)
  final admin = FirebaseAdminApp.initializeApp(
    'smart-app-platform',
    Credential.fromServiceAccount(File('serviceAccountKey.json')),
  );

  final firestore = Firestore(admin);

  final jsonFile = File('ayesha_footwear.json');
  final rawData = jsonDecode(await jsonFile.readAsString());
  final tables = rawData['tables'] as Map<String, dynamic>;

  // Helper: Convert ISO date strings to Firestore Timestamps
  dynamic toTimestamp(String? isoString) {
    if (isoString == null) return null;
    return DateTime.parse(isoString);
  }

  // Helper: Parse items_json strings into real arrays
  List<dynamic> parseItemsJson(String? jsonString) {
    if (jsonString == null) return [];
    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  // --- Migrate Collections under companies/comp_ayesha_footwear ---
  const companyId = 'comp_ayesha_footwear';
  final companyDoc = firestore.collection('companies').doc(companyId);
  await companyDoc.set({
    'id': companyId,
    'name': 'Ayesha Footwear',
    'createdAt': DateTime.now().toIso8601String(),
    'upiId': 'atiqullahkhan554@okicici',
  });

  await _migrateCollection(companyDoc, 'categories', tables['categories'] as List, 'name');

  await _migrateCollection(companyDoc, 'products', tables['products'] as List, 'id');

  await _migrateCollection(companyDoc, 'customers', tables['customers'] as List, 'id');

  await _migrateCollection(companyDoc, 'bills', tables['bills'] as List, 'id', transform: (doc) {
    if (doc['items_json'] != null) {
      doc['items'] = parseItemsJson(doc['items_json']);
      doc.remove('items_json');
    }
    doc['created_at'] = toTimestamp(doc['created_at'] as String?);
    return doc;
  });

  await _migrateCollection(companyDoc, 'customer_loyalty', tables['customer_loyalty'] as List, 'customer_id');

  await _migrateCollection(companyDoc, 'loyalty_settings', tables['loyalty_settings'] as List, 'id');

  await _migrateCollection(companyDoc, 'offers', tables['offers'] as List, 'id', transform: (doc) {
    doc['valid_from'] = toTimestamp(doc['valid_from'] as String?);
    doc['valid_until'] = toTimestamp(doc['valid_until'] as String?);
    return doc;
  });

  await _migrateCollection(companyDoc, 'offer_tracking', tables['offer_tracking'] as List, 'id', transform: (doc) {
    doc['sent_at'] = toTimestamp(doc['sent_at'] as String?);
    doc['redeemed_at'] = toTimestamp(doc['redeemed_at'] as String?);
    return doc;
  });

  await _migrateCollection(companyDoc, 'returns', tables['returns'] as List, 'id', transform: (doc) {
    doc['created_at'] = toTimestamp(doc['created_at'] as String?);
    doc['processed_at'] = toTimestamp(doc['processed_at'] as String?);
    if (doc['items_json'] != null) {
      doc['items'] = parseItemsJson(doc['items_json']);
      doc.remove('items_json');
    }
    if (doc['exchange_items_json'] != null) {
      doc['exchange_items'] = parseItemsJson(doc['exchange_items_json']);
      doc.remove('exchange_items_json');
    }
    return doc;
  });

  await _migrateCollection(companyDoc, 'stock_movements', tables['stock_movements'] as List, 'id', transform: (doc) {
    doc['created_at'] = toTimestamp(doc['created_at'] as String?);
    return doc;
  });

  print('\n🎉 Migration complete! Only companies collection created at root.');
  await admin.close();
}

Future<void> _migrateCollection(
    DocumentReference companyDoc,
    String collectionName,
    List<dynamic> documents,
    String idField, {
      Map<String, dynamic> Function(Map<String, dynamic>)? transform,
    }) async {
  print('📦 Migrating $collectionName (${documents.length} docs)...');

  int count = 0;
  for (final doc in documents) {
    final docMap = Map<String, dynamic>.from(doc as Map);
    final docId = docMap[idField]?.toString() ??
        companyDoc.collection(collectionName).doc().id;

    var finalDoc = docMap;
    if (transform != null) {
      finalDoc = transform(docMap);
    }

    // Write strictly under companies/{companyId}/{collectionName}/{docId}
    await companyDoc.collection(collectionName).doc(docId).set(finalDoc);
    count++;

    if (count % 100 == 0) {
      print('  ✅ Written $count docs so far...');
    }
  }

  print('  ✅ $collectionName: $count documents migrated under company');
}