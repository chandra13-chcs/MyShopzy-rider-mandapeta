import '../core/models/demo_delivery.dart';

class HomeDemoData {
  const HomeDemoData({
    this.greeting = 'Good morning,',
    this.riderName = 'Ravi Kumar',
    this.deliveriesCompleted = 5,
    this.todayEarnings = 650,
    this.distanceKm = 18.6,
    this.onlineTime = '4h 25m',
    this.activeDelivery = DemoDelivery.batchThreeActive,
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
