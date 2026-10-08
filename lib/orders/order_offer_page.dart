import 'package:flutter/material.dart';

import '../core/state/order_offer_store.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_badge.dart';
import '../delivery/delivery_page.dart';

class OrderOfferPage extends StatelessWidget {
  const OrderOfferPage({required this.offerStore, super.key});

  final OrderOfferStore offerStore;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: offerStore,
      builder: (context, child) {
        final status = offerStore.status;
        final isOffline = !offerStore.availabilityStore.isAvailable;
        final activeDelivery = offerStore.activeDelivery;
        final appBarTitle = activeDelivery != null
            ? 'Active Delivery'
            : isOffline
            ? 'Orders'
            : status == OrderOfferStatus.available
            ? 'New Delivery Offer'
            : 'Delivery Offers';

        return Scaffold(
          appBar: AppBar(title: Text(appBarTitle)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                if (activeDelivery != null)
                  _buildNotice(
                    icon: Icons.delivery_dining_rounded,
                    title: "You're currently delivering",
                    message:
                        'Complete your current delivery to receive new offers.',
                    color: AppTheme.warning,
                  )
                else if (isOffline)
                  _buildNotice(
                    icon: Icons.wifi_off_rounded,
                    title: "You're offline",
                    message: 'Go online to receive delivery offers.',
                    color: AppTheme.error,
                  )
                else if (status == OrderOfferStatus.available)
                  _buildOffer(context)
                else
                  _buildEndState(context, status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOffer(BuildContext context) {
    final delivery = offerStore.offer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'New Delivery Offer',
                        style: AppTheme.sectionTitle,
                      ),
                    ),
                    StatusBadge(
                      label: '${offerStore.secondsRemaining}s',
                      color: offerStore.secondsRemaining <= 5
                          ? AppTheme.error
                          : AppTheme.brand,
                      backgroundColor: offerStore.secondsRemaining <= 5
                          ? AppTheme.brandSoft
                          : AppTheme.brandSoft,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(delivery.orderId, style: AppTheme.secondaryTextStyle),
                const SizedBox(height: 18),
                _OfferDetail(
                  icon: Icons.storefront_outlined,
                  label: 'Store',
                  value: delivery.store,
                ),
                const SizedBox(height: 14),
                _OfferDetail(
                  icon: Icons.store_mall_directory_outlined,
                  label: 'Pickup',
                  value: delivery.pickup,
                  distance: '${delivery.pickupDistanceKm} km away',
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: SizedBox(
                    height: 18,
                    child: VerticalDivider(color: AppTheme.divider, width: 1),
                  ),
                ),
                _OfferDetail(
                  icon: Icons.person_outline_rounded,
                  label: 'Customer',
                  value: delivery.customer,
                ),
                const SizedBox(height: 14),
                _OfferDetail(
                  icon: Icons.location_on_outlined,
                  label: 'Drop',
                  value: delivery.drop,
                  distance: '${delivery.deliveryDistanceKm} km',
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  children: [
                    _OfferMetric(
                      icon: Icons.route_outlined,
                      label: 'Total distance',
                      value: '${delivery.distanceKm.toStringAsFixed(1)} km',
                    ),
                    _OfferMetric(
                      icon: Icons.two_wheeler_outlined,
                      label: 'Vehicle',
                      value: delivery.vehicle,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.successSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Estimated payout',
                          style: AppTheme.secondaryTextStyle,
                        ),
                      ),
                      Text(
                        '₹${delivery.payout}',
                        style: AppTheme.sectionTitle.copyWith(
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: offerStore.canAccept
                    ? () {
                        offerStore.rejectOffer();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Offer rejected')),
                        );
                      }
                    : null,
                child: const Text('REJECT'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: offerStore.canAccept
                    ? () {
                        if (!offerStore.acceptOffer()) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Offer accepted')),
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DeliveryPage(delivery: delivery),
                          ),
                        );
                      }
                    : null,
                child: const Text('ACCEPT'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEndState(BuildContext context, OrderOfferStatus status) {
    final isExpired = status == OrderOfferStatus.expired;
    final title = switch (status) {
      OrderOfferStatus.accepted => 'Offer accepted',
      OrderOfferStatus.rejected => 'Offer rejected',
      OrderOfferStatus.expired => 'Offer expired',
      _ => 'No offer available',
    };
    final message = isExpired
        ? 'No longer available'
        : status == OrderOfferStatus.accepted
        ? 'Your delivery is now active.'
        : 'You remain online and can receive another demo offer.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNotice(
          icon: isExpired ? Icons.timer_off_outlined : Icons.info_outline,
          title: title,
          message: message,
          color: isExpired ? AppTheme.error : AppTheme.secondaryText,
        ),
        if (status == OrderOfferStatus.rejected || isExpired) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed:
                offerStore.availabilityStore.isAvailable && !offerStore.isBusy
                ? () => offerStore.showAnotherDemoOffer()
                : null,
            child: const Text('Show another demo offer'),
          ),
        ],
      ],
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.cardTitle.copyWith(color: color)),
                  const SizedBox(height: 5),
                  Text(message, style: AppTheme.secondaryTextStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferDetail extends StatelessWidget {
  const _OfferDetail({
    required this.icon,
    required this.label,
    required this.value,
    this.distance,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? distance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.brand, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.smallStatus),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (distance != null) ...[
          const SizedBox(width: 8),
          Text(distance!, style: AppTheme.smallStatus),
        ],
      ],
    );
  }
}

class _OfferMetric extends StatelessWidget {
  const _OfferMetric({
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.secondaryText, size: 19),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.smallStatus),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}
