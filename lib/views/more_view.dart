import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../widgets/shop_widgets.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key, required this.onAction});
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    const actions = [
      (
        Icons.table_chart_outlined,
        'Export Customers Excel',
        'Save customer name, size, mobile, color preference'
      ),
      (
        Icons.picture_as_pdf_outlined,
        'Bill PDF Template',
        'Prepare printable and shareable receipts'
      ),
      (
        Icons.backup_table_outlined,
        'SQLite Database',
        'Customers, products, sales, sale items, payments'
      ),
      (
        Icons.chat_outlined,
        'WhatsApp Offers',
        'Send festival and stock arrival messages'
      ),
    ];
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Header(),
          const SizedBox(height: 22),
          Text('More', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
              'Tools for exports, receipts, local backup, and customer offers.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Expanded(
              child: ListView.separated(
                  itemCount: actions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => ListTile(
                      tileColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.border)),
                      leading:
                          Icon(actions[index].$1, color: AppColors.deepNavy),
                      title: Text(actions[index].$2,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(actions[index].$3),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onAction(actions[index].$2)))),
        ]));
  }
}
