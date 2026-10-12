import 'package:flutter/material.dart';

import '../core/state/availability_store.dart';
import '../core/state/order_offer_store.dart';
import '../core/models/demo_delivery.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/section_title.dart';
import '../core/widgets/status_badge.dart';
import '../delivery/delivery_page.dart';
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
                    const SizedBox(height: 22),
                    SectionTitle(title: "Today's summary"),
                    const SizedBox(height: 10),
                    _buildDailySummary(),
                    const SizedBox(height: 22),
                    if (delivery case final activeDelivery?) ...[
                      SectionTitle(title: 'Current Delivery'),
                      const SizedBox(height: 10),
                      _buildActiveDelivery(activeDelivery),
                    ] else if (widget.offerStore.canShowOffer) ...[
                      const SectionTitle(title: 'New Order'),
                      const SizedBox(height: 10),
                      _buildNewOrder(),
                    ] else
                      _buildWaitingState(),
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
        SizedBox(
          width: 110,
          height: 36,
          child: Row(
            children: [
              Image.asset(
                'assets/sounds/logo.png',
                fit: BoxFit.contain,
                width: 36,
                height: 36,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'MyShopzy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.darkGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.demoData.greeting,
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.demoData.riderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Rider ID: ${widget.demoData.riderId}',
                style: AppTheme.secondaryTextStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCard() {
    final isAvailable = widget.availabilityStore.isAvailable;
    final isBusy = widget.offerStore.isBusy;
    final statusColor = isAvailable ? AppTheme.success : AppTheme.error;

    return Card(
      color: isAvailable ? AppTheme.onlineBox : AppTheme.surface,
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

  Widget _buildNewOrder() {
    final offer = widget.offerStore.offer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('New order offer', style: AppTheme.cardTitle),
                ),
                StatusBadge(
                  label: '${widget.offerStore.secondsRemaining}s',
                  color: AppTheme.brand,
                  backgroundColor: AppTheme.brandSoft,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(offer.orderId, style: AppTheme.bodyText),
            const SizedBox(height: 10),
            _OfferSummaryRow(label: 'Store', value: offer.store),
            _OfferSummaryRow(label: 'Pickup', value: offer.pickup),
            _OfferSummaryRow(
              label: 'Pickup distance',
              value:
                  '${offer.pickupDistanceKm?.toStringAsFixed(1) ?? '1.8'} km',
            ),
            _OfferSummaryRow(label: 'Drop', value: offer.drop),
            _OfferSummaryRow(
              label: 'Delivery distance',
              value: '${offer.effectiveDeliveryDistance.toStringAsFixed(1)} km',
            ),
            _OfferSummaryRow(
              label: 'Total distance',
              value: '${offer.distanceKm.toStringAsFixed(1)} km',
            ),
            _OfferSummaryRow(
              label: 'Payout breakdown',
              value: offer.payoutBreakdown,
            ),
            _OfferSummaryRow(
              label: 'Estimated payout',
              value: '₹${offer.calculatedPayout}',
            ),
            _OfferSummaryRow(label: 'Vehicle', value: offer.vehicle),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.offerStore.canAccept
                        ? () => widget.offerStore.rejectOffer()
                        : null,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.offerStore.canAccept
                        ? () => _acceptOffer(offer)
                        : null,
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOffer(DemoDelivery delivery) async {
    if (!widget.offerStore.acceptOffer()) return;
    await _openDeliveryPage(delivery);
  }

  Widget _buildActiveDelivery(DemoDelivery delivery) {
    return Card(
      color: AppTheme.currentDeliveryCard,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  color: AppTheme.brand,
                  backgroundColor: AppTheme.brandSoft,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openDeliveryPage(delivery),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continue Delivery'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.darkGreen,
                  foregroundColor: AppTheme.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingState() {
    final isAvailable = widget.availabilityStore.isAvailable;
    return Card(
      child: ListTile(
        leading: Icon(
          isAvailable ? Icons.hourglass_empty_rounded : Icons.wifi_off_rounded,
          color: isAvailable ? AppTheme.brand : AppTheme.secondaryText,
        ),
        title: Text(
          isAvailable ? 'Waiting for new orders' : "You're offline",
          style: AppTheme.cardTitle,
        ),
        subtitle: Text(
          isAvailable
              ? 'A new order will appear here.'
              : 'Go online to receive new orders.',
          style: AppTheme.secondaryTextStyle,
        ),
      ),
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
      color: AppTheme.summaryCard,
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

class _OfferSummaryRow extends StatelessWidget {
  const _OfferSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 124,
          child: Text(label, style: AppTheme.secondaryTextStyle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: AppTheme.bodyText)),
      ],
    ),
  );
}
