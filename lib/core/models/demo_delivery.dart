import 'dart:math' as math;

enum DeliveryTimeWindow { day, evening }

class DeliveryLineItem {
  const DeliveryLineItem({required this.name, required this.quantity});

  final String name;
  final int quantity;
}

class DemoDelivery {
  const DemoDelivery({
    required this.orderId,
    required this.store,
    required this.customer,
    required this.pickup,
    required this.drop,
    required this.distanceKm,
    required this.payout,
    required this.status,
    this.pickupDistanceKm,
    this.deliveryDistanceKm,
    this.items = const [],
    this.storePhone,
    this.customerPhone,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
    this.hasServerPayout = false,
    this.vehicle = 'Bike',
    this.timeWindow = DeliveryTimeWindow.day,
    this.rain = false,
    this.hasRouteEstimate = true,
    this.isLocationDemo = false,
  });

  static const batchThreeActive = DemoDelivery(
    orderId: '#MS-2048',
    store: 'Fresh Basket',
    customer: 'Ananya Reddy',
    pickup: '12 Market Road',
    drop: 'Lakshmi Nagar',
    distanceKm: 2.4,
    payout: 85,
    status: 'On the Way',
    deliveryDistanceKm: 2.4,
    timeWindow: DeliveryTimeWindow.day,
  );

  static const newOffer = DemoDelivery(
    orderId: '#MS-2051',
    store: 'Fresh Basket',
    customer: 'Ananya Reddy',
    pickup: '12 Market Road',
    drop: 'Lakshmi Nagar',
    distanceKm: 4.2,
    payout: 40,
    status: 'New Offer',
    pickupDistanceKm: 1.8,
    deliveryDistanceKm: 2.4,
    pickupLatitude: 16.8668,
    pickupLongitude: 81.9296,
    dropLatitude: 16.8584,
    dropLongitude: 81.9421,
    items: [
      DeliveryLineItem(name: 'Fresh vegetables', quantity: 2),
      DeliveryLineItem(name: 'Milk', quantity: 1),
    ],
    customerPhone: null,
    storePhone: null,
    timeWindow: DeliveryTimeWindow.day,
  );

  factory DemoDelivery.nearbyDemoOffer({
    required double riderLatitude,
    required double riderLongitude,
  }) {
    return DemoDelivery(
      orderId: newOffer.orderId,
      store: 'Local Demo Kitchen',
      customer: 'Demo Customer',
      pickup: 'Your current location (demo)',
      drop: 'Same location (demo)',
      distanceKm: 0,
      payout: newOffer.payout,
      status: newOffer.status,
      pickupDistanceKm: 0,
      deliveryDistanceKm: 0,
      items: const [
        DeliveryLineItem(name: 'Demo meal combo', quantity: 1),
        DeliveryLineItem(name: 'Water bottle', quantity: 1),
      ],
      pickupLatitude: riderLatitude,
      pickupLongitude: riderLongitude,
      dropLatitude: riderLatitude,
      dropLongitude: riderLongitude,
      timeWindow: newOffer.timeWindow,
      isLocationDemo: true,
    );
  }

  factory DemoDelivery.fromRiderApiJson(Map<String, dynamic> json) {
    final orderId = json['orderId'];
    final store = json['store'];
    if (orderId is! String || orderId.isEmpty || store is! String) {
      throw const FormatException('Order is missing its ID or store name.');
    }

    final deliveryAddress = json['drop'];
    final customer = deliveryAddress is Map<String, dynamic>
        ? deliveryAddress['customerName'] ?? deliveryAddress['name']
        : null;
    final customerName = json['customerName'] ?? customer;
    final customerPhone = json['customerPhone'];
    final storePhone = json['storePhone'];
    final serverPayout = _optionalInteger(json['payout']);
    final distanceKm = _optionalNumber(json['distanceKm']);
    final pickupDistanceKm = _optionalNumber(json['pickupDistanceKm']);
    final deliveryDistanceKm = _optionalNumber(json['deliveryDistanceKm']);
    return DemoDelivery(
      orderId: orderId,
      store: store,
      customer: customerName is String && customerName.isNotEmpty
          ? customerName
          : 'Customer',
      pickup: _formatAddress(json['pickup']),
      drop: _formatAddress(deliveryAddress),
      customerPhone: customerPhone is String && customerPhone.trim().isNotEmpty
          ? customerPhone.trim()
          : null,
      storePhone: storePhone is String && storePhone.trim().isNotEmpty
          ? storePhone.trim()
          : null,
      pickupLatitude: _optionalCoordinate(json['pickupLatitude'], -90, 90),
      pickupLongitude: _optionalCoordinate(json['pickupLongitude'], -180, 180),
      dropLatitude: _optionalCoordinate(json['dropLatitude'], -90, 90),
      dropLongitude: _optionalCoordinate(json['dropLongitude'], -180, 180),
      distanceKm: distanceKm ?? 0,
      payout: serverPayout ?? 40,
      hasServerPayout: serverPayout != null,
      status: json['status'] is String ? json['status'] as String : 'New Offer',
      pickupDistanceKm: pickupDistanceKm,
      deliveryDistanceKm: deliveryDistanceKm,
      items: _parseItems(json['items']),
      hasRouteEstimate:
          distanceKm != null ||
          pickupDistanceKm != null ||
          deliveryDistanceKm != null,
    );
  }

