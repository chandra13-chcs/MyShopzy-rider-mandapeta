import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/status_badge.dart';
import '../earnings/rider_earnings_demo_data.dart';

enum _HistoryStatusFilter { all, completed, cancelled }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  _HistoryStatusFilter _statusFilter = _HistoryStatusFilter.all;
  EarningsPeriod _periodFilter = EarningsPeriod.thisMonth;

  List<DeliveryHistoryItem> get _filteredHistory => RiderEarningsDemoData
      .history
      .where((item) {
        final matchesStatus = switch (_statusFilter) {
          _HistoryStatusFilter.all => true,
          _HistoryStatusFilter.completed =>
            item.status == DeliveryHistoryStatus.completed,
          _HistoryStatusFilter.cancelled =>
            item.status == DeliveryHistoryStatus.cancelled,
        };
        final matchesPeriod = switch (_periodFilter) {
          EarningsPeriod.today => item.period == EarningsPeriod.today,
          EarningsPeriod.thisWeek =>
            item.period == EarningsPeriod.today ||
                item.period == EarningsPeriod.thisWeek,
          EarningsPeriod.thisMonth => true,
        };
        return matchesStatus && matchesPeriod;
      })
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final history = _filteredHistory;
    final completedCount = RiderEarningsDemoData.history
        .where((item) => item.status == DeliveryHistoryStatus.completed)
        .length;
    final cancelledCount = RiderEarningsDemoData.history
        .where((item) => item.status == DeliveryHistoryStatus.cancelled)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery history')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _HistoryCountCard(
                    title: 'Completed Deliveries',
                    count: completedCount,
                    color: AppTheme.success,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HistoryCountCard(
                    title: 'Cancelled Deliveries',
                    count: cancelledCount,
                    color: AppTheme.error,
                    icon: Icons.cancel_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Status', style: AppTheme.cardTitle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(_HistoryStatusFilter.all, 'All'),
                _statusChip(_HistoryStatusFilter.completed, 'Completed'),
                _statusChip(_HistoryStatusFilter.cancelled, 'Cancelled'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Time period', style: AppTheme.cardTitle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _periodChip(EarningsPeriod.today, 'Today'),
                _periodChip(EarningsPeriod.thisWeek, 'This Week'),
                _periodChip(EarningsPeriod.thisMonth, 'This Month'),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Deliveries', style: AppTheme.sectionTitle),
            const SizedBox(height: 10),
            if (history.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No deliveries match these filters.'),
                ),
              )
            else
              for (final item in history)
                _HistoryRecordCard(
                  item: item,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => DeliveryHistoryDetailsPage(item: item),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(_HistoryStatusFilter filter, String label) => ChoiceChip(
    key: ValueKey('history-status-${filter.name}'),
    label: Text(label),
    selected: _statusFilter == filter,
    onSelected: (_) => setState(() => _statusFilter = filter),
  );

  Widget _periodChip(EarningsPeriod period, String label) => ChoiceChip(
    key: ValueKey('history-period-${period.name}'),
    label: Text(label),
    selected: _periodFilter == period,
    onSelected: (_) => setState(() => _periodFilter = period),
  );
}

class DeliveryHistoryDetailsPage extends StatelessWidget {
  const DeliveryHistoryDetailsPage({required this.item, super.key});

  final DeliveryHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final isCompleted = item.status == DeliveryHistoryStatus.completed;
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.orderId,
                            style: AppTheme.sectionTitle,
                          ),
                        ),
                        StatusBadge(
                          label: isCompleted ? 'Delivered' : 'Cancelled',
                          color: isCompleted
                              ? AppTheme.success
                              : AppTheme.error,
                          backgroundColor: isCompleted
                              ? AppTheme.successSoft
                              : const Color(0xFFFFE8E6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _HistoryDetailRow(label: 'Store', value: item.store),
                    _HistoryDetailRow(label: 'Customer', value: item.customer),
                    _HistoryDetailRow(label: 'Pickup', value: item.pickup),
                    _HistoryDetailRow(label: 'Drop', value: item.drop),
                    _HistoryDetailRow(
                      label: 'Date',
                      value: item.dateTime.split('•').first.trim(),
                    ),
                    _HistoryDetailRow(
                      label: 'Time',
                      value: item.dateTime.contains('•')
                          ? item.dateTime.split('•').last.trim()
                          : item.dateTime,
                    ),
                    _HistoryDetailRow(
                      label: 'Distance',
                      value: '${item.distanceKm.toStringAsFixed(1)} km',
                    ),
                    _HistoryDetailRow(
                      label: 'Delivery status',
                      value: isCompleted ? 'Delivered' : 'Cancelled',
                      valueColor: isCompleted
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                    _HistoryDetailRow(
                      label: 'Earnings',
                      value: _currency(item.earnings),
                      valueColor: isCompleted
                          ? AppTheme.success
                          : AppTheme.error,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCountCard extends StatelessWidget {
  const _HistoryCountCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: AppTheme.cardTitle.copyWith(color: color),
                ),
                Text(title, style: AppTheme.secondaryTextStyle),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({required this.item, required this.onTap});

  final DeliveryHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = item.status == DeliveryHistoryStatus.completed;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        key: ValueKey('history-record-${item.orderId}'),
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isCompleted
                    ? AppTheme.successSoft
                    : const Color(0xFFFFE8E6),
                child: Icon(
                  isCompleted ? Icons.check_rounded : Icons.close_rounded,
                  color: isCompleted ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.orderId, style: AppTheme.cardTitle),
                    const SizedBox(height: 3),
                    Text(item.store, style: AppTheme.bodyText),
                    const SizedBox(height: 2),
                    Text(item.customer, style: AppTheme.secondaryTextStyle),
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
                    label: isCompleted ? 'Delivered' : 'Cancelled',
                    color: isCompleted ? AppTheme.success : AppTheme.error,
                    backgroundColor: isCompleted
                        ? AppTheme.successSoft
                        : const Color(0xFFFFE8E6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currency(item.earnings),
                    style: AppTheme.cardTitle.copyWith(
                      color: isCompleted ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryDetailRow extends StatelessWidget {
  const _HistoryDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(label, style: AppTheme.secondaryTextStyle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyText.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

String _currency(int amount) {
  if (amount < 1000) return '₹$amount';
  final digits = amount.toString();
  var prefix = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (prefix.length > 2) {
    groups.insert(0, prefix.substring(prefix.length - 2));
    prefix = prefix.substring(0, prefix.length - 2);
  }
  groups.insert(0, prefix);
  return '₹${groups.join(',')},${digits.substring(digits.length - 3)}';
}
