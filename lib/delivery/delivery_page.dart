import 'package:flutter/material.dart';
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
            delivery.isLocationDemo
                ? 'Local demo · pickup and drop at your current location'
                : 'Grocery delivery · ${delivery.totalDistanceLabel}',
            style: AppTheme.secondaryTextStyle,
          ),
          const SizedBox(height: 20),
          if (isActive) ...[
            _OrderFlowProgress(
              delivery: delivery,
              pickupStatus: pickupStatus!,
              deliveryStatus: deliveryStatus!,
            ),
            const SizedBox(height: 12),
          ],
          if (store != null && store.queuedOrderStatusCount > 0) ...[
            _SyncPendingNotice(count: store.queuedOrderStatusCount),
            const SizedBox(height: 12),
          ],
          if (isActive) ...[
            _RouteMapCard(
              delivery: delivery,
              riderPosition: store?.availabilityStore.lastPosition,
              pickupStatus: pickupStatus!,
              offerStore: store!,
              showMapTiles: showMapTiles,
              onOpenMaps: () => _openNavigation(
                context,
                pickupStatus == PickupStatus.pickedUp ||
                        pickupStatus == PickupStatus.onTheWay
                    ? delivery.drop
                    : delivery.pickup,
                pickupStatus == PickupStatus.pickedUp ||
                        pickupStatus == PickupStatus.onTheWay
                    ? delivery.dropLatitude
                    : delivery.pickupLatitude,
                pickupStatus == PickupStatus.pickedUp ||
                        pickupStatus == PickupStatus.onTheWay
                    ? delivery.dropLongitude
                    : delivery.pickupLongitude,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('open-full-route-google-maps'),
              onPressed: () => _openFullRouteInGoogleMaps(context),
              icon: const Icon(Icons.map_rounded),
              label: const Text('Open pickup + delivery route in Google Maps'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppTheme.surface,
              ),
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
            address: _displayAddress(delivery.pickup),
            distance: delivery.pickupDistanceKm == null
                ? null
                : '${delivery.pickupDistanceKm!.toStringAsFixed(1)} km away',
          ),
          const SizedBox(height: 12),
          _StopCard(
            step: '2',
            title: 'Deliver to customer',
            place: delivery.customer,
            address: _displayAddress(delivery.drop),
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
              key: const ValueKey('navigate-to-pickup-google-maps'),
              onPressed: () => _openNavigation(
                context,
                delivery.pickup,
                delivery.pickupLatitude,
                delivery.pickupLongitude,
              ),
              icon: const Icon(Icons.map_rounded),
              label: const Text('Open Google Maps to Pickup'),
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
            if (delivery.pickupLatitude == null ||
                delivery.pickupLongitude == null)
              _primaryAction('Reached Store', () => store.reachStore(delivery))
            else
              const _ArrivalNotice(),
          ],
        );
      case PickupStatus.reachedPickup:
        return FilledButton.icon(
          key: const ValueKey('view-pickup-order'),
          onPressed: () => store.openOrderDetails(delivery),
          icon: const Icon(Icons.inventory_2_rounded),
          label: const Text('View pickup order'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: AppTheme.darkGreen,
            foregroundColor: AppTheme.surface,
          ),
        );
      case PickupStatus.orderDetails:
        return _PickupOrderDetails(delivery: delivery, offerStore: store);
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
              key: const ValueKey('navigate-to-customer-google-maps'),
              onPressed: () => _openNavigation(
                context,
                delivery.drop,
                delivery.dropLatitude,
                delivery.dropLongitude,
              ),
              icon: const Icon(Icons.map_rounded),
              label: const Text('Open Google Maps to Customer'),
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

  Future<void> _openFullRouteInGoogleMaps(BuildContext context) async {
    final pickup = _mapsDestination(
      delivery.pickup,
      delivery.pickupLatitude,
      delivery.pickupLongitude,
    );
    final drop = _mapsDestination(
      delivery.drop,
      delivery.dropLatitude,
      delivery.dropLongitude,
    );
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': drop,
      'waypoints': pickup,
      'travelmode': 'driving',
    });
    await _openContact(context, uri);
  }

  String _mapsDestination(String address, double? latitude, double? longitude) {
    if (latitude != null && longitude != null) return '$latitude,$longitude';
    return _displayAddress(address);
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

  String _displayAddress(String address) =>
      delivery.isLocationDemo ? address : '$address, Mandapeta';
}

class _OrderFlowProgress extends StatelessWidget {
  const _OrderFlowProgress({
    required this.delivery,
    required this.pickupStatus,
    required this.deliveryStatus,
  });

  final DemoDelivery delivery;
  final PickupStatus pickupStatus;
  final DeliveryStatus deliveryStatus;

