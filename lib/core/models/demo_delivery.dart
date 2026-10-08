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
}
