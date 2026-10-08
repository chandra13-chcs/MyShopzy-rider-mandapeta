import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/section_title.dart';
import '../core/widgets/status_badge.dart';
import '../delivery/delivery_page.dart';
import '../earnings/earnings_page.dart';
import '../history/history_page.dart';
import '../help_support/help_support_page.dart';
import '../orders/orders_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isOnline = true;

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(),
                const SizedBox(height: 22),
                _buildOnlineCard(),
                const SizedBox(height: 20),
                _buildEarningsCard(),
                const SizedBox(height: 24),
                SectionTitle(
                  title: "Today's overview",
                  action: 'History',
                  onAction: () => _openPage(const HistoryPage()),
                ),
                const SizedBox(height: 10),
                _buildOverview(),
                const SizedBox(height: 24),
                SectionTitle(
                  title: 'New delivery',
                  action: 'All orders',
                  onAction: () => _openPage(const OrdersPage()),
                ),
                const SizedBox(height: 10),
                _buildDeliveryCard(),
                const SizedBox(height: 22),
                _buildQuickLinks(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delivery_dining,
            color: AppTheme.brand,
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning,', style: AppTheme.secondaryTextStyle),
              SizedBox(height: 2),
              Text('Ravi Kumar 👋', style: AppTheme.greetingTitle),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => _openPage(const HelpSupportPage()),
          tooltip: 'Help and support',
          icon: const Icon(Icons.support_agent_rounded),
        ),
      ],
    );
  }

  Widget _buildOnlineCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (_isOnline ? AppTheme.success : AppTheme.error)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isOnline ? Icons.wifi : Icons.wifi_off,
                color: _isOnline ? AppTheme.success : AppTheme.error,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline ? 'You are online' : 'You are offline',
                    style: AppTheme.cardTitle,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _isOnline
                        ? 'Ready to receive deliveries'
                        : 'Go online to receive orders',
                    style: AppTheme.secondaryTextStyle,
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _isOnline,
              activeTrackColor: AppTheme.success,
              onChanged: (value) => setState(() => _isOnline = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return InkWell(
      onTap: () => _openPage(const EarningsPage()),
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryText,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.onDarkSurface,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "Today's earnings",
                  style: TextStyle(color: AppTheme.onDarkSurface),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_outward_rounded,
                  color: AppTheme.onDarkSurface,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '₹ 1,250.00',
              style: TextStyle(
                color: AppTheme.surface,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 15),
            Container(height: 1, color: AppTheme.darkDivider),
            const SizedBox(height: 13),
            const Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  color: AppTheme.onDarkSurface,
                  size: 17,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '5 deliveries completed',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.onDarkSurface),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '+ ₹ 150 bonus',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.bonus),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return Row(
      children: const [
        Expanded(
          child: _OverviewTile(
            icon: Icons.check_circle_outline,
            value: '5',
            label: 'Completed',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _OverviewTile(
            icon: Icons.timer_outlined,
            value: '3h 40m',
            label: 'Active time',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _OverviewTile(
            icon: Icons.star_outline_rounded,
            value: '4.9',
            label: 'Rating',
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryCard() {
    return Card(
      child: InkWell(
        onTap: () => _openPage(const DeliveryPage()),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const StatusBadge(label: 'NEW ORDER'),
                  const Spacer(),
                  const Text('2.4 km away', style: AppTheme.secondaryTextStyle),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.secondaryText,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _PlaceRow(
                icon: Icons.storefront_outlined,
                color: AppTheme.brand,
                title: 'Fresh Basket Supermarket',
                subtitle: 'Pickup · 12 Market Road',
              ),
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 1,
                    height: 17,
                    color: AppTheme.divider,
                  ),
                ),
              ),
              const _PlaceRow(
                icon: Icons.location_on_outlined,
                color: AppTheme.success,
                title: 'Ananya Reddy',
                subtitle: 'Drop-off · 8 Lake View Colony',
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Est. payout', style: AppTheme.secondaryTextStyle),
                      SizedBox(width: 7),
                      Text(
                        '₹ 85',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  FilledButton(
                    onPressed: () => _openPage(const DeliveryPage()),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('View order'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLinks() {
    return Row(
      children: [
        Expanded(
          child: _QuickLink(
            icon: Icons.tune_rounded,
            label: 'Preferences',
            onTap: () => _openPage(const SettingsPage()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickLink(
            icon: Icons.help_outline_rounded,
            label: 'Get help',
            onTap: () => _openPage(const HelpSupportPage()),
          ),
        ),
      ],
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.brand, size: 19),
            const SizedBox(height: 8),
            Text(value, style: AppTheme.cardTitle.copyWith(fontSize: 15)),
            const SizedBox(height: 3),
            Text(label, style: AppTheme.smallStatus),
          ],
        ),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(subtitle, style: AppTheme.smallStatus),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.brand, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.smallStatus.copyWith(
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.secondaryText,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
