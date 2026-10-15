import 'package:flutter/material.dart';

import '../core/state/order_offer_store.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_badge.dart';
import '../history/history_page.dart';
import 'rider_earnings_demo_data.dart';

class EarningsPage extends StatelessWidget {
  const EarningsPage({this.offerStore, super.key});

  final OrderOfferStore? offerStore;

  @override
  Widget build(BuildContext context) {
    final summary = RiderEarningsDemoData.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryPage()),
            ),
            tooltip: 'Delivery history',
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppTheme.darkGreen,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TODAY'S EARNINGS",
                      style: TextStyle(color: AppTheme.onDarkSurface),
                    ),
                    const SizedBox(height: 8),
                    if (offerStore case final liveStore?)
                      AnimatedBuilder(
                        animation: liveStore,
                        builder: (context, child) {
                          final settlement = liveStore.todaySettlementMinor;
                          return Text(
                            settlement == null
                                ? liveStore.apiClient == null
                                      ? _currency(summary.today)
                                      : _currency(0)
                                : '₹${(settlement / 100).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.surface,
                              fontWeight: FontWeight.w800,
                              fontSize: 34,
                            ),
                          );
                        },
                      )
                    else
                      Text(
                        _currency(summary.today),
                        style: const TextStyle(
                          color: AppTheme.surface,
                          fontWeight: FontWeight.w800,
                          fontSize: 34,
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (offerStore case final liveStore?)
                      AnimatedBuilder(
                        animation: liveStore,
                        builder: (context, child) => Text(
                          '${liveStore.todayCompletedDeliveries ?? (liveStore.apiClient == null ? 5 : 0)} deliveries completed',
                          style: const TextStyle(color: AppTheme.onDarkSurface),
                        ),
                      )
                    else
                      const Text(
                        '5 deliveries completed',
                        style: TextStyle(color: AppTheme.onDarkSurface),
                      ),
                    if (offerStore?.earningsErrorMessage case final error?) ...[
                      const SizedBox(height: 6),
                      Text(
                        error,
                        style: const TextStyle(color: AppTheme.onDarkSurface),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: 'Earnings summary'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'This Week',
                    value: _currency(summary.thisWeek),
                    icon: Icons.date_range_rounded,
                    color: AppTheme.brand,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    title: 'This Month',
                    value: _currency(summary.thisMonth),
                    icon: Icons.calendar_month_rounded,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Earnings',
                    value: _currency(summary.totalEarnings),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppTheme.brand,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    title: 'Completed Deliveries',
                    value: _groupNumber(summary.completedDeliveries),
                    icon: Icons.check_circle_outline_rounded,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.trending_up_rounded,
                  color: AppTheme.brand,
                ),
                title: const Text('Average Earnings / Delivery'),
                trailing: Text(
                  _currency(summary.averagePerDelivery),
                  style: AppTheme.cardTitle,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'Earnings breakdown'),
            const SizedBox(height: 10),
            for (final breakdown in RiderEarningsDemoData.breakdowns)
              _BreakdownCard(breakdown: breakdown),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'Recent Earnings'),
            const SizedBox(height: 10),
            for (final item in RiderEarningsDemoData.recentEarnings)
              _RecentEarningCard(item: item),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HistoryPage()),
              ),
              icon: const Icon(Icons.history_rounded),
              label: const Text('View delivery history'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: AppTheme.sectionTitle);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.cardTitle,
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.secondaryTextStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.breakdown});

  final EarningsBreakdown breakdown;

  String get _title => switch (breakdown.period) {
    EarningsPeriod.today => 'Today',
    EarningsPeriod.thisWeek => 'This Week',
    EarningsPeriod.thisMonth => 'This Month',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: AppTheme.cardTitle),
            const SizedBox(height: 12),
            _BreakdownRow(
              label: 'Deliveries',
              value: '${breakdown.deliveries}',
            ),
            const SizedBox(height: 8),
            _BreakdownRow(
              label: 'Distance',
              value: '${_distance(breakdown.distanceKm)} km',
            ),
            const Divider(height: 20),
            _BreakdownRow(
              label: 'Earnings',
              value: _currency(breakdown.earnings),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasize
                ? AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700)
                : AppTheme.secondaryTextStyle,
          ),
        ),
        Text(
          value,
          style: emphasize
              ? AppTheme.bodyText.copyWith(fontWeight: FontWeight.w800)
              : AppTheme.bodyText,
        ),
      ],
    );
  }
}

class _RecentEarningCard extends StatelessWidget {
  const _RecentEarningCard({required this.item});

  final DeliveryHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.successSoft,
              child: Icon(Icons.payments_outlined, color: AppTheme.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.orderId, style: AppTheme.cardTitle),
                  const SizedBox(height: 3),
                  Text(item.store, style: AppTheme.bodyText),
                  const SizedBox(height: 3),
                  Text(item.dateTime, style: AppTheme.secondaryTextStyle),
                  const SizedBox(height: 3),
                  Text(
                    '${item.distanceKm.toStringAsFixed(1)} km',
                    style: AppTheme.secondaryTextStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(
                  label: 'Delivered',
                  color: AppTheme.success,
                  backgroundColor: AppTheme.successSoft,
                ),
                const SizedBox(height: 8),
                Text(
                  _currency(item.earnings),
                  style: AppTheme.cardTitle.copyWith(color: AppTheme.success),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _currency(int amount) => '₹${_groupNumber(amount)}';

String _distance(double distanceKm) => distanceKm == distanceKm.roundToDouble()
    ? distanceKm.toStringAsFixed(0)
    : distanceKm.toStringAsFixed(1);

String _groupNumber(int value) {
  final digits = value.toString();
  if (digits.length <= 3) return digits;
  var leading = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (leading.length > 2) {
    groups.insert(0, leading.substring(leading.length - 2));
    leading = leading.substring(0, leading.length - 2);
  }
  groups.insert(0, leading);
  return '${groups.join(',')},${digits.substring(digits.length - 3)}';
}
