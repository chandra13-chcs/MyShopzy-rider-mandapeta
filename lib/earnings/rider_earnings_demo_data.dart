enum EarningsPeriod { today, thisWeek, thisMonth }

enum DeliveryHistoryStatus { completed, cancelled }

class RiderEarningsSummary {
  const RiderEarningsSummary({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.totalEarnings,
    required this.completedDeliveries,
    required this.averagePerDelivery,
  });

  final int today;
  final int thisWeek;
  final int thisMonth;
  final int totalEarnings;
  final int completedDeliveries;
  final int averagePerDelivery;
}

class EarningsBreakdown {
  const EarningsBreakdown({
    required this.period,
    required this.deliveries,
    required this.distanceKm,
    required this.earnings,
  });

  final EarningsPeriod period;
  final int deliveries;
  final double distanceKm;
  final int earnings;
}

class DeliveryHistoryItem {
  const DeliveryHistoryItem({
    required this.orderId,
    required this.store,
    required this.customer,
    required this.pickup,
    required this.drop,
    required this.dateTime,
    required this.distanceKm,
    required this.status,
    required this.earnings,
    required this.period,
  });

  final String orderId;
  final String store;
  final String customer;
  final String pickup;
  final String drop;
  final String dateTime;
  final double distanceKm;
  final DeliveryHistoryStatus status;
  final int earnings;
  final EarningsPeriod period;
}

abstract final class RiderEarningsDemoData {
  static const summary = RiderEarningsSummary(
    today: 650,
    thisWeek: 3850,
    thisMonth: 18420,
    totalEarnings: 124800,
    completedDeliveries: 1220,
    averagePerDelivery: 102,
  );

  static const breakdowns = [
    EarningsBreakdown(
      period: EarningsPeriod.today,
      deliveries: 5,
      distanceKm: 18.6,
      earnings: 650,
    ),
    EarningsBreakdown(
      period: EarningsPeriod.thisWeek,
      deliveries: 31,
      distanceKm: 124.5,
      earnings: 3850,
    ),
    EarningsBreakdown(
      period: EarningsPeriod.thisMonth,
      deliveries: 186,
      distanceKm: 742,
      earnings: 18420,
    ),
  ];

  static const history = [
    DeliveryHistoryItem(
      orderId: '#MS-2051',
      store: 'Fresh Basket',
      customer: 'Ananya Reddy',
      pickup: '12 Market Road',
      drop: 'Lakshmi Nagar',
      dateTime: 'Today • 2:40 PM',
      distanceKm: 4.2,
      status: DeliveryHistoryStatus.completed,
      earnings: 95,
      period: EarningsPeriod.today,
    ),
    DeliveryHistoryItem(
      orderId: '#MS-2048',
      store: 'Fresh Basket',
      customer: 'Ananya Reddy',
      pickup: '12 Market Road',
      drop: 'Lakshmi Nagar',
      dateTime: 'Today • 1:55 PM',
      distanceKm: 2.4,
      status: DeliveryHistoryStatus.completed,
      earnings: 85,
      period: EarningsPeriod.today,
    ),
    DeliveryHistoryItem(
      orderId: '#MS-2047',
      store: 'Green Mart',
      customer: 'Kiran Rao',
      pickup: '8 Station Road',
      drop: 'Ramakrishna Colony',
      dateTime: 'Today • 12:30 PM',
      distanceKm: 5.1,
      status: DeliveryHistoryStatus.completed,
      earnings: 120,
      period: EarningsPeriod.today,
    ),
    DeliveryHistoryItem(
      orderId: '#MS-2042',
      store: 'Green Mart',
      customer: 'Sita Devi',
      pickup: '8 Station Road',
      drop: 'Old Bus Stand',
      dateTime: 'Today • 11:15 AM',
      distanceKm: 3.6,
      status: DeliveryHistoryStatus.cancelled,
      earnings: 0,
      period: EarningsPeriod.today,
    ),
    DeliveryHistoryItem(
      orderId: '#MS-2040',
      store: 'Daily Needs Mart',
      customer: 'Rahul Varma',
      pickup: 'Market Street',
      drop: 'Vijaya Nagar',
      dateTime: 'Yesterday • 6:12 PM',
      distanceKm: 6.3,
      status: DeliveryHistoryStatus.completed,
      earnings: 110,
      period: EarningsPeriod.thisWeek,
    ),
    DeliveryHistoryItem(
      orderId: '#MS-2038',
      store: 'City Pharmacy',
      customer: 'Meera Rao',
      pickup: 'Main Road',
      drop: 'Temple Street',
      dateTime: 'Oct 2 • 9:20 AM',
      distanceKm: 3.2,
      status: DeliveryHistoryStatus.completed,
      earnings: 90,
      period: EarningsPeriod.thisMonth,
    ),
    DeliveryHistoryItem(
      orderId: '#MS-2036',
      store: 'Green Mart',
      customer: 'Ravi Teja',
      pickup: '8 Station Road',
      drop: 'Canal Road',
      dateTime: 'Oct 1 • 4:05 PM',
      distanceKm: 4.8,
      status: DeliveryHistoryStatus.cancelled,
      earnings: 0,
      period: EarningsPeriod.thisMonth,
    ),
  ];

  static List<DeliveryHistoryItem> get recentEarnings => history
      .where((item) => item.status == DeliveryHistoryStatus.completed)
      .take(3)
      .toList(growable: false);
}
