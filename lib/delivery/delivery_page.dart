import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/models/demo_delivery.dart';
import '../core/state/order_offer_store.dart';
import '../core/widgets/status_badge.dart';

class DeliveryPage extends StatelessWidget {
  const DeliveryPage({
    this.delivery = DemoDelivery.batchThreeActive,
    this.offerStore,
    super.key,
  });

  final DemoDelivery delivery;
  final OrderOfferStore? offerStore;

  @override
  Widget build(BuildContext context) {
    final store = offerStore;
    if (store == null) return _buildPage(context, null, null);

    return AnimatedBuilder(
      animation: store,
      builder: (context, child) => _buildPage(
        context,
        store.activeDelivery?.orderId == delivery.orderId
            ? store.pickupStatus
            : null,
        store.activeDelivery?.orderId == delivery.orderId
            ? store.deliveryStatus
            : null,
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    PickupStatus? pickupStatus,
    DeliveryStatus? deliveryStatus,
  ) {
    final store = offerStore;
    final isActive = store?.activeDelivery?.orderId == delivery.orderId;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (pickupStatus == PickupStatus.goingToPickup)
            _buildPickupNavigationCard(context, store!)
          else
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: AppTheme.mapSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 48, color: AppTheme.success),
                    SizedBox(height: 8),
                    Text('Route preview', style: AppTheme.secondaryTextStyle),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text('Order ${delivery.orderId}', style: AppTheme.screenTitle),
          const SizedBox(height: 5),
          Text(
            'Grocery delivery · ${delivery.distanceKm.toStringAsFixed(1)} km',
            style: AppTheme.secondaryTextStyle,
          ),
          const SizedBox(height: 20),
          if (pickupStatus != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delivery_dining_rounded,
                      color: AppTheme.brand,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Delivery status', style: AppTheme.cardTitle),
                    ),
                    StatusBadge(label: store!.activeDeliveryStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _StopCard(
            step: '1',
            title: 'Pickup from store',
            place: delivery.store,
            address: '${delivery.pickup}, Mandapeta',
            distance: delivery.pickupDistanceKm == null
                ? null
                : '${delivery.pickupDistanceKm!.toStringAsFixed(1)} km away',
          ),
          const SizedBox(height: 12),
          _StopCard(
            step: '2',
            title: 'Deliver to customer',
            place: delivery.customer,
            address: '${delivery.drop}, Mandapeta',
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: AppTheme.brand),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Your estimated payout')),
                  Text(
                    '₹ ${delivery.payout}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!isActive)
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo order accepted')),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Accept delivery'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            )
          else
            _buildActiveActions(
              context,
              store!,
              pickupStatus!,
              deliveryStatus!,
            ),
        ],
      ),
    );
  }

  Widget _buildActiveActions(
    BuildContext context,
    OrderOfferStore store,
    PickupStatus pickupStatus,
    DeliveryStatus deliveryStatus,
  ) {
    switch (pickupStatus) {
      case PickupStatus.goingToPickup:
        return _primaryAction(
          'Reached Store',
          () => store.reachStore(delivery),
        );
      case PickupStatus.reachedPickup:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text("You're at the pickup location."),
              ),
            ),
            const SizedBox(height: 12),
            _primaryAction(
              'View Order Details',
              () => store.openOrderDetails(delivery),
            ),
          ],
        );
      case PickupStatus.orderDetails:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Order Details', style: AppTheme.cardTitle),
                const SizedBox(height: 6),
                const Text('Verify the order before pickup.'),
                const SizedBox(height: 14),
                Text('Order ${delivery.orderId}'),
                const SizedBox(height: 6),
                Text('Store: ${delivery.store}'),
                const SizedBox(height: 6),
                const Text('Items:'),
                const SizedBox(height: 4),
                const Text('2 × Chicken Biryani'),
                const Text('1 × Coke'),
                const SizedBox(height: 16),
                _primaryAction(
                  'Verify Pickup',
                  () => store.beginPickupVerification(delivery),
                ),
              ],
            ),
          ),
        );
      case PickupStatus.pickupVerification:
        return _PickupVerificationForm(delivery: delivery, offerStore: store);
      case PickupStatus.pickedUp:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Pickup Verified'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ${delivery.orderId}'),
                    const SizedBox(height: 6),
                    Text('Store: ${delivery.store}'),
                    const SizedBox(height: 8),
                    Text(
                      '${delivery.store} → ${delivery.drop}',
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Delivery distance: '
                      '${(delivery.deliveryDistanceKm ?? delivery.distanceKm).toStringAsFixed(1)} km',
                    ),
                    const SizedBox(height: 4),
                    Text('Payout: ₹${delivery.payout}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _primaryAction(
              'Continue to Customer',
              () => store.continueToDelivery(delivery),
            ),
          ],
        );
      case PickupStatus.onTheWay:
        return _buildDeliveryActions(context, store, deliveryStatus);
    }
  }

  Widget _buildPickupNavigationCard(
    BuildContext context,
    OrderOfferStore store,
  ) {
    return Card(
      color: AppTheme.mapSurface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.navigation_outlined, color: AppTheme.brand),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Pickup Location', style: AppTheme.cardTitle),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              delivery.pickup,
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${delivery.pickupDistanceKm?.toStringAsFixed(1) ?? '1.8'} km away',
              style: AppTheme.secondaryTextStyle,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigation started')),
                ),
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Navigate to Pickup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryActions(
    BuildContext context,
    OrderOfferStore store,
    DeliveryStatus status,
  ) {
    switch (status) {
      case DeliveryStatus.onTheWay:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCustomerDeliverySummary(),
            const SizedBox(height: 12),
            _primaryAction(
              'Arriving at Customer',
              () => store.arriveAtCustomer(delivery),
            ),
          ],
        );
      case DeliveryStatus.arriving:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCustomerDeliverySummary(
              message: 'You are arriving at the delivery location.',
            ),
            const SizedBox(height: 12),
            _primaryAction(
              'Start Delivery Confirmation',
              () => store.startDeliveryConfirmation(delivery),
            ),
          ],
        );
      case DeliveryStatus.confirmingDelivery:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Confirm Delivery', style: AppTheme.cardTitle),
                const SizedBox(height: 14),
                Text('Order: ${delivery.orderId}'),
                const SizedBox(height: 6),
                Text('Customer: ${delivery.customer}'),
                const SizedBox(height: 6),
                Text('Drop: ${delivery.drop}'),
                const SizedBox(height: 6),
                Text('Payout: ₹${delivery.payout}'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _completeDelivery(context, store),
                  child: const Text('Confirm Delivery'),
                ),
              ],
            ),
          ),
        );
      case DeliveryStatus.delivered:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCustomerDeliverySummary({String? message}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(message),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer: ${delivery.customer}',
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Drop: ${delivery.drop}'),
                const SizedBox(height: 6),
                Text(
                  'Delivery distance: '
                  '${(delivery.deliveryDistanceKm ?? delivery.distanceKm).toStringAsFixed(1)} km',
                ),
                const SizedBox(height: 4),
                Text('Payout: ₹${delivery.payout}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _completeDelivery(
    BuildContext context,
    OrderOfferStore store,
  ) async {
    if (!store.completeActiveDelivery(delivery)) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delivered'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Delivery completed successfully.'),
              const SizedBox(height: 12),
              Text('Order ${delivery.orderId}'),
              const SizedBox(height: 8),
              Text('Customer: ${delivery.customer}'),
              const SizedBox(height: 6),
              Text('Drop: ${delivery.drop}'),
              const SizedBox(height: 6),
              Text('Payout: ₹${delivery.payout}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    Navigator.of(context).pop(true);
  }

  Widget _primaryAction(String label, VoidCallback onPressed) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: Text(label),
    );
  }
}

