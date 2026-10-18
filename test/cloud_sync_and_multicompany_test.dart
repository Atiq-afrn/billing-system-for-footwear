import 'package:flutter_test/flutter_test.dart';

import 'package:ayesha_footwear/models/company_profile.dart';
import 'package:ayesha_footwear/models/user_profile.dart';
import 'package:ayesha_footwear/services/cloud_sync_service.dart';

void main() {
  group('CompanyProfile Model Tests', () {
    test('Serializes to and from Map correctly', () {
      final now = DateTime(2026, 10, 13);
      final company = CompanyProfile(
        id: 'comp_ayesha_footwear',
        name: 'Ayesha Footwear Main Store',
        ownerUid: 'uid_123',
        mobile: '9876543210',
        upiId: 'ayesha@okaxis',
        createdAt: now,
        address: 'MG Road, Kanpur',
      );

      final map = company.toMap();
      expect(map['id'], 'comp_ayesha_footwear');
      expect(map['name'], 'Ayesha Footwear Main Store');
      expect(map['ownerUid'], 'uid_123');
      expect(map['mobile'], '9876543210');
      expect(map['upiId'], 'ayesha@okaxis');
      expect(map['address'], 'MG Road, Kanpur');

      final fromMap = CompanyProfile.fromMap(map, defaultId: 'comp_ayesha_footwear');
      expect(fromMap.id, 'comp_ayesha_footwear');
      expect(fromMap.name, 'Ayesha Footwear Main Store');
      expect(fromMap.ownerUid, 'uid_123');
      expect(fromMap.mobile, '9876543210');
      expect(fromMap.upiId, 'ayesha@okaxis');
      expect(fromMap.address, 'MG Road, Kanpur');
    });

    test('UserProfile generates clean effectiveCompanyId slug from company name', () {
      final profile = UserProfile(
        uid: 'user_99',
        name: 'Atiqu Khan',
        mobile: '9876543210',
        email: 'atiq@example.com',
        companyName: 'Ayesha Footwear Branch #2',
        upiId: 'atiq@okicici',
        createdAt: DateTime.now(),
      );

      expect(profile.effectiveCompanyId, contains('ayesha_footwear_branch__2'));
    });

    test('UserProfile handles explicit companyId and ownedCompanyIds', () {
      final profile = UserProfile(
        uid: 'user_99',
        name: 'Atiqu Khan',
        mobile: '9876543210',
        email: 'atiq@example.com',
        companyName: 'Ayesha Footwear',
        upiId: 'atiq@okicici',
        companyId: 'comp_custom_store_1',
        ownedCompanyIds: ['comp_custom_store_1', 'comp_branch_2'],
        createdAt: DateTime.now(),
      );

      expect(profile.effectiveCompanyId, 'comp_custom_store_1');
      expect(profile.ownedCompanyIds, contains('comp_branch_2'));
    });
  });

  group('CloudSyncStatus Enum & Service Tests', () {
    test('Status enum provides user-friendly labels for each state', () {
      expect(CloudSyncStatus.idle.label, 'Ready');
      expect(CloudSyncStatus.syncing.label, 'Syncing Cloud...');
      expect(CloudSyncStatus.synced.label, 'Cloud Synced');
      expect(CloudSyncStatus.offline.label, 'Offline (Local)');
      expect(CloudSyncStatus.error.label, 'Sync Warning');
    });

    test('CloudSyncService initializes in idle state without throwing', () {
      final service = CloudSyncService.instance;
      service.initialize(null);
      expect(service.status, CloudSyncStatus.idle);
      expect(service.lastError, isNull);
    });
  });
}
