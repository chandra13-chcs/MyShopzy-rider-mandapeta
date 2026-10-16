import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../core/models/demo_delivery.dart';
import '../core/state/order_offer_store.dart';
import '../core/widgets/status_badge.dart';
import '../orders/rider_map_view.dart';

class DeliveryPage extends StatelessWidget {
  const DeliveryPage({
    this.delivery = DemoDelivery.batchThreeActive,
    this.offerStore,
    this.showMapTiles = true,
    super.key,
  });

  final DemoDelivery delivery;
  final OrderOfferStore? offerStore;
  final bool showMapTiles;

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
            'Grocery delivery · ${delivery.totalDistanceLabel}',
            style: AppTheme.secondaryTextStyle,
          ),
          const SizedBox(height: 20),
          if (store != null && store.queuedOrderStatusCount > 0) ...[
            _SyncPendingNotice(count: store.queuedOrderStatusCount),
            const SizedBox(height: 12),
          ],
          if (isActive) ...[
            _RouteMapCard(
              delivery: delivery,
              riderPosition: store?.availabilityStore.lastPosition,
              showMapTiles: showMapTiles,
            ),
            const SizedBox(height: 12),
          ],
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () => _openNavigation(
                context,
                delivery.pickup,
                delivery.pickupLatitude,
                delivery.pickupLongitude,
              ),
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Navigate to Store'),
            ),
            if (_phoneUri(delivery.storePhone) case final storePhoneUri?) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openContact(context, storePhoneUri),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Call Store'),
              ),
            ],
            const SizedBox(height: 8),
            _primaryAction('Reached Store', () => store.reachStore(delivery)),
          ],
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
              () => _runOrderTransition(
                context,
                () => store.startDelivery(delivery),
              ),
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
            _buildCustomerDeliverySummary(context),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openNavigation(
                context,
                delivery.drop,
                delivery.dropLatitude,
                delivery.dropLongitude,
              ),
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Navigate to Customer'),
            ),
            const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                _customerContactActions(context),
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

  Widget _buildCustomerDeliverySummary(BuildContext context) {
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
                  '${delivery.deliveryDistanceLabel}',
                ),
                const SizedBox(height: 4),
                Text('Payout: ₹${delivery.payout}'),
                const SizedBox(height: 12),
                _customerContactActions(context),
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
    final completed = await store.completeDelivery(delivery);
    if (!context.mounted) return;
    if (!completed) {
      final message =
          store.errorMessage ?? 'Unable to complete this delivery yet.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(true);
    }
  }

  Future<void> _runOrderTransition(
    BuildContext context,
    Future<bool> Function() transition,
  ) async {
    final completed = await transition();
    if (!context.mounted || completed) return;
    final message =
        offerStore?.errorMessage ?? 'Unable to update this order status.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _customerContactActions(BuildContext context) {
    final phone = delivery.customerPhone;
    final phoneUri = _phoneUri(phone);
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: phoneUri == null
              ? null
              : () => _openContact(context, phoneUri),
          icon: const Icon(Icons.call_outlined),
          label: const Text('Call'),
        ),
        OutlinedButton.icon(
          onPressed: phoneUri == null
              ? null
              : () => _openContact(
                  context,
                  Uri(scheme: 'sms', path: phoneUri.path),
                ),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Chat'),
        ),
      ],
    );
  }

  static Uri? _phoneUri(String? phone) {
    if (phone == null) return null;
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!RegExp(r'^\+?\d{5,15}$').hasMatch(normalized)) return null;
    return Uri(scheme: 'tel', path: normalized);
  }

  Future<void> _openNavigation(
    BuildContext context,
    String address,
    double? latitude,
    double? longitude,
  ) async {
    final destination = latitude != null && longitude != null
        ? '$latitude,$longitude'
        : address;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    });
    await _openContact(context, uri);
  }

  Future<void> _openContact(BuildContext context, Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('No application can open this link.');
      }
    } on Object catch (error) {
      if (!context.mounted) return;
      final message = error is StateError
          ? 'Unable to open the selected navigation or contact app.'
          : 'Unable to open the selected navigation or contact app.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _primaryAction(String label, VoidCallback onPressed) {
    return FilledButton(
      onPressed: offerStore?.isUpdatingOrderStatus == true ? null : onPressed,
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

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final store = widget.offerStore;
    final confirmed = store.apiClient == null
        ? store.verifyPickup(widget.delivery, _digitsController.text)
        : await store.confirmPickup(widget.delivery, _digitsController.text);
    if (!mounted) return;
    if (confirmed) {
      return;
    }

    setState(
      () => _verificationError =
          store.errorMessage ?? 'Those digits do not match the order.',
    );
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
                onPressed: widget.offerStore.isUpdatingOrderStatus
                    ? null
                    : _verify,
                child: widget.offerStore.isUpdatingOrderStatus
                    ? const Text('Updating...')
                    : const Text('Verify Pickup'),
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

class _RouteMapCard extends StatelessWidget {
  const _RouteMapCard({
    required this.delivery,
    required this.riderPosition,
    required this.showMapTiles,
  });

  final DemoDelivery delivery;
  final Position? riderPosition;
  final bool showMapTiles;

  @override
  Widget build(BuildContext context) {
    final routePoints = <LatLng>[
      if (delivery.pickupLatitude != null && delivery.pickupLongitude != null)
        LatLng(delivery.pickupLatitude!, delivery.pickupLongitude!),
      if (delivery.dropLatitude != null && delivery.dropLongitude != null)
        LatLng(delivery.dropLatitude!, delivery.dropLongitude!),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.route_rounded, color: AppTheme.brand),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Live route', style: AppTheme.cardTitle),
                ),
                Text(
                  riderPosition == null ? 'Locating rider...' : 'Live tracking',
                  style: AppTheme.smallStatus,
                ),
              ],
            ),
          ),
          if (routePoints.length >= 2)
            RiderMapView(
              key: const ValueKey('delivery-route-map'),
              riderLocation: riderPosition == null
                  ? null
                  : LatLng(riderPosition!.latitude, riderPosition!.longitude),
              showCurrentLocation: riderPosition == null,
              pickupLocation: routePoints.first,
              dropoffLocation: routePoints.last,
              showTiles: showMapTiles,
              height: 240,
            )
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Text(
                'Route map is unavailable because store or customer coordinates are missing.',
                style: AppTheme.secondaryTextStyle,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                if (riderPosition != null)
                  const _RouteLegendItem(label: 'Rider', color: AppTheme.brand),
                if (delivery.pickupLatitude != null &&
                    delivery.pickupLongitude != null)
                  const _RouteLegendItem(label: 'Store', color: AppTheme.brand),
                if (delivery.dropLatitude != null &&
                    delivery.dropLongitude != null)
                  const _RouteLegendItem(
                    label: 'Drop-off',
                    color: AppTheme.brandYellow,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLegendItem extends StatelessWidget {
  const _RouteLegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: AppTheme.smallStatus),
    ],
  );
}

class _SyncPendingNotice extends StatelessWidget {
  const _SyncPendingNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Card(
    color: AppTheme.brandSoft,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.sync_rounded, color: AppTheme.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count order update${count == 1 ? '' : 's'} saved offline. '
              'They will sync when your connection returns.',
              style: AppTheme.bodyText,
            ),
          ),
        ],
      ),
    ),
  );
}