class _PickupVerificationForm extends StatefulWidget {
  const _PickupVerificationForm({
    required this.delivery,
    required this.offerStore,
  });

  final DemoDelivery delivery;
  final OrderOfferStore offerStore;

  @override
  State<_PickupVerificationForm> createState() =>
      _PickupVerificationFormState();
}

class _PickupVerificationFormState extends State<_PickupVerificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _digitsController = TextEditingController();
  String? _verificationError;

  @override
  void dispose() {
    _digitsController.dispose();
    super.dispose();
  }

  void _verify() {
    if (!_formKey.currentState!.validate()) return;
    if (widget.offerStore.verifyPickup(
      widget.delivery,
      _digitsController.text,
    )) {
      return;
    }

    setState(() => _verificationError = 'Those digits do not match the order.');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Confirm Pickup', style: AppTheme.cardTitle),
              const SizedBox(height: 6),
              const Text('Enter the last 4 digits of the Order ID.'),
              const SizedBox(height: 14),
              TextFormField(
                controller: _digitsController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  labelText: 'Last 4 digits',
                  hintText: '2051',
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter the last 4 digits.';
                  }
                  if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                    return 'Enter exactly 4 digits.';
                  }
                  return null;
                },
                onChanged: (_) {
                  if (_verificationError != null) {
                    setState(() => _verificationError = null);
                  }
                },
              ),
              if (_verificationError case final error?) ...[
                const SizedBox(height: 4),
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _verify,
                child: const Text('Verify Pickup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.step,
    required this.title,
    required this.place,
    required this.address,
    this.distance,
  });

  final String step;
  final String title;
  final String place;
  final String address;
  final String? distance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.brandSoft,
              foregroundColor: AppTheme.brand,
              child: Text(
                step,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.secondaryTextStyle),
                  const SizedBox(height: 5),
                  Text(
                    place,
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(address, style: AppTheme.secondaryTextStyle),
                  if (distance case final pickupDistance?) ...[
                    const SizedBox(height: 4),
                    Text(pickupDistance, style: AppTheme.secondaryTextStyle),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
