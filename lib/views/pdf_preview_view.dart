import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/bill.dart';
import '../services/auth_service.dart';
import '../services/bill_pdf_service.dart';

class PdfPreviewView extends StatelessWidget {
  const PdfPreviewView({
    super.key,
    required this.bill,
    this.companyName,
    this.companyAddress,
    this.companyMobile,
    this.upiId,
  });

  final Bill bill;
  final String? companyName;
  final String? companyAddress;
  final String? companyMobile;
  final String? upiId;

  String _resolveCompanyName() {
    if (companyName != null && companyName!.trim().isNotEmpty) {
      return companyName!.trim();
    }
    final active = AuthService.instance.activeCompany?.name;
    if (active != null && active.trim().isNotEmpty) {
      return active.trim();
    }
    final profile = AuthService.instance.currentProfile?.companyName;
    if (profile != null && profile.trim().isNotEmpty) {
      return profile.trim();
    }
    return 'Footwear Store';
  }

  String? _resolveAddress() {
    if (companyAddress != null && companyAddress!.trim().isNotEmpty) {
      return companyAddress!.trim();
    }
    final active = AuthService.instance.activeCompany?.address;
    if (active != null && active.trim().isNotEmpty) {
      return active.trim();
    }
    return null;
  }

  String? _resolveMobile() {
    if (companyMobile != null && companyMobile!.trim().isNotEmpty) {
      return companyMobile!.trim();
    }
    final active = AuthService.instance.activeCompany?.mobile;
    if (active != null && active.trim().isNotEmpty) {
      return active.trim();
    }
    final profile = AuthService.instance.currentProfile?.mobile;
    if (profile != null && profile.trim().isNotEmpty) {
      return profile.trim();
    }
    return null;
  }

  String? _resolveUpiId() {
    if (upiId != null && upiId!.trim().isNotEmpty) {
      return upiId!.trim();
    }
    final active = AuthService.instance.activeCompany?.upiId;
    if (active != null && active.trim().isNotEmpty) {
      return active.trim();
    }
    final profile = AuthService.instance.currentProfile?.upiId;
    if (profile != null && profile.trim().isNotEmpty) {
      return profile.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCompanyName = _resolveCompanyName();
    final effectiveAddress = _resolveAddress();
    final effectiveMobile = _resolveMobile();
    final effectiveUpiId = _resolveUpiId();

    final service = BillPdfService();
    final sanitizedName = effectiveCompanyName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              effectiveCompanyName,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Tax Invoice • Bill #${bill.id}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: PdfPreview(
        build: (_) => service.buildBillPdf(
          bill,
          companyName: effectiveCompanyName,
          address: effectiveAddress,
          mobile: effectiveMobile,
          upiId: effectiveUpiId,
        ),
        pdfFileName: '${sanitizedName}_${bill.id}.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}

