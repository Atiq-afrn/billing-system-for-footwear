import 'package:flutter/material.dart';

import 'bill.dart';
import 'customer.dart';

enum CustomerSegment {
  highSpending,
  loyal,
  regular,
  newCustomer,
  inactive;

  String get displayName {
    switch (this) {
      case CustomerSegment.highSpending:
        return 'High-Spending VIP';
      case CustomerSegment.loyal:
        return 'Loyal Customer';
      case CustomerSegment.regular:
        return 'Regular Customer';
      case CustomerSegment.newCustomer:
        return 'New Customer';
      case CustomerSegment.inactive:
        return 'Inactive / At Risk';
    }
  }

  Color get color {
    switch (this) {
      case CustomerSegment.highSpending:
        return const Color(0xFFD97706); // Amber Gold
      case CustomerSegment.loyal:
        return const Color(0xFF10B981); // Emerald Green
      case CustomerSegment.regular:
        return const Color(0xFF2563EB); // Royal Blue
      case CustomerSegment.newCustomer:
        return const Color(0xFF0D9488); // Teal
      case CustomerSegment.inactive:
        return const Color(0xFFEF4444); // Red/Coral
    }
  }

  Color get backgroundColor {
    switch (this) {
      case CustomerSegment.highSpending:
        return const Color(0xFFFEF3C7);
      case CustomerSegment.loyal:
        return const Color(0xFFD1FAE5);
      case CustomerSegment.regular:
        return const Color(0xFFDBEAFE);
      case CustomerSegment.newCustomer:
        return const Color(0xFFCCFBF1);
      case CustomerSegment.inactive:
        return const Color(0xFFFEE2E2);
    }
  }

  IconData get icon {
    switch (this) {
      case CustomerSegment.highSpending:
        return Icons.workspace_premium_rounded;
      case CustomerSegment.loyal:
        return Icons.star_rounded;
      case CustomerSegment.regular:
        return Icons.repeat_rounded;
      case CustomerSegment.newCustomer:
        return Icons.person_add_alt_1_rounded;
      case CustomerSegment.inactive:
        return Icons.schedule_rounded;
    }
  }
}

class LoyaltyProgramConfig {
  const LoyaltyProgramConfig({
    this.pointsPer100Spent = 1,
    this.pointValueInRupees = 1.0,
    this.minRedemptionPoints = 50,
    this.welcomeBonusPoints = 50,
    this.highSpendingThreshold = 5000,
    this.loyalVisitsThreshold = 3,
    this.inactiveDaysThreshold = 45,
  });

  final int pointsPer100Spent;
  final double pointValueInRupees;
  final int minRedemptionPoints;
  final int welcomeBonusPoints;
  final int highSpendingThreshold;
  final int loyalVisitsThreshold;
  final int inactiveDaysThreshold;

  factory LoyaltyProgramConfig.fromMap(Map<String, dynamic> map) {
    return LoyaltyProgramConfig(
      pointsPer100Spent: (map['points_per_100_spent'] as num?)?.toInt() ?? 1,
      pointValueInRupees: (map['point_value_rupees'] as num?)?.toDouble() ?? 1.0,
      minRedemptionPoints: (map['min_points_to_redeem'] as num?)?.toInt() ?? 50,
      welcomeBonusPoints: (map['welcome_bonus_points'] as num?)?.toInt() ?? 50,
      highSpendingThreshold: (map['high_spending_threshold'] as num?)?.toInt() ?? 5000,
      loyalVisitsThreshold: (map['loyal_visits_threshold'] as num?)?.toInt() ?? 3,
      inactiveDaysThreshold: (map['inactive_days_threshold'] as num?)?.toInt() ?? 45,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': 1,
        'points_per_100_spent': pointsPer100Spent,
        'point_value_rupees': pointValueInRupees,
        'min_points_to_redeem': minRedemptionPoints,
        'welcome_bonus_points': welcomeBonusPoints,
        'high_spending_threshold': highSpendingThreshold,
        'loyal_visits_threshold': loyalVisitsThreshold,
        'inactive_days_threshold': inactiveDaysThreshold,
      };

  LoyaltyProgramConfig copyWith({
    int? pointsPer100Spent,
    double? pointValueInRupees,
    int? minRedemptionPoints,
    int? welcomeBonusPoints,
    int? highSpendingThreshold,
    int? loyalVisitsThreshold,
    int? inactiveDaysThreshold,
  }) {
    return LoyaltyProgramConfig(
      pointsPer100Spent: pointsPer100Spent ?? this.pointsPer100Spent,
      pointValueInRupees: pointValueInRupees ?? this.pointValueInRupees,
      minRedemptionPoints: minRedemptionPoints ?? this.minRedemptionPoints,
      welcomeBonusPoints: welcomeBonusPoints ?? this.welcomeBonusPoints,
      highSpendingThreshold: highSpendingThreshold ?? this.highSpendingThreshold,
      loyalVisitsThreshold: loyalVisitsThreshold ?? this.loyalVisitsThreshold,
      inactiveDaysThreshold: inactiveDaysThreshold ?? this.inactiveDaysThreshold,
    );
  }
}

class CustomerLoyaltyProfile {
  CustomerLoyaltyProfile({
    required this.customer,
    required this.bills,
    this.points = 0,
    this.pointsRedeemed = 0,
    this.marketingConsent = true,
    this.config = const LoyaltyProgramConfig(),
  });

