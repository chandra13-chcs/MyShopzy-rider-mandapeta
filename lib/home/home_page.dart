import 'package:flutter/material.dart';

import '../core/state/availability_store.dart';
import '../core/state/order_offer_store.dart';
import '../core/models/demo_delivery.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/section_title.dart';
import '../core/widgets/status_badge.dart';
import '../delivery/delivery_page.dart';
import '../earnings/earnings_page.dart';
import '../help_support/help_support_page.dart';
import '../history/history_page.dart';
import '../orders/orders_page.dart';
import '../orders/order_offer_page.dart';
import 'home_demo_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.availabilityStore,
    required this.offerStore,
    this.demoData = const HomeDemoData(),
    super.key,
  });

  final AvailabilityStore availabilityStore;
  final OrderOfferStore offerStore;
  final HomeDemoData demoData;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _openPage(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _openDeliveryPage(DemoDelivery delivery) async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            DeliveryPage(delivery: delivery, offerStore: widget.offerStore),
      ),
    );
    if (!mounted) return;
    if (completed == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Delivery marked complete')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.offerStore,
      builder: (context, child) {
        final delivery = widget.offerStore.activeDelivery;
        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildAvailabilityCard(),
                    if (widget.offerStore.canShowOffer) ...[
                      const SizedBox(height: 14),
                      _buildCompactOffer(),
                    ],
                    const SizedBox(height: 22),
                    SectionTitle(
                      title: "Today's summary",
                      action: 'Earnings',
                      onAction: () => _openPage(const EarningsPage()),
                    ),
                    const SizedBox(height: 10),
                    _buildDailySummary(),
                    const SizedBox(height: 22),
                    if (delivery case final activeDelivery?) ...[
                      SectionTitle(title: 'Active Delivery'),
                      const SizedBox(height: 10),
                      _buildActiveDelivery(activeDelivery),
                    ] else
                      _buildNoActiveDelivery(),
                    const SizedBox(height: 22),
                    SectionTitle(
                      title: 'Recent Delivery',
                      action: 'History',
                      onAction: () => _openPage(const HistoryPage()),
                    ),
                    const SizedBox(height: 10),
                    _buildRecentDelivery(),
                    const SizedBox(height: 22),
                    const SectionTitle(title: 'Quick actions'),
                    const SizedBox(height: 10),
                    _buildQuickActions(),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.demoData.greeting,
                style: AppTheme.secondaryTextStyle,
              ),
              const SizedBox(height: 2),
              Text(
                widget.demoData.riderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.greetingTitle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () => _openPage(const HelpSupportPage()),
          tooltip: 'Help and support',
          icon: const Icon(Icons.support_agent_rounded),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCard() {
    final isAvailable = widget.availabilityStore.isAvailable;
    final isBusy = widget.offerStore.isBusy;
    final statusColor = isAvailable ? AppTheme.success : AppTheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              isAvailable ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: statusColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAvailable ? "You're online" : "You're offline",
                    style: AppTheme.cardTitle.copyWith(color: statusColor),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isAvailable
                        ? isBusy
                              ? "You're currently delivering; new offers are paused."
                              : "You're ready to receive delivery offers."
                        : "You're not available for new delivery offers.",
                    style: AppTheme.secondaryTextStyle,
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isAvailable,
              activeTrackColor: AppTheme.success,
              onChanged: widget.availabilityStore.setAvailable,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummary() {
    final data = widget.demoData;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Deliveries',
                value: '${data.deliveriesCompleted}',
                detail: 'completed',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.payments_outlined,
                label: "Today's earnings",
                value: '₹${data.todayEarnings}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.route_outlined,
                label: 'Distance',
                value: '${data.distanceKm.toStringAsFixed(1)} km',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.schedule_outlined,
                label: 'Online time',
                value: data.onlineTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactOffer() {
    return Card(
      child: InkWell(
        onTap: () => _openPage(OrderOfferPage(offerStore: widget.offerStore)),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: AppTheme.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Delivery Offer', style: AppTheme.cardTitle),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.offerStore.offer.store} · '
                      '₹${widget.offerStore.offer.payout} · '
                      '${widget.offerStore.secondsRemaining}s left',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.secondaryTextStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppTheme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveDelivery(DemoDelivery delivery) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You're currently delivering",
              style: AppTheme.secondaryTextStyle.copyWith(
                color: AppTheme.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    delivery.orderId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.cardTitle,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: widget.offerStore.activeDeliveryStatus,
                  color: AppTheme.success,
                  backgroundColor: AppTheme.successSoft,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DeliveryDetailRow(
              icon: Icons.storefront_outlined,
              label: 'Store',
              value: delivery.store,
            ),
            const SizedBox(height: 10),
            _DeliveryDetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Customer',
              value: delivery.customer,
            ),
            const SizedBox(height: 10),
            _DeliveryDetailRow(
              icon: Icons.store_mall_directory_outlined,
              label: 'Pickup',
              value: delivery.pickup,
            ),
            const SizedBox(height: 10),
            _DeliveryDetailRow(
              icon: Icons.location_on_outlined,
              label: 'Drop',
              value: delivery.drop,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _InlineMetric(
                  icon: Icons.route_outlined,
                  text: '${delivery.distanceKm.toStringAsFixed(1)} km',
                ),
                _InlineMetric(
                  icon: Icons.payments_outlined,
                  text: '₹${delivery.payout}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openDeliveryPage(delivery),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('View Delivery'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveDelivery() {
    final isAvailable = widget.availabilityStore.isAvailable;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: AppTheme.secondaryText,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No active delivery', style: AppTheme.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    isAvailable
                        ? 'Stay online to receive nearby delivery offers.'
                        : 'Go online when you are ready to receive delivery offers.',
                    style: AppTheme.secondaryTextStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDelivery() {
    final delivery = widget.demoData.recentDelivery;
    return Card(
      child: InkWell(
        onTap: () => _openPage(const DeliveryPage()),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.successSoft,
                child: Icon(Icons.check_rounded, color: AppTheme.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.store,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${delivery.distanceKm.toStringAsFixed(1)} km · Delivered',
                      style: AppTheme.smallStatus,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${delivery.payout}',
                style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppTheme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                onTap: () => _openPage(
                  OrdersPage(
                    availabilityStore: widget.availabilityStore,
                    offerStore: widget.offerStore,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.history_rounded,
                label: 'History',
                onTap: () => _openPage(const HistoryPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Earnings',
                onTap: () => _openPage(const EarningsPage()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () => _openPage(const HelpSupportPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.brand, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.smallStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.cardTitle,
                ),
                if (detail != null) Text(detail!, style: AppTheme.smallStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryDetailRow extends StatelessWidget {
  const _DeliveryDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.secondaryText, size: 19),
        const SizedBox(width: 9),
        SizedBox(width: 68, child: Text(label, style: AppTheme.smallStatus)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.secondaryText, size: 17),
        const SizedBox(width: 5),
        Text(
          text,
          style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
        key: ValueKey('home-action-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.brand, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
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
