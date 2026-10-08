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
        store.activeDelivery?.orderId == delivery.orderId ||
                store.deliveryStatus == DeliveryStatus.delivered
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
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
          if (!isActive && deliveryStatus == DeliveryStatus.delivered)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('Delivery completed successfully.'),
              ),
            )
          else if (!isActive)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('This delivery is not active.'),
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
        return _primaryAction('Order Details', () {
          store.openOrderDetails(delivery);
        });
      case PickupStatus.orderDetails:
        return _PickupVerificationForm(delivery: delivery, offerStore: store);
      case PickupStatus.pickedUp:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Pickup Confirmed'),
              ),
            ),
            const SizedBox(height: 12),
            _primaryAction(
              'Start Delivery',
              () => store.continueToDelivery(delivery),
            ),
          ],
        );
      case PickupStatus.onTheWay:
        return _buildDeliveryActions(context, store, deliveryStatus);
    }
  }

  Widget _buildDeliveryActions(
    BuildContext context,
    OrderOfferStore store,
    DeliveryStatus status,
  ) {
    switch (status) {
      case DeliveryStatus.goingToCustomer:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCustomerDeliverySummary(),
            const SizedBox(height: 12),
            _primaryAction(
              'Reached Customer',
              () => store.arriveAtCustomer(delivery),
            ),
          ],
        );
      case DeliveryStatus.reachedCustomer:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Customer & Order Details',
                  style: AppTheme.cardTitle,
                ),
                const SizedBox(height: 14),
                Text('Order: ${delivery.orderId}'),
                const SizedBox(height: 6),
                Text('Customer: ${delivery.customer}'),
                const SizedBox(height: 6),
                Text('Drop: ${delivery.drop}'),
                const SizedBox(height: 6),
                Text('Payout: ₹${delivery.payout}'),
                const SizedBox(height: 16),
                _primaryAction(
                  'Hand Over',
                  () => store.handOverOrder(delivery),
                ),
              ],
            ),
          ),
        );
      case DeliveryStatus.handOver:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Hand Over', style: AppTheme.cardTitle),
                const SizedBox(height: 8),
                Text(
                  'Order ${delivery.orderId} is ready to be marked delivered.',
                ),
                const SizedBox(height: 16),
                _primaryAction(
                  'Mark Delivered',
                  () => _completeDelivery(context, store),
                ),
              ],
            ),
          ),
        );
      case DeliveryStatus.delivered:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCustomerDeliverySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

  void _completeDelivery(BuildContext context, OrderOfferStore store) {
    if (!store.completeActiveDelivery(delivery)) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(true);
    }
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
              const Text('Order Details', style: AppTheme.cardTitle),
              const SizedBox(height: 6),
              Text('Store: ${widget.delivery.store}'),
              const SizedBox(height: 6),
              Text('Order: ${widget.delivery.orderId}'),
              const SizedBox(height: 6),
              const Text('Enter the last 4 digits to confirm pickup.'),
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
