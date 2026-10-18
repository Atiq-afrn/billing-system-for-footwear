import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_colors.dart';
import '../models/bill.dart';

String money(num amount) {
  if (amount is int || amount == amount.roundToDouble()) {
    return 'Rs ${amount.toInt()}';
  }
  return 'Rs ${amount.toStringAsFixed(2)}';
}

class NoLeadingDotNumberFormatter extends TextInputFormatter {
  const NoLeadingDotNumberFormatter({this.allowDecimals = true});
  final bool allowDecimals;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Reject leading dot (e.g. .007, .006, .)
    if (text.startsWith('.')) {
      return oldValue;
    }

    if (!allowDecimals) {
      if (RegExp(r'^\d+$').hasMatch(text)) {
        return newValue;
      }
      return oldValue;
    }

    // Allow numbers with a whole number before decimal (e.g. 1.100, 800.600)
    if (RegExp(r'^\d+(\.\d*)?$').hasMatch(text)) {
      return newValue;
    }

    return oldValue;
  }
}

ButtonStyle orangeButton() => FilledButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: AppColors.deepNavy,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)));

class Header extends StatelessWidget {
  const Header({
    super.key,
    this.title,
    this.subtitle,
    this.onMenuPressed,
    this.unreadAlertsCount = 0,
    this.onNotificationsPressed,
    this.trailing,
  });

  final String? title;
  final String? subtitle;
  final VoidCallback? onMenuPressed;
  final int unreadAlertsCount;
  final VoidCallback? onNotificationsPressed;
  final Widget? trailing;

  void _openDrawer(BuildContext context) {
    if (onMenuPressed != null) {
      onMenuPressed!();
      return;
    }
    final nearest = Scaffold.maybeOf(context);
    if (nearest != null && nearest.hasDrawer) {
      nearest.openDrawer();
      return;
    }
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScaffoldState) {
        final state = element.state as ScaffoldState;
        if (state.hasDrawer) {
          state.openDrawer();
          return false;
        }
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = title != null && title!.trim().isNotEmpty
        ? title!.trim()
        : 'Ayesha Footwear';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      color: Colors.transparent,
      child: Row(
        children: [
          // Professional Side Menu Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _openDrawer(context),
                child: const Center(
                  child: Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF0F172A),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Professional Dynamic Company Name & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayTitle,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                      ),
                      child: const Text(
                        'OFFICIAL',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!.trim(),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 8),
          ],

          // Professional Notification Bell Side Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (onNotificationsPressed != null) {
                        onNotificationsPressed!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              unreadAlertsCount > 0
                                  ? '$unreadAlertsCount products are out of stock / unavailable!'
                                  : 'All footwear products are currently in stock.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Center(
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 21,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (unreadAlertsCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '$unreadAlertsCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
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
}

class CardBox extends StatelessWidget {
  const CardBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class BoxIcon extends StatelessWidget {
  const BoxIcon(this.icon,
      {super.key, required this.background, required this.color});
  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: color, size: 22),
  );
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.icon, this.label, {super.key});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(20), // Stadium border
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppColors.deepNavy),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.mainText),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]),
  );
}

class BillTile extends StatelessWidget {
  const BillTile(
      {super.key,
        required this.bill,
        required this.onPdf,
        required this.onShare});
  final Bill bill;
  final VoidCallback onPdf;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final itemsCount = bill.allItems.length;
    final itemText = itemsCount > 1
        ? '${bill.customer} • $itemsCount items (${bill.qty} pairs)'
        : '${bill.customer} • ${bill.item}${bill.size.isNotEmpty ? ' (Size ${bill.size})' : ''}';

    return CardBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BoxIcon(
            Icons.receipt_long_outlined,
            background: const Color(0xFFEFF6FF), // Soft Blue
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        bill.id,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bill.payMode,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  itemText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                money(bill.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionIcon(
                    icon: Icons.picture_as_pdf_outlined,
                    onPressed: onPdf,
                    color: const Color(0xFFDC2626), // Red for PDF
                  ),
                  const SizedBox(width: 4),
                  _buildActionIcon(
                    icon: Icons.share_outlined,
                    onPressed: onShare,
                    color: const Color(0xFF16A34A), // Green for WhatsApp/Share
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}