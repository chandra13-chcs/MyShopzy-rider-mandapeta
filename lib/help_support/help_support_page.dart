import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final Set<int> _expandedFaqs = {};
  final List<GlobalKey> _faqKeys = List.generate(
    _faqEntries.length,
    (_) => GlobalKey(),
  );

  Future<void> _showDemoDialog({
    required String title,
    required String message,
    String actionLabel = 'Close',
  }) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(actionLabel),
        ),
      ],
    ),
  );

  void _toggleFaq(int index) {
    setState(() {
      if (!_expandedFaqs.add(index)) _expandedFaqs.remove(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Need a hand?', style: AppTheme.sectionTitle),
                        const SizedBox(height: 4),
                        Text(
                          'Browse local rider help topics and demo support options.',
                          style: AppTheme.secondaryTextStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quick Help', style: AppTheme.sectionTitle),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _QuickHelpTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'How to accept an order',
                  onTap: () => _openFaq(0),
                ),
                const _TileDivider(),
                _QuickHelpTile(
                  icon: Icons.storefront_outlined,
                  title: 'How pickup works',
                  onTap: () => _openFaq(2),
                ),
                const _TileDivider(),
                _QuickHelpTile(
                  icon: Icons.delivery_dining_rounded,
                  title: 'How delivery works',
                  onTap: () => _openFaq(3),
                ),
                const _TileDivider(),
                _QuickHelpTile(
                  icon: Icons.payments_outlined,
                  title: 'How earnings work',
                  onTap: () => _openFaq(4),
                ),
                const _TileDivider(),
                _QuickHelpTile(
                  icon: Icons.block_outlined,
                  title: 'What happens if I reject an order?',
                  onTap: () => _openFaq(5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('FAQ', style: AppTheme.sectionTitle),
          const SizedBox(height: 3),
          const Text('Frequently asked', style: AppTheme.secondaryTextStyle),
          const SizedBox(height: 8),
          for (var index = 0; index < _faqEntries.length; index++)
            Card(
              key: _faqKeys[index],
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionPanelList(
                elevation: 0,
                expandedHeaderPadding: EdgeInsets.zero,
                expansionCallback: (panelIndex, isExpanded) {
                  if (panelIndex == 0 &&
                      isExpanded != _expandedFaqs.contains(index)) {
                    _toggleFaq(index);
                  }
                },
                children: [
                  ExpansionPanel(
                    canTapOnHeader: true,
                    isExpanded: _expandedFaqs.contains(index),
                    headerBuilder: (context, isExpanded) => ListTile(
                      title: Text(
                        _faqEntries[index].question,
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    body: (_expandedFaqs.contains(index)
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _faqEntries[index].answer,
                                style: AppTheme.secondaryTextStyle.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          const Text('Contact Support', style: AppTheme.sectionTitle),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const ValueKey('help-contact-center'),
                  leading: const Icon(
                    Icons.help_center_outlined,
                    color: AppTheme.brand,
                  ),
                  title: const Text('Help Center'),
                  subtitle: const Text('Browse demo support information'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showDemoDialog(
                    title: 'Help Center',
                    message:
                        'You are viewing the MyShopzy Rider demo help center. '
                        'Support services are not connected.',
                  ),
                ),
                const _TileDivider(),
                ListTile(
                  key: const ValueKey('help-report-issue'),
                  leading: const Icon(
                    Icons.report_problem_outlined,
                    color: AppTheme.brand,
                  ),
                  title: const Text('Report an Issue'),
                  subtitle: const Text('Demo action; no report will be sent'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showDemoDialog(
                    title: 'Report an Issue',
                    message:
                        'Issue reporting is a demo action only. '
                        'No ticket or message has been sent.',
                  ),
                ),
                const _TileDivider(),
                ListTile(
                  key: const ValueKey('help-emergency'),
                  leading: const Icon(
                    Icons.emergency_outlined,
                    color: AppTheme.error,
                  ),
                  title: const Text('Emergency Help'),
                  subtitle: const Text('Demo information only'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showDemoDialog(
                    title: 'Emergency Help',
                    message:
                        'For immediate danger, contact local emergency '
                        'services. This demo does not place calls or access '
                        'your location.',
                    actionLabel: 'Understood',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFaq(int index) {
    _toggleFaq(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _faqKeys[index].currentContext;
      if (!mounted || targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }
}

class _FaqEntry {
  const _FaqEntry({required this.question, required this.answer});

  final String question;
  final String answer;
}

const _faqEntries = [
  _FaqEntry(
    question: 'How do I accept an order?',
    answer:
        'Open the available demo offer from Home or Orders and choose Accept '
        'before its timer expires. The accepted order appears as your active '
        'delivery.',
  ),
  _FaqEntry(
    question: 'How do I reach the pickup store?',
    answer:
        'Open the active delivery details to view the store name, pickup '
        'address, and demo distance. This app does not provide live maps or '
        'navigation.',
  ),
  _FaqEntry(
    question: 'How do I verify pickup?',
    answer:
        'At the store, open the order details and enter the demo order’s last '
        'four digits when asked. Pickup is not confirmed until you submit the '
        'correct demo value.',
  ),
  _FaqEntry(
    question: 'How do I mark an order delivered?',
    answer:
        'After continuing to delivery and reaching the customer, follow the '
        'confirmation steps on Delivery Details. The demo delivery is marked '
        'complete only after your explicit confirmation.',
  ),
  _FaqEntry(
    question: 'How are earnings calculated?',
    answer:
        'The Earnings screen displays sample delivery amounts, distances, '
        'and totals. All values in this version are demo data.',
  ),
  _FaqEntry(
    question: 'What happens if I reject an order?',
    answer:
        'The demo offer is marked rejected and your availability remains '
        'unchanged. You can check for another demo offer while available and '
        'not busy.',
  ),
  _FaqEntry(
    question: 'What should I do if the customer is unavailable?',
    answer:
        'This demo does not provide customer contact or issue-resolution '
        'services. Use the on-screen demo flow and the Contact Support '
        'information; no call or support ticket will be created.',
  ),
];

class _QuickHelpTile extends StatelessWidget {
  const _QuickHelpTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.brand),
    title: Text(title, style: AppTheme.bodyText),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 56, endIndent: 16);
}