  final String orderId;
  final String store;
  final String customer;
  final String pickup;
  final String drop;
  final String? customerPhone;
  final String? storePhone;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropLatitude;
  final double? dropLongitude;
  final bool hasServerPayout;
  final double distanceKm;
  final int payout;
  final String status;
  final double? pickupDistanceKm;
  final double? deliveryDistanceKm;
  final List<DeliveryLineItem> items;
  final String vehicle;
  final DeliveryTimeWindow timeWindow;
  final bool rain;
  final bool hasRouteEstimate;
  final bool isLocationDemo;

  double get effectiveDeliveryDistance => deliveryDistanceKm ?? distanceKm;

  String get pickupDistanceLabel => pickupDistanceKm == null
      ? 'Not provided'
      : '${pickupDistanceKm!.toStringAsFixed(1)} km';

  String get deliveryDistanceLabel => !hasRouteEstimate
      ? 'Not provided'
      : '${effectiveDeliveryDistance.toStringAsFixed(1)} km';

  String get totalDistanceLabel => !hasRouteEstimate
      ? 'Not provided'
      : '${distanceKm.toStringAsFixed(1)} km';

  int get basePayout => timeWindow == DeliveryTimeWindow.evening ? 50 : 40;

  int get distanceCharge {
    final extraKm = effectiveDeliveryDistance > 4
        ? (effectiveDeliveryDistance - 4).ceil()
        : 0;
    return extraKm * 10;
  }

  int get rainCharge => rain ? 10 : 0;

  int get calculatedPayout =>
      hasServerPayout ? payout : basePayout + distanceCharge + rainCharge;

  String get payoutBreakdown {
    if (hasServerPayout) return 'Total payout: ₹$payout';
    final extraKm = effectiveDeliveryDistance > 4
        ? (effectiveDeliveryDistance - 4).ceil()
        : 0;
    final parts = <String>[
      'Base: ₹$basePayout',
      if (extraKm > 0) 'Distance: +₹$distanceCharge ($extraKm km)',
      if (rain) 'Rain: +₹10',
    ];
    return parts.join(' • ');
  }

  static String _formatAddress(Object? value) {
    if (value is String) return value;
    if (value is! Map<String, dynamic>) return 'Address unavailable';

    const addressFields = [
      'formattedAddress',
      'addressLine',
      'street',
      'locality',
      'city',
      'pincode',
    ];
    final parts = <String>[];
    for (final field in addressFields) {
      final part = value[field];
      if (part is String && part.trim().isNotEmpty && !parts.contains(part)) {
        parts.add(part.trim());
      }
    }
    return parts.isEmpty ? 'Address unavailable' : parts.join(', ');
  }

  static List<DeliveryLineItem> _parseItems(Object? value) {
    if (value == null) return const [];
    if (value is! List) {
      throw const FormatException('Order items must be a list.');
    }

    final items = <DeliveryLineItem>[];
    for (final item in value) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Order contains an invalid item.');
      }
      final name = item['name'];
      final quantity = _optionalInteger(item['quantity']);
      if (name is! String ||
          name.trim().isEmpty ||
          quantity == null ||
          quantity < 1) {
        throw const FormatException(
          'Order item is missing its name or quantity.',
        );
      }
      items.add(DeliveryLineItem(name: name.trim(), quantity: quantity));
    }
    return List.unmodifiable(items);
  }

  static int? _optionalInteger(Object? value) {
    if (value is int) return value;
    if (value is String) {
      final integer = int.tryParse(value);
      if (integer != null) return integer;
      final number = double.tryParse(value);
      return number != null && number.isFinite ? number.round() : null;
    }
    if (value is num && value.isFinite) return value.round();
    return null;
  }

  static double? _optionalNumber(Object? value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number != null && number.isFinite ? math.max(0, number) : null;
  }

  static double? _optionalCoordinate(
    Object? value,
    double minimum,
    double maximum,
  ) {
    final signed = value is num ? value.toDouble() : double.tryParse('$value');
    return signed != null &&
            signed.isFinite &&
            signed >= minimum &&
            signed <= maximum
        ? signed
        : null;
  }

  DemoDelivery copyWith({
    String? status,
    double? distanceKm,
    double? pickupDistanceKm,
    double? deliveryDistanceKm,
    bool? hasRouteEstimate,
    DeliveryTimeWindow? timeWindow,
    bool? rain,
    int? payout,
    String? customerPhone,
    String? storePhone,
  }) => DemoDelivery(
    orderId: orderId,
    store: store,
    customer: customer,
    pickup: pickup,
    drop: drop,
    customerPhone: customerPhone ?? this.customerPhone,
    storePhone: storePhone ?? this.storePhone,
    pickupLatitude: pickupLatitude,
    pickupLongitude: pickupLongitude,
    dropLatitude: dropLatitude,
    dropLongitude: dropLongitude,
    distanceKm: distanceKm ?? this.distanceKm,
    payout: payout ?? this.payout,
    hasServerPayout: hasServerPayout,
    status: status ?? this.status,
    pickupDistanceKm: pickupDistanceKm ?? this.pickupDistanceKm,
    deliveryDistanceKm: deliveryDistanceKm ?? this.deliveryDistanceKm,
    items: items,
    vehicle: vehicle,
    timeWindow: timeWindow ?? this.timeWindow,
    rain: rain ?? this.rain,
    hasRouteEstimate: hasRouteEstimate ?? this.hasRouteEstimate,
    isLocationDemo: isLocationDemo,
  );
}
