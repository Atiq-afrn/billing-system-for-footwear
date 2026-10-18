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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Blue App Bar
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331E3A8A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Side menu bar (white menu button that opens side drawer)
          Builder(
            builder: (ctx) => InkWell(
              onTap: () {
                if (onMenuPressed != null) {
                  onMenuPressed!();
                } else {
                  Scaffold.maybeOf(ctx)?.openDrawer();
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: const Center(
                  child: Icon(Icons.menu, color: Colors.white, size: 22),
                ),
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
                  title != null && title!.trim().isNotEmpty ? title! : 'Ayesha Footwear',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 8),
          ],
          // Notification bell with unread badge (white icon on blue app bar)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.notifications_none, size: 20, color: Colors.white),
                  onPressed: () {
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
                ),
              ),
              if (unreadAlertsCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$unreadAlertsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border)),
      child: child);
}

class BoxIcon extends StatelessWidget {
  const BoxIcon(this.icon,
      {super.key, required this.background, required this.color});
  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color));
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.icon, this.label, {super.key});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.deepNavy),
        const SizedBox(width: 6),
        Flexible(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis))
      ]));
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
        children: [
          BoxIcon(Icons.receipt_long,
              background: AppColors.accent.withValues(alpha: .14),
              color: AppColors.deepNavy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bill.id,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bill.payMode,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  itemText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.mainText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(money(bill.total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      tooltip: 'Generate PDF',
                      onPressed: onPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      visualDensity: VisualDensity.compact),
                  IconButton(
                      tooltip: 'Share on WhatsApp',
                      onPressed: onShare,
                      icon: const Icon(Icons.share_outlined),
                      visualDensity: VisualDensity.compact),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
