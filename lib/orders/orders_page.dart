import 'package:flutter/material.dart';

import '../core/state/availability_store.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_badge.dart';
import '../delivery/delivery_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({required this.availabilityStore, super.key});

  final AvailabilityStore availabilityStore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ValueListenableBuilder<AvailabilityStatus>(
        valueListenable: availabilityStore,
        builder: (context, availability, child) {
          if (availability == AvailabilityStatus.offline) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: const [
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.wifi_off_rounded,
                      color: AppTheme.error,
                    ),
                    title: Text("You're offline"),
                    subtitle: Text(
                      'New delivery offers are unavailable while you are offline.',
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text(
                'Your next delivery is waiting',
                style: AppTheme.secondaryTextStyle,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          StatusBadge(label: 'NEW ORDER'),
                          Spacer(),
                          Text('2.4 km', style: AppTheme.secondaryTextStyle),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Fresh Basket Supermarket',
                        style: AppTheme.cardTitle,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Pickup · 12 Market Road',
                        style: AppTheme.secondaryTextStyle,
                      ),
                      const Divider(height: 26),
                      const Text(
                        'Ananya Reddy',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Drop-off · 8 Lake View Colony',
                        style: AppTheme.secondaryTextStyle,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Payout  ',
                                style: AppTheme.secondaryTextStyle,
                              ),
                              Text(
                                '₹ 85',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const DeliveryPage(),
                              ),
                            ),
                            child: const Text('View details'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text('Coming up', style: AppTheme.sectionTitle),
              const SizedBox(height: 12),
              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.schedule_rounded,
                    color: AppTheme.secondaryText,
                  ),
                  title: Text('No scheduled deliveries'),
                  subtitle: Text('New offers will show here'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
