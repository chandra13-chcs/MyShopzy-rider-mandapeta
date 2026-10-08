import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery history')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('Today', style: AppTheme.sectionTitle),
          SizedBox(height: 12),
          _HistoryItem(
            store: 'Green Grocers',
            time: '10:42 AM',
            payout: '₹ 120',
          ),
          SizedBox(height: 10),
          _HistoryItem(
            store: 'Daily Needs Mart',
            time: '9:18 AM',
            payout: '₹ 95',
          ),
          SizedBox(height: 10),
          _HistoryItem(
            store: 'Fresh Basket Supermarket',
            time: '8:35 AM',
            payout: '₹ 85',
          ),
          SizedBox(height: 24),
          Text('Yesterday', style: AppTheme.sectionTitle),
          SizedBox(height: 12),
          _HistoryItem(
            store: 'City Pharmacy',
            time: 'Yesterday · 6:12 PM',
            payout: '₹ 110',
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.store,
    required this.time,
    required this.payout,
  });

  final String store;
  final String time;
  final String payout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.successSoft,
          child: Icon(Icons.check_rounded, color: AppTheme.success),
        ),
        title: Text(
          store,
          style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(time),
        trailing: Text(
          payout,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
