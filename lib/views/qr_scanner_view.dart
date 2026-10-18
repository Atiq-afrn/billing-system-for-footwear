import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app/app_colors.dart';
import '../models/product.dart';
import '../widgets/shop_widgets.dart';

class QrScannerView extends StatefulWidget {
  const QrScannerView({
    super.key,
    required this.products,
    this.onProductScanned,
    this.onRawCodeScanned,
    this.initialAmount = 999,
    this.companyName = 'Ayesha Footwear',
    this.upiId = 'atiqullahkhan554@okicici',
  });

  final List<Product> products;
  final ValueChanged<Product>? onProductScanned;
  final ValueChanged<String>? onRawCodeScanned;
  final int initialAmount;
  final String companyName;
  final String upiId;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _laserAnimController;

  bool isFlashOn = false;
  bool isFrontCamera = false;

  int selectedMode = 0; // 0 = Camera Scanner, 1 = My UPI QR
  final manualCodeController = TextEditingController();
  late final TextEditingController paymentAmountController;

  Product? detectedProduct;
  String? scannedRawValue;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    paymentAmountController = TextEditingController(
      text: widget.initialAmount > 0 ? widget.initialAmount.toString() : '999',
    );

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _laserAnimController.dispose();
    manualCodeController.dispose();
    paymentAmountController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final now = DateTime.now();
    if (_lastScanTime != null && now.difference(_lastScanTime!).inMilliseconds < 1200) {
      return; // Debounce fast repeat scans
    }

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) return;

    _lastScanTime = now;
    _processScannedCode(rawValue);
  }

  void _processScannedCode(String rawCode) {
    setState(() {
      scannedRawValue = rawCode;
    });

    // Check if rawCode matches a product in stock
    final clean = rawCode.trim().toLowerCase();
    Product? matched;

    for (final p in widget.products) {
      if (p.id.toLowerCase() == clean ||
          p.name.toLowerCase() == clean ||
          clean.contains(p.id.toLowerCase())) {
        matched = p;
        break;
      }
    }

    // Try parsing JSON if structured product QR
    if (matched == null && (rawCode.startsWith('{') && rawCode.endsWith('}'))) {
      try {
        final data = jsonDecode(rawCode) as Map<String, dynamic>;
        final id = (data['id'] ?? data['product_id'] ?? '') as String;
        if (id.isNotEmpty) {
          matched = widget.products.firstWhere(
            (p) => p.id.toLowerCase() == id.toLowerCase(),
            orElse: () => Product(
              id: id,
              name: (data['name'] ?? 'Scanned Footwear') as String,
              category: (data['category'] ?? 'Men Formal') as String,
              stock: (data['stock'] as num?)?.toInt() ?? 10,
              price: (data['price'] as num?)?.toInt() ?? 999,
              sizes: (data['sizes'] as List?)?.map((e) => e.toString()).toList() ?? ['7', '8', '9'],
              colors: (data['colors'] as List?)?.map((e) => e.toString()).toList() ?? ['Black', 'Tan'],
            ),
          );
        }
      } catch (_) {}
    }

    setState(() {
      detectedProduct = matched;
    });

    if (widget.onRawCodeScanned != null && matched == null) {
      widget.onRawCodeScanned!(rawCode);
    }
  }

  void _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() => isFlashOn = !isFlashOn);
    } catch (_) {}
  }

  void _switchCamera() async {
    try {
      await _scannerController.switchCamera();
      setState(() => isFrontCamera = !isFrontCamera);
    } catch (_) {}
  }

  String get _upiPaymentUri {
    final amt = paymentAmountController.text.trim();
    final amountVal = double.tryParse(amt) ?? 0.0;
    final upiId = widget.upiId.trim().isNotEmpty ? widget.upiId.trim() : 'atiqullahkhan554@okicici';
    final payeeName = Uri.encodeComponent(widget.companyName);
    final note = Uri.encodeComponent('${widget.companyName} Bill');

    if (amountVal > 0) {
      return 'upi://pay?pa=$upiId&pn=$payeeName&am=${amountVal.toStringAsFixed(2)}&cu=INR&tn=$note';
    }
    return 'upi://pay?pa=$upiId&pn=$payeeName&cu=INR&tn=$note';
  }

  void _triggerSoundboxAnnouncement() {
    final amt = paymentAmountController.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF002E6E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🔊 "Rs $amt payment received via UPI for ${widget.companyName}!"',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: null, // Title removed as requested
        actions: [
          // Flashlight and camera switch ONLY shown in Camera Scanner mode (selectedMode == 0)
          if (selectedMode == 0) ...[
            IconButton(
              icon: Icon(
                isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: isFlashOn ? AppColors.accent : Colors.white,
              ),
              tooltip: 'Flashlight',
              onPressed: _toggleTorch,
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              tooltip: 'Switch Camera',
              onPressed: _switchCamera,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode switch tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => selectedMode = 0),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedMode == 0 ? const Color(0xFF002E6E) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 18, color: selectedMode == 0 ? AppColors.accent : Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            'Scan Camera',
                            style: TextStyle(
                              color: selectedMode == 0 ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => selectedMode = 1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedMode == 1 ? const Color(0xFF002E6E) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code, size: 18, color: selectedMode == 1 ? AppColors.accent : Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            'Store UPI QR Code',
                            style: TextStyle(
                              color: selectedMode == 1 ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: selectedMode == 0 ? _buildCameraScannerView() : _buildUpiQrView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraScannerView() {
    return Column(
      children: [
        // Camera Viewfinder Box
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Real Camera Feed
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) {
                    return Container(
                      color: Colors.black87,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam_off, color: Colors.orange, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Camera initialized or simulator mode active.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You can scan presets or type any code below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Viewfinder Framing Overlay
              Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              // 4 Corner brackets
              _buildCornerBracket(top: 0, left: 0, isTop: true, isLeft: true),
              _buildCornerBracket(top: 0, right: 0, isTop: true, isLeft: false),
              _buildCornerBracket(bottom: 0, left: 0, isTop: false, isLeft: true),
              _buildCornerBracket(bottom: 0, right: 0, isTop: false, isLeft: false),

              // Animated Laser Line
              AnimatedBuilder(
                animation: _laserAnimController,
                builder: (context, _) {
                  return Positioned(
                    top: 25 + (_laserAnimController.value * 220),
                    child: Container(
                      width: 240,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.transparent, Color(0xFF00BAF2), AppColors.accent, Colors.transparent],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BAF2).withOpacity(0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Bottom Controls / Scanned Result Card
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Manual Search Input Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: manualCodeController,
                          onSubmitted: (v) => _processScannedCode(v),
                          decoration: InputDecoration(
                            hintText: 'Enter code or barcode (e.g. PROD-001)',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _processScannedCode(manualCodeController.text),
                        child: const Text('SEARCH'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Quick Scan Stock Chips
                  if (widget.products.isNotEmpty) ...[
                    const Text(
                      '⚡ Quick Stock Barcode Presets:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.products.map((p) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              avatar: const Icon(Icons.qr_code, size: 14, color: Color(0xFF002E6E)),
                              label: Text('${p.id}: ${p.name.split(' ').take(2).join(' ')}'),
                              onPressed: () => _processScannedCode(p.id),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Detected Product Card
                  if (detectedProduct != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.deepNavy.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.deepNavy,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.inventory_2, color: AppColors.accent, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detectedProduct!.name,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                    ),
                                    Text(
                                      'ID: ${detectedProduct!.id} • Category: ${detectedProduct!.category}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                money(detectedProduct!.price),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.deepNavy),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Available Stock: ${detectedProduct!.stock} pairs',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: detectedProduct!.stock <= 0 ? Colors.red : Colors.green.shade800,
                                ),
                              ),
                              Text(
                                'Sizes: ${detectedProduct!.sizes.join(', ')}',
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: FilledButton.icon(
                              style: orangeButton(),
                              onPressed: () {
                                Navigator.pop(context);
                                if (widget.onProductScanned != null) {
                                  widget.onProductScanned!(detectedProduct!);
                                }
                                if (widget.onRawCodeScanned != null) {
                                  widget.onRawCodeScanned!(detectedProduct!.id);
                                }
                              },
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text(
                                'SELECT & USE THIS ITEM',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (scannedRawValue != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Scanned Code: $scannedRawValue (No exact catalog match)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (widget.onRawCodeScanned != null) {
                                widget.onRawCodeScanned!(scannedRawValue!);
                              }
                            },
                            child: const Text('USE CODE'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpiQrView() {
    final parsedAmt = double.tryParse(paymentAmountController.text.trim()) ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Store UPI QR Container
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BAF2).withOpacity(0.20),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, color: Color(0xFF002E6E), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'UPI Payment Accepted Here',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF002E6E)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.companyName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.deepNavy),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'UPI ID: ${widget.upiId}',
                    style: const TextStyle(color: Color(0xFF002E6E), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),

                // REAL Live Generated UPI QR Code
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black12, width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: QrImageView(
                    data: _upiPaymentUri,
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: true,
                    embeddedImage: null,
                    errorStateBuilder: (cxt, err) {
                      return const Center(child: Text('Error generating UPI QR'));
                    },
                  ),
                ),
                const SizedBox(height: 12),

                if (parsedAmt > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002E6E).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pay Exact Amount: ${money(parsedAmt)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF002E6E)),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Scan with any UPI App: Google Pay, PhonePe, Paytm, Cred, BHIM',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // PREMIUM DESIGN: Dynamic Bill UPI Amount Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF002E6E).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.point_of_sale, color: Color(0xFF002E6E), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter Bill Amount for QR',
                            style: TextStyle(
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Generates custom instant payment QR with soundbox alert',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hero Input Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF002E6E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: paymentAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: const [
                            NoLeadingDotNumberFormatter(allowDecimals: true),
                          ],
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (paymentAmountController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 20),
                          onPressed: () {
                            setState(() {
                              paymentAmountController.clear();
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Amount Addition Pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [100, 200, 500, 1000].map((addVal) {
                    return InkWell(
                      onTap: () {
                        final current = double.tryParse(paymentAmountController.text.trim()) ?? 0.0;
                        final updated = current + addVal;
                        setState(() {
                          paymentAmountController.text = updated == updated.roundToDouble()
                              ? updated.toInt().toString()
                              : updated.toStringAsFixed(2);
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '+₹$addVal',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF002E6E),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Soundbox Alert Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF002E6E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _triggerSoundboxAnnouncement,
                    icon: const Icon(Icons.volume_up, color: AppColors.accent, size: 20),
                    label: const Text(
                      'PLAY SOUNDBOX VOICE CONFIRMATION',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBracket({double? top, double? bottom, double? left, double? right, required bool isTop, required bool isLeft}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(14) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(14) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(14) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(14) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
