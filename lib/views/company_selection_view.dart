import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/company_profile.dart';
import '../services/auth_service.dart';
import '../view_models/shop_view_model.dart';

class CompanySelectionView extends StatefulWidget {
  const CompanySelectionView({
    super.key,
    required this.viewModel,
    required this.onCompanySelected,
  });

  final ShopViewModel viewModel;
  final Future<void> Function(CompanyProfile company) onCompanySelected;

  @override
  State<CompanySelectionView> createState() => _CompanySelectionViewState();
}

class _CompanySelectionViewState extends State<CompanySelectionView> {
  bool isLoading = false;
  List<CompanyProfile> companies = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => isLoading = true);
    try {
      final list = await AuthService.instance.fetchAuthorizedCompanies();
      if (mounted) {
        setState(() {
          companies = list;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleSelectCompany(CompanyProfile company) async {
    setState(() => isLoading = true);
    try {
      await widget.onCompanySelected(company);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error launching company: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showCreateBranchDialog() {
    final nameCtrl = TextEditingController();
    final upiCtrl = TextEditingController(text: widget.viewModel.upiId);
    final mobileCtrl = TextEditingController(text: widget.viewModel.userProfile?.mobile ?? '');
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_business, color: Color(0xFF1E3A8A), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Register Company / Branch',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Register a new isolated company under your authenticated account. Products, bills, and stock remain completely separated.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Company / Store Name *',
                    hintText: 'e.g. Ayesha Footwear Branch 2',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter company name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: upiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Store UPI ID for Billing *',
                    hintText: 'e.g. merchant@okaxis',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid UPI ID' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Mobile Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dlgContext);
              setState(() => isLoading = true);
              try {
                final newComp = await AuthService.instance.registerNewBranch(
                  name: nameCtrl.text.trim(),
                  upiId: upiCtrl.text.trim(),
                  mobile: mobileCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                );
                await widget.onCompanySelected(newComp);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => isLoading = false);
              }
            },
            child: const Text('Register & Open', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = (AuthService.instance.currentProfile?.name != null &&
            AuthService.instance.currentProfile!.name.trim().isNotEmpty)
        ? AuthService.instance.currentProfile!.name.trim()
        : 'Store Owner';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Select Company / Branch',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await widget.viewModel.logout();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Loading authorized companies...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 550),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.business, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome, $ownerName',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Choose which company or store branch to open',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Section Title & Refresh
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'YOUR AUTHORIZED COMPANIES (${companies.length})',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                                tooltip: 'Refresh',
                                onPressed: _loadCompanies,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Company List
                          Expanded(
                            child: companies.isEmpty
                                ? Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.storefront_outlined,
                                              size: 48, color: Colors.white38),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'No registered companies found',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Register your first company below to begin.',
                                            style:
                                                TextStyle(color: Colors.white60, fontSize: 12),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          FilledButton.icon(
                                            onPressed: _showCreateBranchDialog,
                                            icon: const Icon(Icons.add, size: 16),
                                            label: const Text('Register Company'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: companies.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final comp = companies[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x33000000),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEFF6FF),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Icon(Icons.storefront,
                                                      color: Color(0xFF2563EB), size: 24),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        comp.name,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w900,
                                                          color: Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          'ID: ${comp.id}',
                                                          style: const TextStyle(
                                                            fontSize: 10.5,
                                                            fontWeight: FontWeight.w700,
                                                            color: Color(0xFF475569),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                            const SizedBox(height: 10),

                                            // Details: UPI ID, Mobile, Created Date (NO PASSWORDS, NO EMAILS)
                                            Row(
                                              children: [
                                                const Icon(Icons.qr_code,
                                                    size: 14, color: Color(0xFF64748B)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'UPI: ${comp.upiId.isNotEmpty ? comp.upiId : "Not set"}',
                                                    style: const TextStyle(
                                                        fontSize: 12, color: Color(0xFF334155)),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (comp.mobile.isNotEmpty) ...[
                                                  const Icon(Icons.phone,
                                                      size: 14, color: Color(0xFF64748B)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    comp.mobile,
                                                    style: const TextStyle(
                                                        fontSize: 12, color: Color(0xFF334155)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 14),

                                            // Action Button
                                            SizedBox(
                                              width: double.infinity,
                                              height: 44,
                                              child: FilledButton.icon(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: const Color(0xFF2563EB),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10)),
                                                ),
                                                onPressed: () => _handleSelectCompany(comp),
                                                icon: const Icon(Icons.login, size: 16),
                                                label: const Text(
                                                  'LAUNCH STORE',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 13,
                                                      letterSpacing: 0.5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 12),

                          // Add Company / Branch Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _showCreateBranchDialog,
                              icon: const Icon(Icons.add_business_outlined, size: 18),
                              label: const Text(
                                '+ REGISTER NEW COMPANY / BRANCH',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    letterSpacing: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
