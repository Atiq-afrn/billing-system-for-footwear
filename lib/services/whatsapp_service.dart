import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/bill.dart';
import '../models/customer.dart';
import '../models/loyalty_models.dart';
import '../models/return_models.dart';

class WhatsAppService {
  String sanitizeMobile(String mobile) {
    final digitsOnly = mobile.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 10) {
      return '91$digitsOnly';
    }
    return digitsOnly;
  }

  Future<bool> sendBillWhatsApp(Bill bill, {String companyName = 'Footwear Store'}) async {
    final cleanMobile = sanitizeMobile(bill.mobile);
    final dateStr =
        '${bill.time.day.toString().padLeft(2, '0')}-${bill.time.month.toString().padLeft(2, '0')}-${bill.time.year}';
    final items = bill.allItems;

    final buffer = StringBuffer();
    buffer.writeln('🧾 *${companyName.toUpperCase()} - TAX INVOICE*');
    buffer.writeln('--------------------------------');
    buffer.writeln('*Bill ID:* ${bill.id}');
    buffer.writeln('*Date:* $dateStr');
    buffer.writeln('*Customer:* ${bill.customer}');
    buffer.writeln('--------------------------------');
    buffer.writeln('*ITEMS PURCHASED (${items.length}):*');

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      buffer.writeln('${i + 1}. *${item.productName}*');
      final sizeCol = [
        if (item.size.isNotEmpty) 'Size: ${item.size}',
        if (item.color.isNotEmpty) 'Color: ${item.color}',
      ].join(' | ');
      if (sizeCol.isNotEmpty) {
        buffer.writeln('   $sizeCol');
      }
      buffer.writeln('   ${item.qty} x Rs ${item.price} = *Rs ${item.total}*');
    }

    buffer.writeln('--------------------------------');
    final subtotal = items.fold(0, (sum, it) => sum + it.total);
    buffer.writeln('*Subtotal:* Rs $subtotal');
    if (bill.discount > 0) {
      buffer.writeln('*Discount:* Rs ${bill.discount}');
    }
    buffer.writeln('*TOTAL AMOUNT:* *Rs ${bill.total}*');
    buffer.writeln('*Payment Mode:* ${bill.payMode}');
    if (bill.note.isNotEmpty) {
      buffer.writeln('*Note:* ${bill.note}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Thank you for shopping with $companyName! 🙏');

    final encodedText = Uri.encodeComponent(buffer.toString().trim());
    final url = Uri.parse('https://wa.me/$cleanMobile?text=$encodedText');

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      return await launchUrl(url);
    }
  }

  Future<bool> sendCustomerOffer(Customer customer, {String companyName = 'Footwear Store'}) async {
    final cleanMobile = sanitizeMobile(customer.mobile);
    final text = '''
Hi ${customer.name}! 👋

New stock has just arrived at *$companyName*! 👟👞
We have special collections available in Size ${customer.size} (${customer.colors}).

Visit our store or reply to this message to reserve your pair!
''';

    final encodedText = Uri.encodeComponent(text.trim());
    final url = Uri.parse('https://wa.me/$cleanMobile?text=$encodedText');

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      return await launchUrl(url);
    }
  }

  Future<bool> sendPersonalizedOffer({
    required CustomerLoyaltyProfile profile,
    required Offer offer,
    String companyName = 'Footwear Store',
  }) async {
    final cleanMobile = sanitizeMobile(profile.customer.mobile);
    final message = offer.generateMessage(
      customerName: profile.customer.name.trim().isNotEmpty ? profile.customer.name.trim() : 'Valued Customer',
      shopName: companyName,
      preferredSize: profile.preferredSizes.isNotEmpty ? profile.preferredSizes.first : null,
      preferredColor: profile.preferredColors.isNotEmpty ? profile.preferredColors.first : null,
    );

    final encodedText = Uri.encodeComponent(message.trim());
    final url = Uri.parse('https://wa.me/$cleanMobile?text=$encodedText');

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      return await launchUrl(url);
    }
  }

  Future<bool> sendReturnExchangeReceiptWhatsApp({
    required ReturnRecord record,
    String companyName = 'Footwear Store',
  }) async {
    final cleanMobile = sanitizeMobile(record.mobile);
    final dateStr =
        '${record.createdAt.day.toString().padLeft(2, '0')}-${record.createdAt.month.toString().padLeft(2, '0')}-${record.createdAt.year}';

    final buffer = StringBuffer();
    buffer.writeln('🔄 *${companyName.toUpperCase()} - RETURN & EXCHANGE RECEIPT*');
    buffer.writeln('--------------------------------');
    buffer.writeln('*Transaction ID:* ${record.id}');
    buffer.writeln('*Original Bill ID:* ${record.billId}');
    buffer.writeln('*Date:* $dateStr');
    buffer.writeln('*Customer:* ${record.customerName}');
    buffer.writeln('*Type:* ${record.type.displayName}');
    buffer.writeln('*Status:* ${record.status.displayName.toUpperCase()}');
    buffer.writeln('--------------------------------');

    buffer.writeln('*RETURNED ITEMS (${record.items.length}):*');
    for (var i = 0; i < record.items.length; i++) {
      final it = record.items[i];
      buffer.writeln('${i + 1}. *${it.productName}*');
      final details = [
        if (it.size.isNotEmpty) 'Size: ${it.size}',
        if (it.color.isNotEmpty) 'Color: ${it.color}',
      ].join(' | ');
      if (details.isNotEmpty) buffer.writeln('   $details');
      buffer.writeln('   Qty: ${it.qty} x Rs ${it.unitPrice} = *Rs ${it.total}*');
      buffer.writeln('   Reason: ${it.reason} | Condition: ${it.condition.shortName}');
    }
    buffer.writeln('*Total Returned Value:* Rs ${record.returnedTotalAmount}');

    if (record.isExchange && record.exchangeItems.isNotEmpty) {
      buffer.writeln('--------------------------------');
      buffer.writeln('*EXCHANGE REPLACEMENTS (${record.exchangeItems.length}):*');
      for (var i = 0; i < record.exchangeItems.length; i++) {
        final exch = record.exchangeItems[i];
        buffer.writeln('${i + 1}. *${exch.productName}*');
        final details = [
          if (exch.size.isNotEmpty) 'Size: ${exch.size}',
          if (exch.color.isNotEmpty) 'Color: ${exch.color}',
        ].join(' | ');
        if (details.isNotEmpty) buffer.writeln('   $details');
        buffer.writeln('   Qty: ${exch.qty} x Rs ${exch.unitPrice} = *Rs ${exch.total}*');
      }
      buffer.writeln('*Total Exchange Value:* Rs ${record.exchangeTotalAmount}');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('*FINANCIAL SETTLEMENT:*');
    if (record.isCustomerRefund) {
      buffer.writeln('💵 *Refund Paid:* *Rs ${record.customerRefundAmount}*');
      buffer.writeln('💳 *Refund Method:* ${record.refundMethod}');
      if (record.transactionRef.isNotEmpty) {
        buffer.writeln('🔖 *Ref / UTR:* ${record.transactionRef}');
      }
    } else if (record.isCustomerPayable) {
      buffer.writeln('💰 *Balance Paid by Customer:* *Rs ${record.customerPayableAmount}*');
      buffer.writeln('💳 *Payment Method:* ${record.refundMethod}');
    } else {
      buffer.writeln('⚖️ *Even Exchange:* No balance due / refund');
    }

    buffer.writeln('👤 *Authorized By:* ${record.approvedBy}');
    if (record.notes.isNotEmpty) {
      buffer.writeln('*Notes:* ${record.notes}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Thank you for shopping with $companyName! 🙏');

    final encodedText = Uri.encodeComponent(buffer.toString().trim());
    final url = Uri.parse('https://wa.me/$cleanMobile?text=$encodedText');

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      return await launchUrl(url);
    }
  }

  Future<void> sharePdfFile(Uint8List pdfBytes, String fileName, {String companyName = 'Footwear Store'}) async {
    final xFile = XFile.fromData(
      pdfBytes,
      name: fileName,
      mimeType: 'application/pdf',
    );
    await Share.shareXFiles([xFile], text: 'Invoice $fileName from $companyName');
  }

  Future<void> shareExcelFile(String filePath, {String companyName = 'Footwear Store'}) async {
    final xFile = XFile(filePath);
    await Share.shareXFiles([xFile], text: '$companyName Data Export');
  }
}
