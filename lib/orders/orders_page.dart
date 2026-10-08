import 'package:flutter/material.dart';

import '../core/state/availability_store.dart';
import '../core/state/order_offer_store.dart';
import '../core/models/demo_delivery.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_badge.dart';
import '../delivery/delivery_page.dart';
import 'order_offer_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({
    required this.availabilityStore,
    required this.offerStore,
    super.key,
  });

  final AvailabilityStore availabilityStore;
  final OrderOfferStore offerStore;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: offerStore,
      builder: (context, child) {
        final activeDelivery = offerStore.activeDelivery;

        return Scaffold(
          appBar: AppBar(title: const Text('Orders')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (activeDelivery != null)
                _buildCurrentlyDelivering(context, activeDelivery)
              else if (!availabilityStore.isAvailable)
                _buildOfflineState()
              else if (offerStore.canShowOffer)
                _buildAvailableOffer(context)
              else
                _buildNoOfferState(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentlyDelivering(
    BuildContext context,
    DemoDelivery delivery,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You're currently delivering",
              style: AppTheme.cardTitle,
            ),
            const SizedBox(height: 5),
            const Text(
              'Complete your current delivery to receive new offers.',
              style: AppTheme.secondaryTextStyle,
            ),
            if (!availabilityStore.isAvailable) ...[
              const SizedBox(height: 8),
              const Text(
                "You're offline; your current delivery remains active.",
                style: AppTheme.secondaryTextStyle,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '${delivery.orderId} · ${delivery.store}',
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Status: ${offerStore.activeDeliveryStatus}',
              style: AppTheme.secondaryTextStyle,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final completed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => DeliveryPage(
                        delivery: delivery,
                        offerStore: offerStore,
                      ),
                    ),
                  );
                  if (!context.mounted) return;
                  if (completed == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delivery marked complete')),
                    );
                  }
                },
                child: const Text('View active delivery'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineState() {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.wifi_off_rounded, color: AppTheme.error),
        title: Text("You're offline"),
        subtitle: Text('Go online to receive delivery offers.'),
      ),
    );
  }

  Widget _buildAvailableOffer(BuildContext context) {
    final delivery = offerStore.offer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('New Delivery Offer', style: AppTheme.cardTitle),
                ),
                const SizedBox(width: 8),
                StatusBadge(label: '${offerStore.secondsRemaining}s'),
              ],
            ),
            const SizedBox(height: 8),
            Text(delivery.orderId, style: AppTheme.secondaryTextStyle),
            const SizedBox(height: 14),
            Text(
              delivery.store,
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              'Pickup · ${delivery.pickup}  •  Drop · ${delivery.drop}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.secondaryTextStyle,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                Text(
                  '${delivery.distanceKm.toStringAsFixed(1)} km',
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '₹${delivery.payout}',
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(delivery.vehicle, style: AppTheme.secondaryTextStyle),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderOfferPage(offerStore: offerStore),
                  ),
                ),
                child: const Text('View offer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOfferState(BuildContext context) {
    final isExpired = offerStore.status == OrderOfferStatus.expired;
    final wasRejected = offerStore.status == OrderOfferStatus.rejected;
    final title = isExpired
        ? 'Offer expired'
        : wasRejected
        ? 'Offer rejected'
        : 'Ready for delivery offers';
    final message = isExpired
        ? 'No longer available'
        : wasRejected
        ? 'You remain online and can receive another demo offer.'
        : 'Stay online to receive nearby delivery offers.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.cardTitle),
            const SizedBox(height: 5),
            Text(message, style: AppTheme.secondaryTextStyle),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                if (offerStore.showAnotherDemoOffer()) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OrderOfferPage(offerStore: offerStore),
                    ),
                  );
                }
              },
              child: const Text('Check for demo offer'),
            ),
          ],
        ),
      ),
    );
  }
}
