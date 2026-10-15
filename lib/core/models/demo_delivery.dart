import 'dart:math' as math;

enum DeliveryTimeWindow { day, evening }

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
    this.vehicle = 'Bike',
    this.timeWindow = DeliveryTimeWindow.day,
    this.rain = false,
    this.hasRouteEstimate = true,
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
    timeWindow: DeliveryTimeWindow.day,
  );

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
    final distanceKm = _optionalNumber(json['distanceKm']);
    final pickupDistanceKm = _optionalNumber(json['pickupDistanceKm']);
    final deliveryDistanceKm = _optionalNumber(json['deliveryDistanceKm']);
    return DemoDelivery(
      orderId: orderId,
      store: store,
      customer: customer is String && customer.isNotEmpty
          ? customer
          : 'Customer',
      pickup: _formatAddress(json['pickup']),
      drop: _formatAddress(deliveryAddress),
      distanceKm: distanceKm ?? 0,
      payout: _optionalInteger(json['payout']) ?? 40,
      status: json['status'] is String ? json['status'] as String : 'New Offer',
      pickupDistanceKm: pickupDistanceKm,
      deliveryDistanceKm: deliveryDistanceKm,
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
  final double distanceKm;
  final int payout;
  final String status;
  final double? pickupDistanceKm;
  final double? deliveryDistanceKm;
  final String vehicle;
  final DeliveryTimeWindow timeWindow;
  final bool rain;
  final bool hasRouteEstimate;

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

  int get calculatedPayout => basePayout + distanceCharge + rainCharge;

  String get payoutBreakdown {
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

  static int? _optionalInteger(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num && value.isFinite) return value.round();
    return null;
  }

  static double? _optionalNumber(Object? value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number != null && number.isFinite ? math.max(0, number) : null;
  }

  DemoDelivery copyWith({
    String? status,
    double? pickupDistanceKm,
    double? deliveryDistanceKm,
    DeliveryTimeWindow? timeWindow,
    bool? rain,
    int? payout,
  }) => DemoDelivery(
    orderId: orderId,
    store: store,
    customer: customer,
    pickup: pickup,
    drop: drop,
    distanceKm: distanceKm,
    payout: payout ?? this.payout,
    status: status ?? this.status,
    pickupDistanceKm: pickupDistanceKm ?? this.pickupDistanceKm,
    deliveryDistanceKm: deliveryDistanceKm ?? this.deliveryDistanceKm,
    vehicle: vehicle,
    timeWindow: timeWindow ?? this.timeWindow,
    rain: rain ?? this.rain,
    hasRouteEstimate: hasRouteEstimate,
  );
}
