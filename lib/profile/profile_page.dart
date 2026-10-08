import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../help_support/help_support_page.dart';
import '../settings/settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.brandSoft,
                    child: Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: AppTheme.brand,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ravi Kumar', style: AppTheme.sectionTitle),
                        SizedBox(height: 4),
                        Text(
                          'Rider · Mandapeta',
                          style: AppTheme.secondaryTextStyle,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile editing will be available soon'),
                      ),
                    ),
                    tooltip: 'Edit profile',
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text('Account', style: AppTheme.sectionTitle),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.phone_outlined, color: AppTheme.brand),
                  title: Text('Phone number'),
                  subtitle: Text('+91 98765 43210'),
                ),
                const Divider(height: 1, indent: 56),
                const ListTile(
                  leading: Icon(
                    Icons.directions_bike_outlined,
                    color: AppTheme.brand,
                  ),
                  title: Text('Vehicle'),
                  subtitle: Text('Motorcycle · AP 05 AB 1234'),
                ),
                const Divider(height: 1, indent: 56),
                const ListTile(
                  leading: Icon(
                    Icons.star_outline_rounded,
                    color: AppTheme.brand,
                  ),
                  title: Text('Rider rating'),
                  subtitle: Text('4.9 · Excellent work!'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsPage(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('Help & support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HelpSupportPage(),
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
}