  @override
  Widget build(BuildContext context) {
    final activeStep = switch (pickupStatus) {
      PickupStatus.goingToPickup ||
      PickupStatus.reachedPickup ||
      PickupStatus.orderDetails => 0,
      PickupStatus.pickedUp => 1,
      PickupStatus.onTheWay => 2,
    };
    final delivered = deliveryStatus == DeliveryStatus.delivered;
    const labels = ['Accepted', 'Picked up', 'Delivered'];
    const icons = [
      Icons.check_circle_outline_rounded,
      Icons.inventory_2_outlined,
      Icons.flag_outlined,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF0F7F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1F176B45)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10176B45),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ORDER JOURNEY',
                  style: TextStyle(
                    color: AppTheme.darkGreen,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (delivery.isLocationDemo)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F1E7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(
                      color: AppTheme.darkGreen,
                      fontSize: 9,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var index = 0; index < labels.length; index++) ...[
                if (index > 0)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 2,
                      color: delivered || index <= activeStep
                          ? AppTheme.brand
                          : const Color(0xFFD8E2DA),
                    ),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey('$index:$activeStep:$delivered'),
                      children: [
                        Icon(
                          delivered || index < activeStep
                              ? Icons.check_circle_rounded
                              : icons[index],
                          color: delivered || index <= activeStep
                              ? AppTheme.brand
                              : const Color(0xFF9AA79D),
                          size: 23,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          labels[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: delivered || index <= activeStep
                                ? AppTheme.darkGreen
                                : AppTheme.secondaryText,
                            fontSize: 10,
                            fontWeight: delivered || index == activeStep
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PickupOrderDetails extends StatelessWidget {
  const _PickupOrderDetails({required this.delivery, required this.offerStore});

  final DemoDelivery delivery;
  final OrderOfferStore offerStore;

  Future<void> _confirmPickup(BuildContext context) async {
    final completed = await offerStore.confirmPickupAndStartDelivery(delivery);
    if (!context.mounted || completed) return;
    final message =
        offerStore.errorMessage ??
        'Unable to confirm pickup and start the delivery.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Order Details', style: AppTheme.cardTitle),
            const SizedBox(height: 14),
            _OrderDetailLine(label: 'Order ID', value: delivery.orderId),
            _OrderDetailLine(label: 'Store', value: delivery.store),
            _OrderDetailLine(label: 'Pickup address', value: delivery.pickup),
            _OrderDetailLine(label: 'Customer', value: delivery.customer),
            _OrderDetailLine(label: 'Delivery address', value: delivery.drop),
            _OrderDetailLine(
              label: 'Estimated payout',
              value: '₹${delivery.calculatedPayout}',
            ),
            const Divider(height: 24),
            const Text('Items to collect', style: AppTheme.cardTitle),
            if (delivery.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Item details were not provided by the order service.',
                  style: AppTheme.secondaryTextStyle,
                ),
              )
            else
              for (final item in delivery.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(item.name, style: AppTheme.bodyText),
                  trailing: Text(
                    '× ${item.quantity}',
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            if (delivery.customerPhone != null)
              _OrderDetailLine(
                label: 'Customer phone',
                value: delivery.customerPhone!,
              ),
            if (delivery.storePhone != null)
              _OrderDetailLine(
                label: 'Store phone',
                value: delivery.storePhone!,
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: offerStore.isUpdatingOrderStatus
                  ? null
                  : () => _confirmPickup(context),
              child: offerStore.isUpdatingOrderStatus
                  ? const Text('Updating...')
                  : const Text('I picked up the order'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailLine extends StatelessWidget {
  const _OrderDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: AppTheme.secondaryTextStyle),
        ),
        Expanded(child: Text(value, style: AppTheme.bodyText)),
      ],
    ),
  );
}

class _ArrivalNotice extends StatelessWidget {
  const _ArrivalNotice();

  @override
  Widget build(BuildContext context) => const Card(
    color: AppTheme.brandSoft,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.location_searching_rounded, color: AppTheme.brand),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'We’ll detect your arrival automatically within '
              '${OrderOfferStore.pickupArrivalRadiusMeters} m of the store.',
            ),
          ),
        ],
      ),
    ),
  );
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
    required this.pickupStatus,
    required this.offerStore,
    required this.showMapTiles,
    required this.onOpenMaps,
  });

  final DemoDelivery delivery;
  final Position? riderPosition;
  final PickupStatus pickupStatus;
  final OrderOfferStore offerStore;
  final bool showMapTiles;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final isPickupLeg =
        pickupStatus != PickupStatus.pickedUp &&
        pickupStatus != PickupStatus.onTheWay;
    final destination = isPickupLeg
        ? delivery.pickupLatitude == null || delivery.pickupLongitude == null
              ? null
              : LatLng(delivery.pickupLatitude!, delivery.pickupLongitude!)
        : delivery.dropLatitude == null || delivery.dropLongitude == null
        ? null
        : LatLng(delivery.dropLatitude!, delivery.dropLongitude!);

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
                Expanded(
                  child: Text(
                    isPickupLeg ? 'Route to Store' : 'Route to Customer',
                    style: AppTheme.cardTitle,
                  ),
                ),
                Text(
                  riderPosition == null ? 'Locating rider...' : 'Live tracking',
                  style: AppTheme.smallStatus,
                ),
              ],
            ),
          ),
          if (destination != null)
            RiderMapView(
              key: const ValueKey('delivery-route-map'),
              riderLocation: riderPosition == null
                  ? null
                  : LatLng(riderPosition!.latitude, riderPosition!.longitude),
              showCurrentLocation: riderPosition == null,
              pickupLocation: isPickupLeg ? destination : null,
              dropoffLocation: isPickupLeg ? null : destination,
              navigationTarget: destination,
              onRiderPositionChanged: isPickupLeg
                  ? (position) =>
                        offerStore.checkPickupArrival(delivery, position)
                  : null,
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
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (riderPosition != null)
                        const _RouteLegendItem(
                          label: 'Rider',
                          color: AppTheme.brand,
                        ),
                      if (isPickupLeg)
                        const _RouteLegendItem(
                          label: 'Store',
                          color: AppTheme.brand,
                        )
                      else
                        const _RouteLegendItem(
                          label: 'Customer',
                          color: AppTheme.brandYellow,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: const ValueKey('route-map-open-google-maps'),
                  onPressed: onOpenMaps,
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text('Google Maps'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    visualDensity: VisualDensity.compact,
                  ),
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
