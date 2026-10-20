import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/bill.dart';
import '../models/customer.dart';
import '../models/product.dart';

class ExcelExportService {
  Future<String> exportShopData({
    required List<Customer> customers,
    required List<Product> products,
    required List<Bill> bills,
    String companyName = 'Footwear Store',
  }) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Customers');
    _writeCustomers(excel['Customers'], customers);
    _writeProducts(excel['Products'], products);
    _writeBills(excel['Bills'], bills);

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Unable to generate Excel file');

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanName = companyName.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    final file = File(p.join(directory.path, '${cleanName}_export_$timestamp.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  void _writeCustomers(Sheet sheet, List<Customer> customers) {
    sheet.appendRow(_row(['Customer ID', 'Name', 'Mobile', 'Size', 'Color Preference', 'Last Purchase', 'Total Spent', 'Visits', 'Note']));
    for (final customer in customers) {
      sheet.appendRow(_row([
        customer.id,
        customer.name,
        customer.mobile,
        customer.size,
        customer.colors,
        customer.lastItem,
        customer.totalSpent.toString(),
        customer.visits.toString(),
        customer.note,
      ]));
    }
  }

  void _writeProducts(Sheet sheet, List<Product> products) {
    sheet.appendRow(_row(['Product ID', 'Name', 'Category', 'Stock', 'Price', 'Sizes', 'Colors']));
    for (final product in products) {
      sheet.appendRow(_row([
        product.id,
        product.name,
        product.category,
        product.stock.toString(),
        product.price.toString(),
        product.sizes.join(', '),
        product.colors.join(', '),
      ]));
    }
  }

  void _writeBills(Sheet sheet, List<Bill> bills) {
    sheet.appendRow(_row([
      'Bill ID',
      'Customer',
      'Mobile',
      'Items Detail',
      'Total Qty',
      'Subtotal',
      'Discount',
      'Total Amount',
      'Payment Mode',
      'Note',
      'Date',
    ]));
    for (final bill in bills) {
      final itemsSummary = bill.allItems
          .map((it) => '${it.productName} (${it.size}/${it.color}) x${it.qty} @₹${it.price}')
          .join('; ');
      sheet.appendRow(_row([
        bill.id,
        bill.customer,
        bill.mobile,
        itemsSummary,
        bill.qty.toString(),
        bill.price.toString(),
        bill.discount.toString(),
        bill.total.toString(),
        bill.payMode,
        bill.note,
        bill.time.toIso8601String(),
      ]));
    }
  }

  Future<String> exportMonthlyBills({
    required List<Bill> bills,
    required DateTime month,
    String companyName = 'Footwear Store',
  }) async {
    final excel = Excel.createExcel();
    final monthName = _monthNames[month.month - 1];
    final sheetName = '$monthName ${month.year} Sales';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    sheet.appendRow(_row([
      'Bill ID',
      'Date & Time',
      'Customer',
      'Mobile',
      'Items Detail',
      'Quantity',
      'Subtotal',
      'Discount',
      'Net Total (₹)',
      'Payment Mode',
      'Notes',
    ]));

    int totalRevenue = 0;
    int totalPairs = 0;

    for (final bill in bills) {
      totalRevenue += bill.total;
      totalPairs += bill.qty;
      final itemsSummary = bill.allItems
          .map((it) => '${it.productName} (${it.size}/${it.color}) x${it.qty} @₹${it.price}')
          .join('; ');
      sheet.appendRow(_row([
        bill.id,
        '${bill.time.day} $monthName ${bill.time.year}, ${bill.time.hour.toString().padLeft(2, '0')}:${bill.time.minute.toString().padLeft(2, '0')}',
        bill.customer,
        bill.mobile,
        itemsSummary,
        bill.qty.toString(),
        bill.price.toString(),
        bill.discount.toString(),
        bill.total.toString(),
        bill.payMode,
        bill.note,
      ]));
    }

    // Append Summary Row
    sheet.appendRow(_row([
      'TOTAL SUMMARY',
      '',
      '${bills.length} Bills',
      '',
      '',
      '$totalPairs Pairs',
      '',
      '',
      '₹$totalRevenue',
      '',
      '',
    ]));

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Unable to generate Excel file');

    final directory = await getApplicationDocumentsDirectory();
    final cleanName = companyName.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    final file = File(p.join(directory.path, '${cleanName}_sales_${month.year}_${month.month.toString().padLeft(2, '0')}.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  List<TextCellValue> _row(List<String> values) => values.map(TextCellValue.new).toList();
}
