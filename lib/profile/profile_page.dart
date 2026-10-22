import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
  Uint8List? _photoBytes;

  Future<void> _chooseProfilePhoto() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1400,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() => _photoBytes = bytes);
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the photo picker.')),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load that profile photo.')),
      );
    }
  }

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
            _ProfileReveal(index: 0, child: _buildProfileHeader()),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Rider performance'),
            const SizedBox(height: 10),
            _ProfileReveal(index: 1, child: _buildPerformance()),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Personal information'),
            const SizedBox(height: 10),
            _ProfileReveal(index: 2, child: _buildPersonalInformation()),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Verification details'),
            const SizedBox(height: 10),
            _ProfileReveal(index: 3, child: _buildVerificationDetails()),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Safety & emergency'),
            const SizedBox(height: 10),
            _ProfileReveal(index: 4, child: _buildSafetySection()),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Account'),
            const SizedBox(height: 10),
            _ProfileReveal(index: 5, child: _buildAccountSection()),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Profile actions'),
            const SizedBox(height: 10),
            _ProfileReveal(index: 6, child: _buildProfileActions()),
            const SizedBox(height: 18),
            const _SectionHeading(title: 'Legal'),
            const SizedBox(height: 10),
            _ProfileReveal(index: 7, child: _buildLegalActions()),
            const SizedBox(height: 18),
            _ProfileReveal(
              index: 8,
              child: OutlinedButton.icon(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.darkGreen, AppTheme.brand, Color(0xFF477F61)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -38,
              top: -58,
              child: _ProfileGlow(size: 150, opacity: 0.08),
            ),
            Positioned(
              right: 78,
              bottom: -74,
              child: _ProfileGlow(size: 120, opacity: 0.06),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutBack,
                        tween: Tween(begin: 0.86, end: 1),
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Semantics(
                          button: true,
                          label: 'Upload rider photo',
                          child: Tooltip(
                            message: 'Upload rider photo',
                            child: InkWell(
                              key: const ValueKey('profile-photo-upload'),
                              onTap: _chooseProfilePhoto,
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 76,
                                height: 76,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      left: 2,
                                      top: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppTheme.accentGreen,
                                              AppTheme.brandYellow,
                                              Colors.white,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.22,
                                              ),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 33,
                                          backgroundColor:
                                              AppTheme.lightGreenSurface,
                                          backgroundImage: _photoBytes == null
                                              ? null
                                              : MemoryImage(_photoBytes!),
                                          child: _photoBytes == null
                                              ? const Icon(
                                                  Icons.person_rounded,
                                                  size: 40,
                                                  color: AppTheme.brand,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandYellow,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.darkGreen,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.18,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 14,
                                          color: AppTheme.darkGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile.name,
                              style: AppTheme.sectionTitle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rider ID: ${_profile.riderId}',
                              style: AppTheme.secondaryTextStyle.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _profile.mobileNumber,
                              style: AppTheme.secondaryTextStyle.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Tap photo to update',
                              style: AppTheme.smallStatus.copyWith(
                                color: AppTheme.brandYellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showEditProfile,
                        tooltip: 'Edit Profile',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusBadge(
                        label: _profile.accountStatus,
                        color: AppTheme.darkGreen,
                        backgroundColor: AppTheme.lightGreenSurface,
                      ),
                      StatusBadge(
                        label: _profile.verificationStatus,
                        color: AppTheme.darkGreen,
                        backgroundColor: const Color(0xFFF4E8CF),
                      ),
                    ],
                  ),
                ],
              ),
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
                    backgroundColor: const Color(0xFFF7F0E2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PerformanceTile(
                    label: 'Total deliveries',
                    value: _profile.totalDeliveriesDisplay,
                    icon: Icons.delivery_dining_rounded,
                    backgroundColor: AppTheme.lightGreenSurface,
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
                    backgroundColor: const Color(0xFFEFF4EC),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PerformanceTile(
                    label: 'Cancelled',
                    value: _profile.cancelledDeliveries.toString(),
                    icon: Icons.cancel_outlined,
                    color: AppTheme.error,
                    backgroundColor: AppTheme.errorSoft,
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
                    backgroundColor: const Color(0xFFEAF2EF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PerformanceTile(
                    label: 'This month',
                    value: '${_profile.monthlyDeliveries} deliveries',
                    icon: Icons.calendar_month_outlined,
                    backgroundColor: const Color(0xFFF1F4ED),
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

class _ProfileGlow extends StatelessWidget {
  const _ProfileGlow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
      border: Border.all(color: Colors.white.withValues(alpha: opacity * 1.5)),
    ),
  );
}

class _ProfileReveal extends StatelessWidget {
  const _ProfileReveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 820);
    final start = (index * 0.085).clamp(0.0, 0.72);
    final end = (start + 0.28).clamp(0.0, 1.0);
    final entrance = Interval(start, end, curve: Curves.easeOutCubic);
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        final progress = entrance.transform(value);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 14),
            child: Transform.scale(
              scale: 0.975 + (0.025 * progress),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _PerformanceTile extends StatelessWidget {
  const _PerformanceTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppTheme.brand,
    this.backgroundColor = AppTheme.performanceTile,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320);
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.94, end: 1),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundColor, Colors.white],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.brandSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.brand, size: 20),
      ),
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
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.brandSoft,
              AppTheme.accentGreen.withValues(alpha: 0.25),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.brand, size: 20),
      ),
      title: Text(title),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppTheme.secondaryText,
        size: 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 56);
}
