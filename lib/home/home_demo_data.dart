class HomeDemoData {
  const HomeDemoData({
    this.greeting = 'Good morning,',
    this.riderName = 'Ravi Kumar',
    this.deliveriesCompleted = 5,
    this.todayEarnings = 650,
    this.distanceKm = 18.6,
    this.onlineTime = '4h 25m',
    this.activeDelivery = const DemoDelivery(
      orderId: '#MS-2048',
      store: 'Fresh Basket',
      customer: 'Ananya Reddy',
      pickup: '12 Market Road',
      drop: 'Lakshmi Nagar',
      distanceKm: 2.4,
      payout: 85,
      status: 'On the Way',
    ),
    this.recentDelivery = const RecentDemoDelivery(
      store: 'Fresh Basket',
      payout: 85,
      distanceKm: 2.4,
    ),
  });

  final String greeting;
  final String riderName;
  final int deliveriesCompleted;
  final int todayEarnings;
  final double distanceKm;
  final String onlineTime;
  final DemoDelivery? activeDelivery;
  final RecentDemoDelivery recentDelivery;
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
  });

  final String orderId;
  final String store;
  final String customer;
  final String pickup;
  final String drop;
  final double distanceKm;
  final int payout;
  final String status;
}

class RecentDemoDelivery {
  const RecentDemoDelivery({
    required this.store,
    required this.payout,
    required this.distanceKm,
  });

  final String store;
  final int payout;
  final double distanceKm;
}
