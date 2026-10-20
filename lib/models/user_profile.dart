class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.mobile,
    required this.email,
    required this.companyName,
    required this.upiId,
    required this.createdAt,
    this.companyId = '',
    this.ownedCompanyIds = const [],
  });

  final String uid;
  final String name;
  final String mobile;
  final String email;
  final String companyName;
  final String upiId;
  final DateTime createdAt;
  final String companyId;
  final List<String> ownedCompanyIds;

  String get effectiveCompanyId {
    if (companyId.trim().isNotEmpty) return companyId.trim();
    final slug = companyName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    if (slug.isNotEmpty) return 'comp_$slug';
    if (uid.trim().isNotEmpty) return 'comp_$uid';
    return 'comp_ayesha_footwear';
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'mobile': mobile,
        'email': email,
        'companyName': companyName,
        'upiId': upiId,
        'createdAt': createdAt.toIso8601String(),
        'companyId': companyId.isNotEmpty ? companyId : effectiveCompanyId,
        'ownedCompanyIds': ownedCompanyIds.isNotEmpty ? ownedCompanyIds : [effectiveCompanyId],
      };

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? defaultUid}) {
    final cName = (map['companyName'] ?? map['company_name'] ?? 'Footwear Store') as String;
    final cId = (map['companyId'] ?? map['company_id'] ?? '') as String;
    List<String> owned = [];
    if (map['ownedCompanyIds'] is List) {
      owned = (map['ownedCompanyIds'] as List).map((e) => e.toString()).toList();
    }

    return UserProfile(
      uid: (map['uid'] ?? defaultUid ?? '') as String,
      name: (map['name'] ?? '') as String,
      mobile: (map['mobile'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      companyName: cName,
      upiId: (map['upiId'] ?? map['upi_id'] ?? '') as String,
      createdAt: DateTime.tryParse((map['createdAt'] ?? '') as String) ?? DateTime.now(),
      companyId: cId,
      ownedCompanyIds: owned,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? mobile,
    String? email,
    String? companyName,
    String? upiId,
    DateTime? createdAt,
    String? companyId,
    List<String>? ownedCompanyIds,
  }) =>
      UserProfile(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        mobile: mobile ?? this.mobile,
        email: email ?? this.email,
        companyName: companyName ?? this.companyName,
        upiId: upiId ?? this.upiId,
        createdAt: createdAt ?? this.createdAt,
        companyId: companyId ?? this.companyId,
        ownedCompanyIds: ownedCompanyIds ?? this.ownedCompanyIds,
      );
}
