import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../services/auth_service.dart';

class AppSplashView extends StatefulWidget {
  const AppSplashView({
    super.key,
    this.onGetStarted,
    this.onSignIn,
    this.isTourMode = false,
    this.storeName,
  });

  final VoidCallback? onGetStarted;
  final VoidCallback? onSignIn;
  final bool isTourMode;
  final String? storeName;

  @override
  State<AppSplashView> createState() => _AppSplashViewState();
}

class _AppSplashViewState extends State<AppSplashView> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _contentSlide;
  late final Animation<double> _contentFade;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _logoScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _contentSlide = Tween<double>(begin: 28.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _contentFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.95, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleGetStarted() async {
    if (!widget.isTourMode) {
      await AuthService.instance.completeSplash();
    }
    widget.onGetStarted?.call();
  }

  Future<void> _handleSignIn() async {
    if (!widget.isTourMode) {
      await AuthService.instance.completeSplash();
    }
    widget.onSignIn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompactScreen = size.height < 720;

    return Scaffold(
      backgroundColor: const Color(0xFF060913),
      body: Stack(
        children: [
          // Ambient Glow Spheres (Background visual depth)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E3A8A).withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF97316).withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.35,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4).withOpacity(0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Screen Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompactScreen ? 18.0 : 22.0,
                vertical: isCompactScreen ? 12.0 : 18.0,
              ),
              child: Column(
                children: [
                  // Top Navigation Bar (Close button if in Tour Mode)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'READY TO SCALE',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isTourMode)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          tooltip: 'Close Tour',
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        TextButton(
                          onPressed: _handleSignIn,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF38BDF8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),

                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: isCompactScreen ? 6 : 14),

                            // ==========================================
                            // 1. BRAND EMBLEM & HALO ANIMATION
                            // ==========================================
                            AnimatedBuilder(
                              animation: _entranceController,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: _logoFade,
                                  child: ScaleTransition(
                                    scale: _logoScale,
                                    child: child,
                                  ),
                                );
                              },
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: child,
                                  );
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer glowing halo
                                    Container(
                                      width: isCompactScreen ? 88 : 100,
                                      height: isCompactScreen ? 88 : 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFF97316).withOpacity(0.4),
                                            blurRadius: 36,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFF38BDF8).withOpacity(0.25),
                                            blurRadius: 24,
                                            spreadRadius: -4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Glassmorphism Emblem Card
                                    Container(
                                      width: isCompactScreen ? 76 : 88,
                                      height: isCompactScreen ? 76 : 88,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF1E293B),
                                            Color(0xFF0F172A),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFF97316).withOpacity(0.55),
                                          width: 1.8,
                                        ),
                                      ),
                                      child: Center(
                                        child: ShaderMask(
                                          shaderCallback: (bounds) => const LinearGradient(
                                            colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                                          ).createShader(bounds),
                                          child: Icon(
                                            Icons.shopping_bag_outlined,
                                            size: isCompactScreen ? 38 : 44,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: isCompactScreen ? 12 : 16),

                            // ==========================================
                            // 2. BRAND TITLE & TAGLINE
                            // ==========================================
                            AnimatedBuilder(
                              animation: _entranceController,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: _contentFade,
                                  child: Transform.translate(
                                    offset: Offset(0, _contentSlide.value),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF97316).withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFFF97316).withOpacity(0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFF97316)),
                                            SizedBox(width: 3),
                                            Text(
                                              'ULTIMATE RETAIL OS',
                                              style: TextStyle(
                                                color: Color(0xFFFDBA74),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.9,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.storeName?.isNotEmpty == true
                                        ? widget.storeName!.toUpperCase()
                                        : 'FOOTWEAR POS',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Everything your footwear store needs in one place',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: isCompactScreen ? 14 : 20),

                            // ==========================================
                            // 3. 4-PILLAR COMPACT GOAL SHOWCASE
                            // ==========================================
                            AnimatedBuilder(
                              animation: _entranceController,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: _contentFade,
                                  child: Transform.translate(
                                    offset: Offset(0, _contentSlide.value * 0.8),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _goalCard(
                                          icon: Icons.receipt_long_rounded,
                                          iconColor: const Color(0xFF38BDF8),
                                          badgeColor: const Color(0xFF0284C7).withOpacity(0.18),
                                          title: 'Fast POS Billing',
                                          desc: 'Split-second bills, Cash/UPI modes & instant QR payments.',
                                          isCompact: isCompactScreen,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _goalCard(
                                          icon: Icons.inventory_2_outlined,
                                          iconColor: const Color(0xFFF97316),
                                          badgeColor: const Color(0xFFEA580C).withOpacity(0.18),
                                          title: 'Smart Stock & Sizes',
                                          desc: 'Multi-size & color variant tracking with low-stock alerts.',
                                          isCompact: isCompactScreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _goalCard(
                                          icon: Icons.cloud_sync_rounded,
                                          iconColor: const Color(0xFF34D399),
                                          badgeColor: const Color(0xFF059669).withOpacity(0.18),
                                          title: 'Cloud Realtime Sync',
                                          desc: 'Firebase cloud multi-terminal sync with 100% offline DB.',
                                          isCompact: isCompactScreen,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _goalCard(
                                          icon: Icons.picture_as_pdf_outlined,
                                          iconColor: const Color(0xFFA78BFA),
                                          badgeColor: const Color(0xFF7C3AED).withOpacity(0.18),
                                          title: 'Thermal & WhatsApp',
                                          desc: 'Instant PDF invoices, thermal print & WhatsApp delivery.',
                                          isCompact: isCompactScreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: isCompactScreen ? 14 : 18),

                            // ==========================================
                            // 4. TRUST CAPABILITY STRIP
                            // ==========================================
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.06)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _trustPill(Icons.offline_bolt_outlined, '100% Offline Ready'),
                                  Container(width: 1, height: 14, color: Colors.white12),
                                  _trustPill(Icons.security_rounded, 'Multi-Tenant Isolated'),
                                  Container(width: 1, height: 14, color: Colors.white12),
                                  _trustPill(Icons.card_giftcard_rounded, 'Loyalty & Offers'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ==========================================
                  // 5. CALL TO ACTION BUTTONS
                  // ==========================================
                  AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _contentFade,
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isTourMode)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.4),
                                backgroundColor: Colors.white.withOpacity(0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                              label: const Text(
                                'BACK TO STORE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          )
                        else ...[
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF97316).withOpacity(0.4),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _handleGetStarted,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'GET STARTED / REGISTER STORE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _handleSignIn,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  children: [
                                    TextSpan(text: 'Already registered your company? '),
                                    TextSpan(
                                      text: 'Sign In',
                                      style: TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalCard({
    required IconData icon,
    required Color iconColor,
    required Color badgeColor,
    required String title,
    required String desc,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10.0 : 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: isCompact ? 17 : 20),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 9),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: isCompact ? 9.8 : 10.8,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustPill(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
