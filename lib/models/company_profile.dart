class CompanyProfile {
  const CompanyProfile({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.mobile,
    required this.upiId,
    required this.createdAt,
    this.address = '',
  });

  final String id;
  final String name;
  final String ownerUid;
  final String mobile;
  final String upiId;
  final DateTime createdAt;
  final String address;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'ownerUid': ownerUid,
        'mobile': mobile,
        'upiId': upiId,
        'createdAt': createdAt.toIso8601String(),
        'address': address,
      };

  factory CompanyProfile.fromMap(Map<String, dynamic> map, {String? defaultId}) {
    DateTime parsedCreatedAt = DateTime.now();
    final rawCreated = map['createdAt'] ?? map['created_at'];
    if (rawCreated is DateTime) {
      parsedCreatedAt = rawCreated;
    } else if (rawCreated != null && rawCreated.runtimeType.toString() == 'Timestamp') {
      try {
        parsedCreatedAt = (rawCreated as dynamic).toDate();
      } catch (_) {}
    } else if (rawCreated is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    }

    return CompanyProfile(
      id: (map['id'] ?? defaultId ?? '') as String,
      name: (map['name'] ?? map['companyName'] ?? 'Ayesha Footwear') as String,
      ownerUid: (map['ownerUid'] ?? map['owner_uid'] ?? '') as String,
      mobile: (map['mobile'] ?? '') as String,
      upiId: (map['upiId'] ?? map['upi_id'] ?? 'atiqullahkhan554@okicici') as String,
      createdAt: parsedCreatedAt,
      address: (map['address'] ?? '') as String,
    );
  }

  CompanyProfile copyWith({
    String? id,
    String? name,
    String? ownerUid,
    String? mobile,
    String? upiId,
    DateTime? createdAt,
    String? address,
  }) =>
      CompanyProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        ownerUid: ownerUid ?? this.ownerUid,
        mobile: mobile ?? this.mobile,
        upiId: upiId ?? this.upiId,
        createdAt: createdAt ?? this.createdAt,
        address: address ?? this.address,
      );
}