  final Customer customer;
  final List<Bill> bills;
  final int points;
  final int pointsRedeemed;
  final bool marketingConsent;
  final LoyaltyProgramConfig config;

  int get totalBills => bills.isNotEmpty ? bills.length : customer.visits;

  int get totalSpent {
    if (bills.isNotEmpty) {
      return bills.fold(0, (sum, b) => sum + b.total);
    }
    return customer.totalSpent;
  }

  int get averageOrderValue => totalBills > 0 ? (totalSpent / totalBills).round() : 0;

  DateTime? get lastPurchaseDate {
    if (bills.isNotEmpty) {
      final sorted = [...bills]..sort((a, b) => b.time.compareTo(a.time));
      return sorted.first.time;
    }
    return null;
  }

  int get daysSinceLastPurchase {
    final last = lastPurchaseDate;
    if (last == null) return -1;
    return DateTime.now().difference(last).inDays;
  }

  CustomerSegment get segment {
    if (totalSpent >= config.highSpendingThreshold) {
      return CustomerSegment.highSpending;
    }
    if (lastPurchaseDate != null && daysSinceLastPurchase >= config.inactiveDaysThreshold && totalBills > 0) {
      return CustomerSegment.inactive;
    }
    if (totalBills >= config.loyalVisitsThreshold) {
      return CustomerSegment.loyal;
    }
    if (totalBills >= 2) {
      return CustomerSegment.regular;
    }
    return CustomerSegment.newCustomer;
  }

  int get availablePoints => points - pointsRedeemed > 0 ? points - pointsRedeemed : 0;

  double get pointsWorthRupees => availablePoints * config.pointValueInRupees;

  // Frequently purchased categories and products
  Map<String, int> get categoryCounts {
    final map = <String, int>{};
    for (final bill in bills) {
      for (final item in bill.allItems) {
        if (item.productName.isNotEmpty) {
          map[item.productName] = (map[item.productName] ?? 0) + item.qty;
        }
      }
    }
    return map;
  }

  List<String> get topPurchasedItems {
    final counts = categoryCounts;
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => '${e.key} (${e.value}x)').toList();
  }

  List<String> get preferredSizes {
    final set = <String>{};
    if (customer.size.isNotEmpty && customer.size != 'Free') {
      set.add(customer.size);
    }
    for (final b in bills) {
      for (final it in b.allItems) {
        if (it.size.isNotEmpty && it.size != 'Free') set.add(it.size);
      }
    }
    return set.toList();
  }

