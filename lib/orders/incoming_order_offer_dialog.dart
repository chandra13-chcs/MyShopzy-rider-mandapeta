import 'package:flutter/material.dart';

import '../core/models/demo_delivery.dart';
import '../core/state/order_offer_store.dart';
import '../core/theme/app_theme.dart';

class IncomingOrderOfferDialog extends StatelessWidget {
  const IncomingOrderOfferDialog({required this.offerStore, super.key});

  final OrderOfferStore offerStore;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: offerStore,
      builder: (context, child) {
        final delivery = offerStore.offer;
        if (delivery == null) return const SizedBox.shrink();
        final size = MediaQuery.sizeOf(context);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          backgroundColor: AppTheme.surface,
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: size.height * 0.92,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RouteHeader(delivery: delivery),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.brand,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NEW ORDER',
                          style: TextStyle(
                            color: AppTheme.brandYellow,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: offerStore.secondsRemaining <= 5
                            ? AppTheme.error
                            : AppTheme.brand,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${offerStore.secondsRemaining}s',
                        style: TextStyle(
                          color: offerStore.secondsRemaining <= 5
                              ? AppTheme.error
                              : AppTheme.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          delivery.orderId,
                          style: AppTheme.secondaryTextStyle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${delivery.calculatedPayout}',
                          style: const TextStyle(
                            color: AppTheme.brand,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Estimated earnings',
                          style: AppTheme.secondaryTextStyle,
                        ),
                        const SizedBox(height: 12),
                        _LocationPanel(delivery: delivery),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _DistancePill(
                              label: 'Pickup',
                              value: _formatDistance(delivery.pickupDistanceKm),
                            ),
                            _DistancePill(
                              label: 'Delivery',
                              value: _formatDistance(
                                delivery.hasRouteEstimate
                                    ? delivery.effectiveDeliveryDistance
                                    : null,
                              ),
                            ),
                            _DistancePill(
                              label: 'Total',
                              value: _formatDistance(
                                delivery.hasRouteEstimate
                                    ? delivery.distanceKm
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Payout: ${delivery.payoutBreakdown}',
                          style: AppTheme.secondaryTextStyle,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Arrival estimate unavailable',
                          style: AppTheme.secondaryTextStyle,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('incoming-order-reject'),
                          onPressed: offerStore.canAccept
                              ? () => _reject(context)
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            minimumSize: const Size(48, 48),
                          ),
                          child: const Text('REJECT'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          key: const ValueKey('incoming-order-accept'),
                          onPressed: offerStore.canAccept
                              ? () => _accept(context)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.brand,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(48, 52),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          child: const Text('ACCEPT ORDER'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _accept(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final accepted = await offerStore.acceptAvailableOffer();
    if (!context.mounted) return;
    if (accepted) {
      navigator.pop(true);
    } else if (context.mounted && offerStore.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(offerStore.errorMessage!)));
    }
  }

  void _reject(BuildContext context) {
    if (offerStore.rejectOffer()) {
      Navigator.of(context).pop(false);
    }
  }
}

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.delivery});

  final DemoDelivery delivery;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      width: double.infinity,
      color: AppTheme.lightGreenSurface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PICKUP  →  DROP',
            style: TextStyle(
              color: AppTheme.brand,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: AppTheme.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  delivery.pickup,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.more_horiz_rounded,
                color: AppTheme.secondaryText,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.location_on_rounded, color: AppTheme.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  delivery.drop,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationPanel extends StatelessWidget {
  const _LocationPanel({required this.delivery});

  final DemoDelivery delivery;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Column(
              children: [
                Icon(Icons.storefront_rounded, size: 19, color: AppTheme.brand),
                SizedBox(height: 5),
                SizedBox(
                  height: 18,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppTheme.divider,
                  ),
                ),
                SizedBox(height: 5),
                Icon(
                  Icons.location_on_rounded,
                  size: 19,
                  color: AppTheme.brand,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PICK UP FROM', style: AppTheme.smallStatus),
                  const SizedBox(height: 2),
                  Text(
                    delivery.store,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.cardTitle,
                  ),
                  Text(
                    delivery.pickup,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.secondaryTextStyle,
                  ),
                  const SizedBox(height: 10),
                  const Text('DELIVER TO', style: AppTheme.smallStatus),
                  const SizedBox(height: 2),
                  Text(
                    delivery.customer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.cardTitle,
                  ),
                  Text(
                    delivery.drop,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
}

class _DistancePill extends StatelessWidget {
  const _DistancePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.lightGreenSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label · $value',
        style: const TextStyle(
          color: AppTheme.brand,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatDistance(double? distance) =>
    distance == null ? 'Not provided' : '${distance.toStringAsFixed(1)} km';
