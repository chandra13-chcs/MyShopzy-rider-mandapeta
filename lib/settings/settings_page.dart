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
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Preferences', style: AppTheme.sectionTitle),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.brand,
                  ),
                  title: const Text('Order alerts'),
                  subtitle: const Text('Get notified about delivery offers'),
                  value: _orderAlerts,
                  onChanged: (value) => setState(() => _orderAlerts = value),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.volume_up_outlined,
                    color: AppTheme.brand,
                  ),
                  title: const Text('Alert sound'),
                  subtitle: const Text('Play a sound for new offers'),
                  value: _sound,
                  onChanged: (value) => setState(() => _sound = value),
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.dark_mode_outlined,
                    color: AppTheme.brand,
                  ),
                  title: const Text('Dark mode'),
                  value: _darkMode,
                  onChanged: (value) => setState(() => _darkMode = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('App', style: AppTheme.sectionTitle),
          const SizedBox(height: 12),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language_rounded),
                  title: Text('Language'),
                  trailing: Text('English', style: AppTheme.secondaryTextStyle),
                ),
                Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('App version'),
                  trailing: Text('1.0.0', style: AppTheme.secondaryTextStyle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
