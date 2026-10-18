import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../services/auth_service.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key, required this.onAuthSuccess});
  final VoidCallback onAuthSuccess;

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool isLoginMode = true;
  bool isLoading = false;
  bool obscurePassword = true;

  // Login controllers
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  // Register controllers
  final regNameController = TextEditingController();
  final regMobileController = TextEditingController();
  final regEmailController = TextEditingController();
  final regPasswordController = TextEditingController();
  final regCompanyController = TextEditingController(text: 'Ayesha Footwear');
  final regUpiController =
      TextEditingController(text: 'atiqullahkhan554@okicici');
  final regFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    regNameController.dispose();
    regMobileController.dispose();
    regEmailController.dispose();
    regPasswordController.dispose();
    regCompanyController.dispose();
    regUpiController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!loginFormKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      await AuthService.instance.login(
        email: loginEmailController.text.trim(),
        password: loginPasswordController.text,
      );
      if (mounted) {
        widget.onAuthSuccess();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorSnackBar(_parseAuthErrorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            'Login failed: ${e.toString().replaceAll('Exception:', '')}');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!regFormKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final name = regNameController.text.trim();
      final mobile = regMobileController.text.trim();
      final email = regEmailController.text.trim();
      final company = regCompanyController.text.trim();
      final upi = regUpiController.text.trim();

      await AuthService.instance.register(
        name: name,
        mobile: mobile,
        email: email,
        password: regPasswordController.text,
        companyName: company,
        upiId: upi,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
                'Welcome, ${name.isEmpty ? "Store Owner" : name}! Account registered.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onAuthSuccess();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            'Notice: ${e.toString().replaceAll('Exception:', '')}');
        widget.onAuthSuccess();
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _parseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No registered account found with this email. Please register first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please verify and try again.';
      case 'email-already-in-use':
        return 'This email address is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'The email format is invalid. Please enter a valid email.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet.';
      case 'internal-error':
        final message = (e.message ?? '').toUpperCase();
        if (message.contains('CONFIGURATION_NOT_FOUND') ||
            message.contains('CONFIGURATION')) {
          return 'Firebase Auth is not configured yet. Enable Email/Password sign-in in Firebase Console, then try again.';
        }
        return e.message ?? 'Authentication error occurred.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }

  void _showForgotPasswordDialog() {
    final resetController =
        TextEditingController(text: loginEmailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered email address to receive a secure password reset link.',
              style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
            ),
            onPressed: () async {
              final email = resetController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid email address.')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await AuthService.instance.sendPasswordReset(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Password reset link sent to $email.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('Could not send reset email: $e');
                }
              }
            },
            child: const Text('SEND RESET LINK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Brand Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF00BAF2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BAF2).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.storefront,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 16),

                // App Brand Name
                const Text(
                  'AYESHA FOOTWEAR POS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Retail Point of Sale & Inventory System',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),

                // Switcher Pill: Sign In / Register
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => isLoginMode = true),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isLoginMode
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isLoginMode
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB)
                                            .withOpacity(0.45),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color:
                                    isLoginMode ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => isLoginMode = false),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isLoginMode
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !isLoginMode
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB)
                                            .withOpacity(0.45),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Register Store',
                              style: TextStyle(
                                color: !isLoginMode
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: isLoginMode ? _buildLoginForm() : _buildRegisterForm(),
                ),

                const SizedBox(height: 18),

                // Quick Demo Store Access
                TextButton.icon(
                  onPressed: () async {
                    await AuthService.instance.setDemoProfile();
                    widget.onAuthSuccess();
                  },
                  icon:
                      const Icon(Icons.bolt, size: 16, color: AppColors.accent),
                  label: const Text(
                    'Quick Demo Store / Offline Access',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Footer Info (Flexible to prevent any screen overflow)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: Colors.white38, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Secured by Firebase Cloud Authentication',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.mainText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sign in to access your bills, inventory, and customer records.',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 20),

          // Email Field
          TextFormField(
            controller: loginEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'e.g. shop@ayeshafootwear.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 14),

          // Password Field
          TextFormField(
            controller: loginPasswordController,
            obscureText: obscurePassword,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: AppColors.secondaryText,
                ),
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
              ),
            ),
          ),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: isLoading ? null : _handleLogin,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'SIGN IN TO STORE',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: regFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Register Store Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.mainText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your Company Name and UPI ID will be used throughout the app for invoices & payments.',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 18),

          // Full Name
          TextFormField(
            controller: regNameController,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Full Name is required'
                : null,
            decoration: const InputDecoration(
              labelText: 'Owner / Manager Full Name',
              hintText: 'e.g. Atiqu Khan',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 12),

          // Mobile Number
          TextFormField(
            controller: regMobileController,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Mobile number is required';
              }
              final digits = v.replaceAll(RegExp(r'\D'), '');
              if (digits.length < 10) {
                return 'Enter valid 10-digit mobile number';
              }
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              hintText: 'e.g. 9876543210',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),

          // Company Name (CRITICAL)
          TextFormField(
            controller: regCompanyController,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Company Name is required'
                : null,
            decoration: const InputDecoration(
              labelText: 'Company / Shop Name',
              hintText: 'e.g. Ayesha Footwear',
              prefixIcon: Icon(Icons.storefront_outlined, size: 20),
              helperText: 'Visible on all receipts, headers & exports',
            ),
          ),
          const SizedBox(height: 12),

          // UPI ID (CRITICAL)
          TextFormField(
            controller: regUpiController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'UPI ID is required';
              if (!v.contains('@')) {
                return 'Enter valid UPI ID (e.g. yourname@okicici)';
              }
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Business UPI ID',
              hintText: 'e.g. atiqullahkhan554@okicici',
              prefixIcon: Icon(Icons.qr_code_2, size: 20),
              helperText: 'Used for dynamic customer payment QR codes',
            ),
          ),
          const SizedBox(height: 12),

          // Email
          TextFormField(
            controller: regEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'e.g. atiqu@ayeshafootwear.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),

          // Password
          TextFormField(
            controller: regPasswordController,
            obscureText: obscurePassword,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: AppColors.secondaryText,
                ),
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: isLoading ? null : _handleRegister,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'REGISTER & LAUNCH STORE',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
