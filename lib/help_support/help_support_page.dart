import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.brandSoft,
                    child: Icon(
                      Icons.support_agent_rounded,
                      color: AppTheme.brand,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Need a hand?', style: AppTheme.sectionTitle),
                        SizedBox(height: 4),
                        Text(
                          'Our rider support team is here for you',
                          style: AppTheme.secondaryTextStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text('Frequently asked', style: AppTheme.sectionTitle),
          const SizedBox(height: 10),
          const _HelpItem(
            title: 'How do I accept a delivery?',
            answer: 'Open a new order from Home or Orders and tap View order to see the delivery details.',
          ),
          const _HelpItem(
            title: 'Where can I see my earnings?',
            answer: 'Your daily and weekly earnings are available from the Earnings tab.',
          ),
          const _HelpItem(
            title: 'How do I update my preferences?',
            answer: 'Open Settings from your Profile or from the quick links on Home.',
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Support chat is coming soon')),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Contact rider support'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.title, required this.answer});

  final String title;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          title,
          style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer,
            style: AppTheme.secondaryTextStyle.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
