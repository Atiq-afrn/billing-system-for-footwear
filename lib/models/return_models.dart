import 'dart:convert';
import 'package:flutter/material.dart';

enum ReturnType {
  returnOnly,
  exchange;

  String get displayName {
    switch (this) {
      case ReturnType.returnOnly:
        return 'Return & Refund';
      case ReturnType.exchange:
        return 'Product Exchange';
    }
  }

  IconData get icon {
    switch (this) {
      case ReturnType.returnOnly:
        return Icons.keyboard_return_rounded;
      case ReturnType.exchange:
        return Icons.swap_horiz_rounded;
    }
  }
}

enum ReturnStatus {
  pendingApproval,
  approved,
  rejected,
  completed;

  String get displayName {
    switch (this) {
      case ReturnStatus.pendingApproval:
        return 'Pending Approval';
      case ReturnStatus.approved:
        return 'Approved';
      case ReturnStatus.rejected:
        return 'Rejected';
      case ReturnStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case ReturnStatus.pendingApproval:
        return const Color(0xFFD97706); // Amber
      case ReturnStatus.approved:
        return const Color(0xFF2563EB); // Royal Blue
      case ReturnStatus.rejected:
        return const Color(0xFFEF4444); // Red
      case ReturnStatus.completed:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ReturnStatus.pendingApproval:
        return const Color(0xFFFEF3C7);
      case ReturnStatus.approved:
        return const Color(0xFFDBEAFE);
      case ReturnStatus.rejected:
        return const Color(0xFFFEE2E2);
      case ReturnStatus.completed:
        return const Color(0xFFD1FAE5);
    }
  }

  IconData get icon {
    switch (this) {
      case ReturnStatus.pendingApproval:
        return Icons.hourglass_top_rounded;
      case ReturnStatus.approved:
        return Icons.thumb_up_alt_rounded;
      case ReturnStatus.rejected:
        return Icons.cancel_outlined;
      case ReturnStatus.completed:
        return Icons.check_circle_rounded;
    }
  }
}

enum ProductCondition {
  sellable,
  damaged,
  used,
  defective,
  pendingInspection;

  String get displayName {
    switch (this) {
      case ProductCondition.sellable:
        return 'Sellable (Restock to Saleable)';
      case ProductCondition.damaged:
        return 'Damaged (Quarantine Stock)';
      case ProductCondition.used:
        return 'Used / Worn (Non-saleable)';
      case ProductCondition.defective:
        return 'Manufacturing Defect (Quarantine)';
      case ProductCondition.pendingInspection:
        return 'Pending Inspection';
    }
  }

  String get shortName {
    switch (this) {
      case ProductCondition.sellable:
        return 'Sellable';
      case ProductCondition.damaged:
        return 'Damaged';
      case ProductCondition.used:
        return 'Used';
      case ProductCondition.defective:
        return 'Defective';
      case ProductCondition.pendingInspection:
        return 'Pending Check';
    }
  }

  bool get canRestock => this == ProductCondition.sellable;

  Color get color {
    switch (this) {
      case ProductCondition.sellable:
        return const Color(0xFF10B981);
      case ProductCondition.damaged:
        return const Color(0xFFEF4444);
      case ProductCondition.used:
        return const Color(0xFFF97316);
      case ProductCondition.defective:
        return const Color(0xFFDC2626);
      case ProductCondition.pendingInspection:
        return const Color(0xFF8B5CF6);
    }
  }
}

class ReturnItem {
  const ReturnItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.color,
    required this.qty,
    required this.unitPrice,
    required this.reason,
    required this.condition,
  });

  final String productId;
  final String productName;
  final String size;
  final String color;
  final int qty;
  final int unitPrice;
  final String reason;
  final ProductCondition condition;

  int get total => qty * unitPrice;

  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      productId: (map['product_id'] ?? '') as String,
      productName: (map['product_name'] ?? '') as String,
      size: (map['size'] ?? '') as String,
      color: (map['color'] ?? '') as String,
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unit_price'] as num?)?.toInt() ?? 0,
      reason: (map['reason'] ?? 'Customer Preference') as String,
      condition: ProductCondition.values.firstWhere(
        (c) => c.name == (map['condition'] as String?),
        orElse: () => ProductCondition.sellable,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'product_name': productName,
        'size': size,
        'color': color,
        'qty': qty,
        'unit_price': unitPrice,
        'reason': reason,
        'condition': condition.name,
      };
}