  List<String> get preferredColors {
    final set = <String>{};
    if (customer.colors.isNotEmpty && customer.colors != 'Standard') {
      set.addAll(customer.colors.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    for (final b in bills) {
      for (final it in b.allItems) {
        if (it.color.isNotEmpty && it.color != 'Standard') set.add(it.color);
      }
    }
    return set.toList();
  }
}

class Offer {
  const Offer({
    required this.id,
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    required this.minSpend,
    required this.applicableCategory,
    required this.targetSegment,
    required this.validFrom,
    required this.validUntil,
    required this.messageTemplate,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String title;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final int minSpend;
  final String applicableCategory;
  final String targetSegment; // 'All', 'High-Spending VIP', 'Loyal Customer', etc.
  final DateTime validFrom;
  final DateTime validUntil;
  final String messageTemplate;
  final bool isActive;

  bool get isCurrentlyValid {
    if (!isActive) return false;
    final now = DateTime.now();
    return now.isAfter(validFrom.subtract(const Duration(seconds: 1))) &&
        now.isBefore(validUntil.add(const Duration(days: 1)));
  }

  String get discountBadge {
    if (discountType == 'percentage') {
      return '${discountValue.toInt()}% OFF';
    }
    return '₹${discountValue.toInt()} OFF';
  }

  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      id: map['id'] as String,
      code: map['code'] as String,
      title: map['title'] as String,
      discountType: (map['discount_type'] as String?) ?? 'percentage',
      discountValue: (map['discount_value'] as num?)?.toDouble() ?? 0.0,
      minSpend: (map['min_spend'] as num?)?.toInt() ?? 0,
      applicableCategory: (map['applicable_category'] as String?) ?? 'All Categories',
      targetSegment: (map['target_segment'] as String?) ?? 'All',
      validFrom: DateTime.tryParse((map['valid_from'] as String?) ?? '') ?? DateTime.now(),
      validUntil: DateTime.tryParse((map['valid_until'] as String?) ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      messageTemplate: (map['message_template'] as String?) ?? '',
      isActive: ((map['is_active'] as num?)?.toInt() ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'title': title,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_spend': minSpend,
        'applicable_category': applicableCategory,
        'target_segment': targetSegment,
        'valid_from': validFrom.toIso8601String(),
        'valid_until': validUntil.toIso8601String(),
        'message_template': messageTemplate,
        'is_active': isActive ? 1 : 0,
      };

  String generateMessage({
    required String customerName,
    required String shopName,
    String? preferredSize,
    String? preferredColor,
  }) {
    if (messageTemplate.isNotEmpty) {
      var msg = messageTemplate;
      msg = msg.replaceAll('{customer_name}', customerName);
      msg = msg.replaceAll('{shop_name}', shopName);
      msg = msg.replaceAll('{offer_code}', code);
      msg = msg.replaceAll('{discount}', discountBadge);
      msg = msg.replaceAll('{min_spend}', '₹$minSpend');
      msg = msg.replaceAll('{valid_till}', '${validUntil.day}/${validUntil.month}/${validUntil.year}');
      msg = msg.replaceAll('{category}', applicableCategory);
      return msg;
    }

    final dateStr = '${validUntil.day}/${validUntil.month}/${validUntil.year}';
    final buffer = StringBuffer();
    buffer.writeln('✨ *SPECIAL OFFER FROM ${shopName.toUpperCase()}!* ✨');
    buffer.writeln('Hello $customerName! 👋');
    buffer.writeln('');
    buffer.writeln('We have an exclusive offer crafted just for you:');
    buffer.writeln('🏷️ *Offer:* $title');
    buffer.writeln('🎉 *Get $discountBadge* on your purchase!');
    if (minSpend > 0) {
      buffer.writeln('📌 *Min Purchase:* ₹$minSpend');
    }
    if (applicableCategory != 'All Categories') {
      buffer.writeln('👠 *Category:* $applicableCategory');
    }
    if (preferredSize != null && preferredSize.isNotEmpty) {
      buffer.writeln('👟 Fresh pairs in your size ($preferredSize) have just arrived!');
    }
    buffer.writeln('🔑 *Use Code:* *$code*');
    buffer.writeln('⏳ *Valid Until:* $dateStr');
    buffer.writeln('');
    buffer.writeln('Visit $shopName today or reply to reserve your favorite footwear! 🙏');
    return buffer.toString();
  }
}

class OfferTracking {
  const OfferTracking({
    required this.id,
    required this.offerId,
    required this.offerCode,
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.sentAt,
    this.isRedeemed = false,
    this.redeemedAt,
    this.billId,
    this.salesGenerated = 0,
  });

  final String id;
  final String offerId;
  final String offerCode;
  final String customerId;
  final String customerName;
  final String mobile;
  final DateTime sentAt;
  final bool isRedeemed;
  final DateTime? redeemedAt;
  final String? billId;
  final int salesGenerated;

  factory OfferTracking.fromMap(Map<String, dynamic> map) {
    return OfferTracking(
      id: map['id'] as String,
      offerId: map['offer_id'] as String,
      offerCode: map['offer_code'] as String,
      customerId: map['customer_id'] as String,
      customerName: map['customer_name'] as String,
      mobile: map['mobile'] as String,
      sentAt: DateTime.tryParse((map['sent_at'] as String?) ?? '') ?? DateTime.now(),
      isRedeemed: ((map['is_redeemed'] as num?)?.toInt() ?? 0) == 1,
      redeemedAt: map['redeemed_at'] != null ? DateTime.tryParse(map['redeemed_at'] as String) : null,
      billId: map['bill_id'] as String?,
      salesGenerated: (map['sales_generated'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'offer_id': offerId,
        'offer_code': offerCode,
        'customer_id': customerId,
        'customer_name': customerName,
        'mobile': mobile,
        'sent_at': sentAt.toIso8601String(),
        'is_redeemed': isRedeemed ? 1 : 0,
        'redeemed_at': redeemedAt?.toIso8601String(),
        'bill_id': billId,
        'sales_generated': salesGenerated,
      };
}
