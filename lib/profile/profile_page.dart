import 'package:flutter/material.dart';

import '../core/state/availability_store.dart';
import '../core/state/new_order_alert.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_badge.dart';
import '../help_support/help_support_page.dart';
import '../settings/settings_page.dart';
import 'rider_profile_demo_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.availabilityStore,
    this.newOrderAlert,
    super.key,
  });

  final AvailabilityStore availabilityStore;
  final NewOrderAlert? newOrderAlert;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  RiderProfileDemoData _profile = const RiderProfileDemoData();

  Future<void> _showEditProfile() async {
    final updatedProfile = await showDialog<RiderProfileDemoData>(
      context: context,
      builder: (_) => _EditProfileDialog(profile: _profile),
    );
    if (!mounted || updatedProfile == null) return;
    setState(() => _profile = updatedProfile);
  }

  Future<void> _showInformationDialog(String title, String message) =>
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

  Future<void> _confirmSos() async {
    final shouldTrigger = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Assistance'),
        content: const Text('Are you sure you want to trigger SOS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Trigger SOS'),
          ),
        ],
      ),
    );
    if (!mounted || shouldTrigger != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS request recorded for demo.')),
    );
  }

  Future<void> _openPage(Widget page) =>
      Navigator.of(context)
          .push<void>(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Rider performance'),
            const SizedBox(height: 10),
            _buildPerformance(),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Personal information'),
            const SizedBox(height: 10),
            _buildPersonalInformation(),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Verification details'),
            const SizedBox(height: 10),
            _buildVerificationDetails(),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Safety & emergency'),
            const SizedBox(height: 10),
            _buildSafetySection(),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Account'),
            const SizedBox(height: 10),
            _buildAccountSection(),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Profile actions'),
            const SizedBox(height: 10),
            _buildProfileActions(),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Legal'),
            const SizedBox(height: 10),
            _buildLegalActions(),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              key: const ValueKey('profile-logout'),
              onPressed: () => _showInformationDialog(
                'Logout',
                'Authentication will be connected in a future backend phase.',
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: AppTheme.brandSoft,
                  child: Icon(
                    Icons.person_rounded,
                    size: 38,
                    color: AppTheme.brand,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile.name, style: AppTheme.sectionTitle),
                      const SizedBox(height: 4),
                      Text(
                        'Rider ID: ${_profile.riderId}',
                        style: AppTheme.secondaryTextStyle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _profile.mobileNumber,
                        style: AppTheme.secondaryTextStyle,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showEditProfile,
                  tooltip: 'Edit Profile',
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.brand),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(
                  label: _profile.accountStatus,
                  color: AppTheme.success,
                  backgroundColor: AppTheme.successSoft,
                ),
                StatusBadge(
                  label: _profile.verificationStatus,
                  color: AppTheme.success,
                  backgroundColor: AppTheme.successSoft,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _PerformanceTile(
                    label: 'Overall rating',
                    value: '${_profile.rating.toStringAsFixed(1)} ⭐',
                    icon: Icons.star_rounded,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PerformanceTile(
                    label: 'Total deliveries',
                    value: _profile.totalDeliveriesDisplay,
                    icon: Icons.delivery_dining_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PerformanceTile(
                    label: 'Completed',
                    value: _profile.completedDeliveriesDisplay,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PerformanceTile(
                    label: 'Cancelled',
                    value: _profile.cancelledDeliveries.toString(),
                    icon: Icons.cancel_outlined,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PerformanceTile(
                    label: 'Total earnings',
                    value: _profile.totalEarningsDisplay,
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PerformanceTile(
                    label: 'This month',
                    value: '${_profile.monthlyDeliveries} deliveries',
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return Card(
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.person_outline_rounded,
            title: 'Full Name',
            value: _profile.name,
          ),
          const _TileDivider(),
          _InfoTile(
            icon: Icons.phone_outlined,
            title: 'Mobile Number',
            value: _profile.mobileNumber,
          ),
          const _TileDivider(),
          _InfoTile(
            icon: Icons.phone_in_talk_outlined,
            title: 'Alternate Number',
            value: _profile.alternateNumber,
          ),
          const _TileDivider(),
          _InfoTile(
            icon: Icons.contact_emergency_outlined,
            title: 'Emergency Contact',
            value: _profile.emergencyContact,
          ),
          const _TileDivider(),
          _InfoTile(
            icon: Icons.call_outlined,
            title: 'Emergency Contact Number',
            value: _profile.emergencyNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationDetails() {
    return Card(
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.verified_user_outlined,
            title: 'Aadhaar ID',
            value: _profile.maskedAadhaar,
          ),
          const _TileDivider(),
          _InfoTile(
            icon: Icons.two_wheeler_outlined,
            title: 'Vehicle Type',
            value: _profile.vehicleType,
          ),
          const _TileDivider(),
          _InfoTile(
            icon: Icons.confirmation_number_outlined,
            title: 'Vehicle Number',
            value: _profile.vehicleNumber,
          ),
          const _TileDivider(),
          _InfoTile(
            icon: Icons.verified_outlined,
            title: 'Verification Status',
            value: _profile.verificationStatus,
            valueColor: AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetySection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.errorSoft,
              child: Icon(Icons.sos_rounded, color: AppTheme.error),
            ),
            title: const Text('SOS', style: AppTheme.cardTitle),
            subtitle: const Text('Demo emergency assistance only'),
            trailing: FilledButton(
              key: const ValueKey('profile-trigger-sos'),
              onPressed: _confirmSos,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.error,
                minimumSize: const Size(48, 40),
              ),
              child: const Text('SOS'),
            ),
          ),
          const _TileDivider(),
          _InfoTile(
            icon: Icons.contact_emergency_outlined,
            title: 'Emergency Contact',
            value: _profile.emergencyContact,
          ),
          const _TileDivider(),
          ListTile(
            leading: const Icon(Icons.call_outlined, color: AppTheme.brand),
            title: const Text('Call Emergency Contact'),
            subtitle: Text(_profile.emergencyNumber),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showInformationDialog(
              'Demo action',
              'Calls are not connected in this demo.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.account_circle_outlined,
            title: 'Account Status',
            value: _profile.accountStatus,
            valueColor: AppTheme.success,
          ),
          const _TileDivider(),
          _InfoTile(
            icon: Icons.verified_outlined,
            title: 'Verification',
            value: _profile.verificationStatus,
            valueColor: AppTheme.success,
          ),
          const _TileDivider(),
          AnimatedBuilder(
            animation: widget.availabilityStore,
            builder: (context, child) => _InfoTile(
              icon: widget.availabilityStore.isAvailable
                  ? Icons.wifi_rounded
                  : Icons.wifi_off_rounded,
              title: 'Availability',
              value: widget.availabilityStore.isAvailable
                  ? 'Online'
                  : 'Offline',
              valueColor: widget.availabilityStore.isAvailable
                  ? AppTheme.success
                  : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActions() {
    return Card(
      child: Column(
        children: [
          _ActionTile(
            key: const ValueKey('profile-edit'),
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            onTap: _showEditProfile,
          ),
          const _TileDivider(),
          _ActionTile(
            key: const ValueKey('profile-emergency-contacts'),
            icon: Icons.contact_emergency_outlined,
            title: 'Emergency Contacts',
            onTap: () => _showInformationDialog(
              'Emergency Contacts',
              '${_profile.emergencyContact}\n${_profile.emergencyNumber}',
            ),
          ),
          const _TileDivider(),
          _ActionTile(
            key: const ValueKey('profile-help'),
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            onTap: () => _openPage(const HelpSupportPage()),
          ),
          const _TileDivider(),
          _ActionTile(
            key: const ValueKey('profile-settings'),
            icon: Icons.tune_rounded,
            title: 'Settings',
            onTap: () =>
                _openPage(SettingsPage(newOrderAlert: widget.newOrderAlert)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalActions() {
    return Card(
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _showInformationDialog(
              'Privacy Policy',
              'This demo profile uses local sample information only. '
                  'No personal information is sent to a server.',
            ),
          ),
          const _TileDivider(),
          _ActionTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => _showInformationDialog(
              'Terms & Conditions',
              'This is a local demonstration of the MyShopzy Rider app.',
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile});

  final RiderProfileDemoData profile;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.profile.name);
  late final _alternateController = TextEditingController(
    text: widget.profile.alternateNumber,
  );
  late final _emergencyContactController = TextEditingController(
    text: widget.profile.emergencyContact,
  );
  late final _emergencyNumberController = TextEditingController(
    text: widget.profile.emergencyNumber,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _alternateController.dispose();
    _emergencyContactController.dispose();
    _emergencyNumberController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      widget.profile.copyWith(
        name: _nameController.text.trim(),
        alternateNumber: _alternateController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        emergencyNumber: _emergencyNumberController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('edit-profile-name'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: _requiredValidator,
              ),
              TextFormField(
                key: const ValueKey('edit-profile-alternate'),
                controller: _alternateController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Alternate Number',
                ),
                validator: _requiredValidator,
              ),
              TextFormField(
                key: const ValueKey('edit-profile-emergency-contact'),
                controller: _emergencyContactController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact',
                ),
                validator: _requiredValidator,
              ),
              TextFormField(
                key: const ValueKey('edit-profile-emergency-number'),
                controller: _emergencyNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Number',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 8),
              const Text(
                'Rider ID, verification and account details are read-only.',
                style: AppTheme.secondaryTextStyle,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('edit-profile-save'),
          onPressed: _save,
          child: const Text('Save Demo Changes'),
        ),
      ],
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: AppTheme.sectionTitle);
}

class _PerformanceTile extends StatelessWidget {
  const _PerformanceTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppTheme.brand,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.performanceTile,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(text: value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.cardTitle,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.secondaryTextStyle,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.brand),
      title: Text(title, style: AppTheme.secondaryTextStyle),
      subtitle: Text(
        value,
        style: AppTheme.bodyText.copyWith(
          color: valueColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    Key? key,
  }) : tileKey = key;

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Key? tileKey;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      leading: Icon(icon, color: AppTheme.brand),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 56);
}