class ExchangeItem {
  const ExchangeItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.color,
    required this.qty,
    required this.unitPrice,
  });

  final String productId;
  final String productName;
  final String size;
  final String color;
  final int qty;
  final int unitPrice;

  int get total => qty * unitPrice;

  factory ExchangeItem.fromMap(Map<String, dynamic> map) {
    return ExchangeItem(
      productId: (map['product_id'] ?? '') as String,
      productName: (map['product_name'] ?? '') as String,
      size: (map['size'] ?? '') as String,
      color: (map['color'] ?? '') as String,
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unit_price'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'product_name': productName,
        'size': size,
        'color': color,
        'qty': qty,
        'unit_price': unitPrice,
      };
}

class ReturnRecord {
  const ReturnRecord({
    required this.id,
    required this.billId,
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.type,
    required this.status,
    required this.returnReason,
    required this.productCondition,
    required this.returnedTotalAmount,
    required this.exchangeTotalAmount,
    required this.netAmount,
    required this.refundMethod,
    required this.refundStatus,
    this.transactionRef = '',
    required this.approvedBy,
    this.rejectionReason,
    required this.createdAt,
    this.processedAt,
    this.notes = '',
    required this.items,
    this.exchangeItems = const [],
  });

  final String id;
  final String billId;
  final String customerId;
  final String customerName;
  final String mobile;
  final ReturnType type;
  final ReturnStatus status;
  final String returnReason;
  final ProductCondition productCondition;
  final int returnedTotalAmount;
  final int exchangeTotalAmount;
  /// netAmount:
  /// If positive: Customer needs to pay additional amount (balance due).
  /// If negative: Refund amount due to customer.
  /// If zero: Even exchange.
  final int netAmount;
  final String refundMethod; // Cash, UPI, Store Credit, Card, N/A
  final String refundStatus; // Completed, Pending, N/A
  final String transactionRef;
  final String approvedBy;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String notes;
  final List<ReturnItem> items;
  final List<ExchangeItem> exchangeItems;

  bool get isExchange => type == ReturnType.exchange;
  bool get isCustomerRefund => netAmount < 0;
  bool get isCustomerPayable => netAmount > 0;
  int get customerRefundAmount => netAmount < 0 ? netAmount.abs() : 0;
  int get customerPayableAmount => netAmount > 0 ? netAmount : 0;

  int get totalItemsReturned => items.fold(0, (sum, it) => sum + it.qty);
  int get totalItemsExchanged => exchangeItems.fold(0, (sum, it) => sum + it.qty);

