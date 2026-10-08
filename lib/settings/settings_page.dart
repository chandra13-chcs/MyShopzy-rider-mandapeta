import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _orderAlerts = true;
  bool _sound = true;
  bool _vibration = true;
  bool _darkModeDemo = false;

  Future<void> _showInformation(String title, String message) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SectionHeading(title: 'APP PREFERENCES'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  key: const ValueKey('settings-order-alerts'),
                  secondary: const _PreferenceIcon(
                    icon: Icons.notifications_outlined,
                  ),
                  title: const Text('Order Alerts'),
                  subtitle: const Text('Local demo preference'),
                  value: _orderAlerts,
                  onChanged: (value) => setState(() => _orderAlerts = value),
                ),
                const _TileDivider(),
                SwitchListTile.adaptive(
                  key: const ValueKey('settings-sound'),
                  secondary: const _PreferenceIcon(
                    icon: Icons.volume_up_outlined,
                  ),
                  title: const Text('Sound'),
                  subtitle: const Text('Local demo preference'),
                  value: _sound,
                  onChanged: (value) => setState(() => _sound = value),
                ),
                const _TileDivider(),
                SwitchListTile.adaptive(
                  key: const ValueKey('settings-vibration'),
                  secondary: const _PreferenceIcon(
                    icon: Icons.vibration_rounded,
                  ),
                  title: const Text('Vibration'),
                  subtitle: const Text('Local demo preference'),
                  value: _vibration,
                  onChanged: (value) => setState(() => _vibration = value),
                ),
                const _TileDivider(),
                SwitchListTile.adaptive(
                  key: const ValueKey('settings-dark-mode'),
                  secondary: const _PreferenceIcon(
                    icon: Icons.dark_mode_outlined,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: const Text(
                    'Demo preference only; app theme remains unchanged',
                  ),
                  value: _darkModeDemo,
                  onChanged: (value) => setState(() => _darkModeDemo = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionHeading(title: 'APP INFORMATION'),
          const SizedBox(height: 10),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: _PreferenceIcon(icon: Icons.delivery_dining_rounded),
                  title: Text('MyShopzy Rider'),
                  subtitle: Text('Rider application'),
                ),
                _TileDivider(),
                _InformationRow(label: 'Version', value: '1.0.0'),
                _TileDivider(),
                _InformationRow(label: 'Environment', value: 'Demo'),
                _TileDivider(),
                _InformationRow(label: 'Backend', value: 'Not Connected'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionHeading(title: 'LEGAL'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const ValueKey('settings-privacy'),
                  leading: const _PreferenceIcon(
                    icon: Icons.privacy_tip_outlined,
                  ),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showInformation(
                    'Privacy Policy',
                    'This demo screen provides sample information only. '
                        'No policy links or external services are connected.',
                  ),
                ),
                const _TileDivider(),
                ListTile(
                  key: const ValueKey('settings-terms'),
                  leading: const _PreferenceIcon(
                    icon: Icons.description_outlined,
                  ),
                  title: const Text('Terms & Conditions'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showInformation(
                    'Terms & Conditions',
                    'This is placeholder information for the MyShopzy Rider '
                        'demo. Terms will be provided in a future product phase.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: AppTheme.smallStatus.copyWith(
      color: AppTheme.secondaryText,
      letterSpacing: 0.8,
    ),
  );
}

class _PreferenceIcon extends StatelessWidget {
  const _PreferenceIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Icon(icon, color: AppTheme.brand);
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppTheme.bodyText)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTheme.secondaryTextStyle.copyWith(
              color: label == 'Backend' ? AppTheme.warning : null,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 56, endIndent: 16);
}
