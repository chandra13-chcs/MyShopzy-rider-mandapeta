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
    payout: 95,
    status: 'New Offer',
    pickupDistanceKm: 1.8,
    deliveryDistanceKm: 2.4,
    timeWindow: DeliveryTimeWindow.day,
  );

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

  double get effectiveDeliveryDistance => deliveryDistanceKm ?? distanceKm;

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
      'Base: ₹${basePayout}',
      if (extraKm > 0) 'Distance: +₹${distanceCharge} (${extraKm} km)',
      if (rain) 'Rain: +₹10',
    ];
    return parts.join(' • ');
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
  );
}