  factory ReturnRecord.fromMap(Map<String, dynamic> map) {
    List<ReturnItem> parsedItems = [];
    final itemsJson = map['items_json'] as String?;
    if (itemsJson != null && itemsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(itemsJson);
        if (decoded is List) {
          parsedItems = decoded.map((e) => ReturnItem.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      } catch (_) {}
    }

    List<ExchangeItem> parsedExchangeItems = [];
    final exchJson = map['exchange_items_json'] as String?;
    if (exchJson != null && exchJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(exchJson);
        if (decoded is List) {
          parsedExchangeItems =
              decoded.map((e) => ExchangeItem.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      } catch (_) {}
    }

    final typeStr = (map['type'] as String?) ?? 'return';
    final statusStr = (map['status'] as String?) ?? 'pending_approval';
    final conditionStr = (map['product_condition'] as String?) ?? 'sellable';

    return ReturnRecord(
      id: map['id'] as String,
      billId: (map['bill_id'] ?? '') as String,
      customerId: (map['customer_id'] ?? '') as String,
      customerName: (map['customer_name'] ?? '') as String,
      mobile: (map['mobile'] ?? '') as String,
      type: typeStr == 'exchange' ? ReturnType.exchange : ReturnType.returnOnly,
      status: ReturnStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => ReturnStatus.pendingApproval,
      ),
      returnReason: (map['return_reason'] ?? 'Wrong Size') as String,
      productCondition: ProductCondition.values.firstWhere(
        (c) => c.name == conditionStr,
        orElse: () => ProductCondition.sellable,
      ),
      returnedTotalAmount: (map['returned_total_amount'] as num?)?.toInt() ?? 0,
      exchangeTotalAmount: (map['exchange_total_amount'] as num?)?.toInt() ?? 0,
      netAmount: (map['net_amount'] as num?)?.toInt() ?? 0,
      refundMethod: (map['refund_method'] ?? 'Cash') as String,
      refundStatus: (map['refund_status'] ?? 'Completed') as String,
      transactionRef: (map['transaction_ref'] as String?) ?? '',
      approvedBy: (map['approved_by'] ?? 'Store Owner') as String,
      rejectionReason: map['rejection_reason'] as String?,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
      processedAt: map['processed_at'] != null ? DateTime.tryParse(map['processed_at'] as String) : null,
      notes: (map['notes'] as String?) ?? '',
      items: parsedItems,
      exchangeItems: parsedExchangeItems,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'bill_id': billId,
        'customer_id': customerId,
        'customer_name': customerName,
        'mobile': mobile,
        'type': type == ReturnType.exchange ? 'exchange' : 'return',
        'status': status.name,
        'return_reason': returnReason,
        'product_condition': productCondition.name,
        'returned_total_amount': returnedTotalAmount,
        'exchange_total_amount': exchangeTotalAmount,
        'net_amount': netAmount,
        'refund_method': refundMethod,
        'refund_status': refundStatus,
        'transaction_ref': transactionRef,
        'approved_by': approvedBy,
        'rejection_reason': rejectionReason,
        'created_at': createdAt.toIso8601String(),
        'processed_at': processedAt?.toIso8601String(),
        'notes': notes,
        'items_json': jsonEncode(items.map((e) => e.toMap()).toList()),
        'exchange_items_json': jsonEncode(exchangeItems.map((e) => e.toMap()).toList()),
      };

  ReturnRecord copyWith({
    ReturnStatus? status,
    String? approvedBy,
    String? rejectionReason,
    DateTime? processedAt,
    String? refundStatus,
    String? transactionRef,
  }) {
    return ReturnRecord(
      id: id,
      billId: billId,
      customerId: customerId,
      customerName: customerName,
      mobile: mobile,
      type: type,
      status: status ?? this.status,
      returnReason: returnReason,
      productCondition: productCondition,
      returnedTotalAmount: returnedTotalAmount,
      exchangeTotalAmount: exchangeTotalAmount,
      netAmount: netAmount,
      refundMethod: refundMethod,
      refundStatus: refundStatus ?? this.refundStatus,
      transactionRef: transactionRef ?? this.transactionRef,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
      notes: notes,
      items: items,
      exchangeItems: exchangeItems,
    );
  }
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.movementType,
    required this.qtyChange,
    required this.referenceId,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final String productId;
  final String productName;
  /// movementType:
  /// - 'sale'
  /// - 'return_sellable' (restocked to saleable inventory)
  /// - 'return_damaged' (quarantined)
  /// - 'exchange_inflow'
  /// - 'exchange_outflow' (replacement product given out)
  /// - 'adjustment'
  final String movementType;
  final int qtyChange; // positive or negative
  final String referenceId; // bill ID or return ID
  final DateTime createdAt;
  final String note;

  String get typeLabel {
    switch (movementType) {
      case 'sale':
        return 'Sale Outflow';
      case 'return_sellable':
        return 'Return Restocked';
      case 'return_damaged':
        return 'Damaged Quarantine';
      case 'exchange_inflow':
        return 'Exchange Inflow';
      case 'exchange_outflow':
        return 'Exchange Outflow';
      case 'adjustment':
        return 'Stock Adjustment';
      default:
        return movementType;
    }
  }

  Color get typeColor {
    if (qtyChange > 0) return const Color(0xFF10B981);
    if (qtyChange < 0) return const Color(0xFFEF4444);
    return const Color(0xFF64748B);
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as String,
      productId: (map['product_id'] ?? '') as String,
      productName: (map['product_name'] ?? '') as String,
      movementType: (map['movement_type'] ?? 'adjustment') as String,
      qtyChange: (map['qty_change'] as num?)?.toInt() ?? 0,
      referenceId: (map['reference_id'] ?? '') as String,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
      note: (map['note'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'movement_type': movementType,
        'qty_change': qtyChange,
        'reference_id': referenceId,
        'created_at': createdAt.toIso8601String(),
        'note': note,
      };
}
