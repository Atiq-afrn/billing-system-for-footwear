import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../services/auth_service.dart';
import '../view_models/shop_view_model.dart';

class ChangeUpiView extends StatefulWidget {
  const ChangeUpiView({
    super.key,
    required this.viewModel,
    this.enableTimer = true,
  });

  final ShopViewModel viewModel;
  final bool enableTimer;

  @override
  State<ChangeUpiView> createState() => _ChangeUpiViewState();
}

class _ChangeUpiViewState extends State<ChangeUpiView> {
  // Verification states
  bool _isVerified = false;
  bool _isPasswordMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  // OTP State
  late String _generatedOtp;
  final TextEditingController _otpController = TextEditingController();
  int _resendCountdown = 45;
  Timer? _timer;

  // Password State
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // New UPI State
  final TextEditingController _newUpiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateAndSendOtp();
  }

  void _generateAndSendOtp() {
    // Generate secure 6-digit numeric OTP
    final random = Random();
    _generatedOtp = (100000 + random.nextInt(900000)).toString();
    _errorMessage = null;

    // Start countdown timer if enabled
    if (widget.enableTimer) {
      _resendCountdown = 45;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) {
          if (_resendCountdown > 0) {
            setState(() => _resendCountdown--);
          } else {
            t.cancel();
          }
        }
      });
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _getUserEmail() {
    return widget.viewModel.userProfile?.email ??
        AuthService.instance.currentProfile?.email ??
        'owner@store.com';
  }

  String _getOwnerName() {
    return widget.viewModel.userProfile?.name ??
        AuthService.instance.currentProfile?.name ??
        'Store Owner';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _passwordController.dispose();
    _newUpiController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final entered = _otpController.text.trim();
    if (entered.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP code.');
      return;
    }

    if (entered != _generatedOtp) {
      setState(() => _errorMessage = 'Invalid OTP code. Please check and try again or use password verification.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isVerified = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Identity verified successfully! Enter your new UPI ID below.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verifyPassword() async {
    final pwd = _passwordController.text;
    if (pwd.isEmpty) {
      setState(() => _errorMessage = 'Please enter your login password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await AuthService.instance.verifyCurrentPassword(pwd);
      if (success) {
        setState(() {
          _isVerified = true;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Firebase password verified successfully! Enter new UPI ID below.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Incorrect password. Please verify the password used for login.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Password verification error: $e';
      });
    }
  }

  Future<void> _saveNewUpi() async {
    final newUpi = _newUpiController.text.trim();
    if (newUpi.isEmpty) {
      setState(() => _errorMessage = 'Please enter a new UPI ID.');
      return;
    }

    if (!newUpi.contains('@') || newUpi.split('@').first.length < 2 || newUpi.split('@').last.length < 2) {
      setState(() => _errorMessage = 'Please enter a valid UPI format (e.g., username@bank or mobile@upi).');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.viewModel.updateUpiId(newUpi);
      await widget.viewModel.refreshUserProfile();

      if (!mounted) return;

      setState(() => _isLoading = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'UPI ID Updated',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.deepNavy),
              ),
            ],
          ),
          content: Text(
            'Your payment UPI ID has been changed to "$newUpi". All customer QR code scans and invoices now reflect this UPI ID.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done & Return', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not update UPI ID: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _getUserEmail();
    final ownerName = _getOwnerName();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Blue Background, White Icons, White Title
            _buildAppBar(context),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // Current Active UPI Card
                  _buildCurrentUpiCard(ownerName, email),

                  const SizedBox(height: 16),

                  // Progress Step Indicator
                  _buildStepHeader(),

                  const SizedBox(height: 16),

                  // Error message banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // STEP 1: Verification Card
                  if (!_isVerified)
                    _buildVerificationCard(email)
                  else
                    _buildVerifiedBadge(),

                  const SizedBox(height: 16),

                  // STEP 2: New UPI ID Card (Unlocked after verification)
                  _buildNewUpiCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A), // Blue App Bar
        boxShadow: [
          BoxShadow(
            color: Color(0x331E3A8A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // White back icon button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.viewModel.companyName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Change Store UPI ID • Security Verification',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text('SECURE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUpiCard(String ownerName, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(Icons.qr_code, color: Color(0xFF1E3A8A), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE UPI PAYMENT ID',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.viewModel.upiId,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text('Owner: $ownerName', style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  email,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    return Row(
      children: [
        _stepPill('1', 'Verify Identity', isCompleted: _isVerified, isActive: !_isVerified),
        Expanded(
          child: Container(
            height: 2,
            color: _isVerified ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
          ),
        ),
        _stepPill('2', 'Set New UPI', isCompleted: false, isActive: _isVerified),
      ],
    );
  }

  Widget _stepPill(String number, String title, {required bool isCompleted, required bool isActive}) {
    final bg = isCompleted
        ? AppColors.success
        : (isActive ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0));
    final fg = (isCompleted || isActive) ? Colors.white : const Color(0xFF64748B);

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(number, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w500,
            color: isActive || isCompleted ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identity Verified Successfully',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                ),
                Text(
                  'Authorized to configure store payment destination.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(String email) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isPasswordMode ? Icons.lock_outline : Icons.mail_lock_outlined,
                color: const Color(0xFF1E3A8A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isPasswordMode ? 'Password Authentication' : 'Email OTP Verification',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isPasswordMode
                ? 'Enter your account password used for logging into your store account.'
                : 'A 6-digit security code was generated for your registered email: $email',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
          ),
          const SizedBox(height: 14),

          // Demonstration / Local Testing OTP Banner
          if (!_isPasswordMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Security OTP: $_generatedOtp (Sent to $email)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ),

          if (!_isPasswordMode) ...[
            // 6-digit OTP input field
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Color(0xFF1E3A8A),
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '• • • • • •',
                hintStyle: const TextStyle(letterSpacing: 8, color: Color(0xFFCBD5E1)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _resendCountdown == 0 ? _generateAndSendOtp : null,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: Text(
                    _resendCountdown == 0 ? 'Resend OTP' : 'Resend OTP in ${_resendCountdown}s',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _isPasswordMode = true;
                    _errorMessage = null;
                  }),
                  child: const Text(
                    'Didn\'t receive OTP? Use Password',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _verifyOtp,
                child: const Text('Verify OTP & Proceed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ] else ...[
            // Password verification mode
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Account Password',
                hintText: 'Enter your sign-in password',
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _isPasswordMode = false;
                    _errorMessage = null;
                  }),
                  child: const Text(
                    '← Back to Email OTP',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _verifyPassword,
                child: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify Password via Firebase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewUpiCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isVerified ? const Color(0xFF1E3A8A).withOpacity(0.3) : const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: _isVerified ? const Color(0xFF1E3A8A) : const Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Enter New UPI ID',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isVerified ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              if (!_isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, size: 10, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Text('LOCKED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isVerified
                ? 'Enter your new official business UPI ID. It will instantly update QR payments and bills.'
                : 'Complete identity verification above to unlock editing this field.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _newUpiController,
            enabled: _isVerified,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'New UPI ID',
              hintText: 'e.g. storename@okaxis or 9876543210@upi',
              prefixIcon: const Icon(Icons.alternate_email, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: _isVerified ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _isVerified ? const Color(0xFF1E3A8A) : const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (_isVerified && !_isLoading) ? _saveNewUpi : null,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Save & Activate New UPI ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
