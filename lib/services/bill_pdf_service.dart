// import 'dart:typed_data';
//
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
//
// import '../models/bill.dart';
// import '../widgets/shop_widgets.dart';
//
// class BillPdfService {
//   Future<Uint8List> buildBillPdf(Bill bill, {String companyName = 'Ayesha Footwear'}) async {
//     final pdf = pw.Document();
//     final items = bill.allItems;
//     final subtotal = items.fold(0, (sum, it) => sum + it.total);
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(32),
//         build: (context) => pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Row(
//               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//               children: [
//                 pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text(companyName.toUpperCase(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
//                     pw.SizedBox(height: 4),
//                     pw.Text('Retail & Commercial Sales Receipt', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
//                     pw.Text('Tax Invoice / Customer Receipt', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
//                   ],
//                 ),
//                 pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.end,
//                   children: [
//                     pw.Text(bill.id, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
//                     pw.Text(_date(bill.time), style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
//                   ],
//                 ),
//               ],
//             ),
//             pw.Divider(thickness: 1.5, color: PdfColors.grey400),
//             pw.SizedBox(height: 12),
//             _sectionTitle('Customer Details'),
//             _line('Name', bill.customer),
//             _line('Mobile / WhatsApp', bill.mobile),
//             if (bill.note.isNotEmpty) _line('Notes', bill.note),
//             pw.SizedBox(height: 18),
//             _sectionTitle('Purchased Items (${items.length})'),
//             pw.Table(
//               border: pw.TableBorder.all(color: PdfColors.grey300),
//               columnWidths: const {
//                 0: pw.FlexColumnWidth(0.5),
//                 1: pw.FlexColumnWidth(3),
//                 2: pw.FlexColumnWidth(1),
//                 3: pw.FlexColumnWidth(1.2),
//                 4: pw.FlexColumnWidth(0.8),
//                 5: pw.FlexColumnWidth(1.3),
//                 6: pw.FlexColumnWidth(1.4),
//               },
//               children: [
//                 pw.TableRow(
//                   decoration: const pw.BoxDecoration(color: PdfColors.grey200),
//                   children: ['#', 'Product', 'Size', 'Color', 'Qty', 'Rate', 'Amount'].map((text) => _cell(text, bold: true)).toList(),
//                 ),
//                 ...items.asMap().entries.map((entry) {
//                   final idx = entry.key + 1;
//                   final it = entry.value;
//                   return pw.TableRow(
//                     children: [
//                       _cell('$idx'),
//                       _cell(it.productName),
//                       _cell(it.size.isEmpty ? '-' : it.size),
//                       _cell(it.color.isEmpty ? '-' : it.color),
//                       _cell('${it.qty}'),
//                       _cell(money(it.price)),
//                       _cell(money(it.total)),
//                     ],
//                   );
//                 }),
//               ],
//             ),
//             pw.SizedBox(height: 18),
//             pw.Align(
//               alignment: pw.Alignment.centerRight,
//               child: pw.Container(
//                 width: 240,
//                 padding: const pw.EdgeInsets.all(12),
//                 decoration: pw.BoxDecoration(
//                   border: pw.Border.all(color: PdfColors.grey300),
//                   borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
//                 ),
//                 child: pw.Column(
//                   children: [
//                     _totalLine('Subtotal', money(subtotal)),
//                     if (bill.discount > 0) _totalLine('Discount', '- ${money(bill.discount)}'),
//                     pw.Divider(),
//                     _totalLine('Grand Total', money(bill.total), bold: true),
//                     _totalLine('Payment Mode', bill.payMode),
//                   ],
//                 ),
//               ),
//             ),
//             pw.Spacer(),
//             pw.Divider(color: PdfColors.grey300),
//             pw.Center(child: pw.Text('Thank you for shopping with $companyName! Visit Again.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.grey800))),
//           ],
//         ),
//       ),
//     );
//
//     return pdf.save();
//   }
//
//   pw.Widget _sectionTitle(String title) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)));
//   pw.Widget _line(String label, String value) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Row(children: [pw.SizedBox(width: 130, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))), pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)))]));
//   pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)));
//   pw.Widget _totalLine(String label, String value, {bool bold = false}) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(label, style: pw.TextStyle(fontSize: bold ? 12 : 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)), pw.Text(value, style: pw.TextStyle(fontSize: bold ? 12 : 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal))]));
//   String _date(DateTime time) => '${time.day.toString().padLeft(2, '0')}-${time.month.toString().padLeft(2, '0')}-${time.year}';
// }


import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/bill.dart';
import '../widgets/shop_widgets.dart';

