import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../history/history_page.dart';

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryPage()),
            ),
            tooltip: 'Delivery history',
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: AppTheme.primaryText,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'TODAY · OCT 8',
                    style: TextStyle(color: AppTheme.onDarkSurface),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '₹ 1,250.00',
                    style: TextStyle(
                      color: AppTheme.surface,
                      fontWeight: FontWeight.w800,
                      fontSize: 34,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    '5 deliveries completed',
                    style: TextStyle(color: AppTheme.onDarkSurface),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Earnings breakdown', style: AppTheme.sectionTitle),
          const SizedBox(height: 12),
          const _EarningRow(label: 'Delivery pay', amount: '₹ 1,100'),
          const _EarningRow(label: 'Incentives', amount: '₹ 150'),
          const Divider(height: 24),
          const _EarningRow(
            label: 'Total earned',
            amount: '₹ 1,250',
            bold: true,
          ),
          const SizedBox(height: 26),
          const Text('This week', style: AppTheme.sectionTitle),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: AppTheme.success,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('You earned ₹ 6,480 this week')),
                  Text(
                    '↑ 12%',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w700,
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

class _EarningRow extends StatelessWidget {
  const _EarningRow({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  final String label;
  final String amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? AppTheme.primaryText : AppTheme.secondaryText,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
