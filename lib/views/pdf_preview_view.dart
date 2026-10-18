import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/bill.dart';
import '../services/bill_pdf_service.dart';

class PdfPreviewView extends StatelessWidget {
  const PdfPreviewView({super.key, required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final service = BillPdfService();
    return Scaffold(
      appBar: AppBar(title: Text('Preview ${bill.id}')),
      body: PdfPreview(
        build: (_) => service.buildBillPdf(bill),
        pdfFileName: '${bill.id}.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