class BillPdfService {
// Professional, minimal invoice colors.
static const PdfColor _navy = PdfColor.fromInt(0xFF17365D);
static const PdfColor _orange = PdfColor.fromInt(0xFFD9822B);
static const PdfColor _text = PdfColor.fromInt(0xFF263445);
static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
static const PdfColor _border = PdfColor.fromInt(0xFFE2E7ED);
static const PdfColor _lightBg = PdfColor.fromInt(0xFFF5F7FA);
static const PdfColor _white = PdfColors.white;

Future<Uint8List> buildBillPdf(
Bill bill, {
String companyName = 'Ayesha Footwear',
String? address,
String? mobile,
String? upiId,
}) async {
final pdf = pw.Document();

final items = bill.allItems;
final subtotal = items.fold<num>(
0,
(sum, item) => sum + item.total,
);

pdf.addPage(
pw.Page(
pageFormat: PdfPageFormat.a4,
margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 26),
theme: pw.ThemeData.withFont(
base: pw.Font.helvetica(),
bold: pw.Font.helveticaBold(),
),
build: (context) {
return pw.Column(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [
// Header
_buildHeader(
companyName,
bill,
address: address,
mobile: mobile,
upiId: upiId,
),

pw.SizedBox(height: 14),

// Customer information
_sectionHeading('CUSTOMER DETAILS'),

pw.SizedBox(height: 7),

_buildCustomerDetails(bill),

pw.SizedBox(height: 16),

// Purchased products
pw.Row(
mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
crossAxisAlignment: pw.CrossAxisAlignment.center,
children: [
pw.Text(
'Purchased Items',
style: pw.TextStyle(
fontSize: 12,
fontWeight: pw.FontWeight.bold,
color: _navy,
),
),
pw.Text(
'${items.length} ${items.length == 1 ? 'item' : 'items'}',
style: const pw.TextStyle(
fontSize: 9,
color: _muted,
),
),
],
),

pw.SizedBox(height: 7),

_buildItemsTable(items),

pw.SizedBox(height: 14),

// Bill summary
pw.Row(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [
pw.Expanded(
child: pw.Padding(
padding: const pw.EdgeInsets.only(top: 4),
child: pw.Column(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [
pw.Text(
'PAYMENT METHOD',
style: pw.TextStyle(
fontSize: 8,
fontWeight: pw.FontWeight.bold,
color: _muted,
),
),
pw.SizedBox(height: 5),
pw.Container(
padding: const pw.EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: pw.BoxDecoration(
color: _lightBg,
borderRadius:
const pw.BorderRadius.all(
pw.Radius.circular(4),
),
),
child: pw.Text(
bill.payMode,
style: pw.TextStyle(
fontSize: 9,
fontWeight: pw.FontWeight.bold,
color: _navy,
),
),
),
if (bill.payMode.toUpperCase() == 'UPI' && upiId != null && upiId.trim().isNotEmpty) ...[
pw.SizedBox(height: 4),
pw.Text(
'UPI: ${upiId.trim()}',
style: const pw.TextStyle(
fontSize: 8,
color: _muted,
),
),
],
],
),
),
),

pw.SizedBox(width: 14),

pw.SizedBox(
width: 220,
child: _buildTotals(
subtotal: subtotal,
discount: bill.discount,
total: bill.total,
),
),
],
),

pw.Spacer(),

// Footer
pw.Container(
width: double.infinity,
padding: const pw.EdgeInsets.only(top: 10),
decoration: const pw.BoxDecoration(
border: pw.Border(
top: pw.BorderSide(
color: _border,
width: 0.8,
),
),
),
child: pw.Column(
children: [
pw.Text(
'Thank you for shopping with $companyName!',
textAlign: pw.TextAlign.center,
style: pw.TextStyle(
fontSize: 10,
fontWeight: pw.FontWeight.bold,
color: _navy,
),
),
pw.SizedBox(height: 3),
pw.Text(
'We look forward to serving you again.',
textAlign: pw.TextAlign.center,
style: const pw.TextStyle(
fontSize: 8,
color: _muted,
),
),
],
),
),
],
);
},
),
);

return pdf.save();
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

pw.Widget _buildHeader(
String companyName,
Bill bill, {
String? address,
String? mobile,
String? upiId,
}) {
return pw.Column(
children: [
pw.Row(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [
pw.Expanded(
child: pw.Column(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [
pw.Text(
companyName.toUpperCase(),
style: pw.TextStyle(
fontSize: 20,
fontWeight: pw.FontWeight.bold,
color: _navy,
letterSpacing: 0.5,
),
),
pw.SizedBox(height: 3),
if (address != null && address.trim().isNotEmpty) ...[
pw.Text(
address.trim(),
style: const pw.TextStyle(
fontSize: 8.5,
color: _muted,
),
),
pw.SizedBox(height: 2),
],
if (mobile != null && mobile.trim().isNotEmpty) ...[
pw.Text(
'Phone: ${mobile.trim()}',
style: const pw.TextStyle(
fontSize: 8.5,
color: _muted,
),
),
pw.SizedBox(height: 2),
],
if (upiId != null && upiId.trim().isNotEmpty) ...[
pw.Text(
'UPI ID: ${upiId.trim()}',
style: const pw.TextStyle(
fontSize: 8.5,
color: _muted,
),
),
pw.SizedBox(height: 2),
],
pw.SizedBox(height: 4),
pw.Container(
padding: const pw.EdgeInsets.symmetric(
horizontal: 7,
vertical: 4,
),
decoration: pw.BoxDecoration(
color: _lightBg,
borderRadius: const pw.BorderRadius.all(
pw.Radius.circular(3),
),
),
child: pw.Text(
'TAX INVOICE / CUSTOMER RECEIPT',
style: pw.TextStyle(
fontSize: 7,
fontWeight: pw.FontWeight.bold,
color: _navy,
letterSpacing: 0.4,
),
),
),
],
),
),

pw.SizedBox(width: 12),

pw.Container(
width: 145,
padding: const pw.EdgeInsets.all(11),
decoration: pw.BoxDecoration(
color: _lightBg,
borderRadius: const pw.BorderRadius.all(
pw.Radius.circular(5),
),
border: pw.Border.all(color: _border),
),
child: pw.Column(
crossAxisAlignment: pw.CrossAxisAlignment.end,
children: [
pw.Text(
'INVOICE',
style: pw.TextStyle(
fontSize: 8,
fontWeight: pw.FontWeight.bold,
color: _muted,
letterSpacing: 1,
),
),
pw.SizedBox(height: 5),
pw.Text(
bill.id,
textAlign: pw.TextAlign.right,
style: pw.TextStyle(
fontSize: 12,
fontWeight: pw.FontWeight.bold,
color: _navy,
),
),
pw.SizedBox(height: 5),
pw.Text(
_date(bill.time),
style: const pw.TextStyle(
fontSize: 9,
color: _text,
),
),
],
),
),
],
),

pw.SizedBox(height: 12),

pw.Container(
width: double.infinity,
height: 2,
color: _navy,
),

pw.SizedBox(height: 2),

pw.Container(
width: 48,
height: 2,
color: _orange,
),
],
);
}

// ---------------------------------------------------------------------------
// Customer details
// ---------------------------------------------------------------------------

pw.Widget _sectionHeading(String title) {
return pw.Text(
title,
style: pw.TextStyle(
fontSize: 9,
fontWeight: pw.FontWeight.bold,
color: _navy,
letterSpacing: 0.7,
),
);
}

pw.Widget _buildCustomerDetails(Bill bill) {
return pw.Container(
width: double.infinity,
padding: const pw.EdgeInsets.symmetric(
horizontal: 12,
vertical: 10,
),
decoration: pw.BoxDecoration(
color: _lightBg,
border: pw.Border.all(color: _border),
borderRadius: const pw.BorderRadius.all(
pw.Radius.circular(5),
),
),
child: pw.Column(
children: [
pw.Row(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [
pw.Expanded(
child: _customerField(
'CUSTOMER NAME',
bill.customer.isEmpty ? '-' : bill.customer,
),
),
pw.SizedBox(width: 16),
pw.Expanded(
child: _customerField(
'MOBILE / WHATSAPP',
bill.mobile.isEmpty ? '-' : bill.mobile,
),
),
],
),
if (bill.note.isNotEmpty) ...[
pw.SizedBox(height: 9),
pw.Container(
width: double.infinity,
height: 0.6,
color: _border,
),
pw.SizedBox(height: 7),
_customerField('NOTE', bill.note),
],
],
),
);
}

pw.Widget _customerField(String label, String value) {
return pw.Column(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [
pw.Text(
label,
style: pw.TextStyle(
fontSize: 7,
fontWeight: pw.FontWeight.bold,
color: _muted,
letterSpacing: 0.4,
),
),
pw.SizedBox(height: 4),
pw.Text(
value,
style: pw.TextStyle(
fontSize: 10,
fontWeight: pw.FontWeight.bold,
color: _text,
),
),
],
);
}

// ---------------------------------------------------------------------------
// Products table
// ---------------------------------------------------------------------------

pw.Widget _buildItemsTable(List<dynamic> items) {
return pw.Table(
border: pw.TableBorder(
horizontalInside: const pw.BorderSide(
color: _border,
width: 0.6,
),
bottom: const pw.BorderSide(
color: _border,
width: 0.8,
),
),
columnWidths: const {
0: pw.FixedColumnWidth(24),
1: pw.FlexColumnWidth(3.0),
2: pw.FixedColumnWidth(34),
3: pw.FlexColumnWidth(1.15),
4: pw.FixedColumnWidth(30),
5: pw.FlexColumnWidth(1.45),
6: pw.FlexColumnWidth(1.65),
},
children: [
pw.TableRow(
decoration: const pw.BoxDecoration(color: _navy),
children: [
_tableCell('#', header: true),
_tableCell('PRODUCT', header: true),
_tableCell('SIZE', header: true),
_tableCell('COLOR', header: true),
_tableCell('QTY', header: true),
_tableCell('RATE', header: true, align: pw.TextAlign.right),
_tableCell('AMOUNT', header: true, align: pw.TextAlign.right),
],
),

...items.asMap().entries.map((entry) {
final index = entry.key;
final item = entry.value;

return pw.TableRow(
decoration: pw.BoxDecoration(
color: index.isEven ? _white : _lightBg,
),
verticalAlignment: pw.TableCellVerticalAlignment.middle,
children: [
_tableCell('${index + 1}'),
_tableCell(item.productName),
_tableCell(item.size.isEmpty ? '-' : item.size),
_tableCell(item.color.isEmpty ? '-' : item.color),
_tableCell('${item.qty}'),
_tableCell(
money(item.price),
align: pw.TextAlign.right,
),
_tableCell(
money(item.total),
align: pw.TextAlign.right,
bold: true,
),
],
);
}),
],
);
}

pw.Widget _tableCell(
String value, {
bool header = false,
bool bold = false,
pw.TextAlign align = pw.TextAlign.left,
}) {
return pw.Padding(
padding: const pw.EdgeInsets.symmetric(
horizontal: 5,
vertical: 9,
),
child: pw.Text(
value,
textAlign: align,
style: pw.TextStyle(
fontSize: header ? 7 : 8,
fontWeight: header || bold
? pw.FontWeight.bold
    : pw.FontWeight.normal,
color: header ? _white : _text,
),
),
);
}

// ---------------------------------------------------------------------------
// Totals
// ---------------------------------------------------------------------------

pw.Widget _buildTotals({
required num subtotal,
required num discount,
required num total,
}) {
return pw.Container(
padding: const pw.EdgeInsets.all(11),
decoration: pw.BoxDecoration(
color: _white,
border: pw.Border.all(color: _border),
borderRadius: const pw.BorderRadius.all(
pw.Radius.circular(5),
),
),
child: pw.Column(
children: [
_totalLine('Subtotal', money(subtotal)),

if (discount > 0) ...[
pw.SizedBox(height: 7),
_totalLine(
'Discount',
'- ${money(discount)}',
valueColor: PdfColors.green700,
),
],

pw.SizedBox(height: 8),

pw.Container(
height: 0.8,
color: _border,
),

pw.SizedBox(height: 9),

pw.Row(
mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
crossAxisAlignment: pw.CrossAxisAlignment.center,
children: [
pw.Expanded(
child: pw.Text(
'GRAND TOTAL',
style: pw.TextStyle(
fontSize: 9,
fontWeight: pw.FontWeight.bold,
color: _navy,
),
),
),
pw.SizedBox(width: 6),
pw.Text(
money(total),
textAlign: pw.TextAlign.right,
style: pw.TextStyle(
fontSize: 13,
fontWeight: pw.FontWeight.bold,
color: _navy,
),
),
],
),
],
),
);
}

pw.Widget _totalLine(
String label,
String value, {
PdfColor valueColor = _text,
}) {
return pw.Row(
mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
children: [
pw.Expanded(
child: pw.Text(
label,
style: const pw.TextStyle(
fontSize: 9,
color: _muted,
),
),
),
pw.SizedBox(width: 6),
pw.Text(
value,
textAlign: pw.TextAlign.right,
style: pw.TextStyle(
fontSize: 9,
fontWeight: pw.FontWeight.bold,
color: valueColor,
),
),
],
);
}

String _date(DateTime time) {
return '${time.day.toString().padLeft(2, '0')}-'
'${time.month.toString().padLeft(2, '0')}-'
'${time.year}';
}
}

