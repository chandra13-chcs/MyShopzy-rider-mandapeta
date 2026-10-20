import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myshopzy_rider/core/models/demo_delivery.dart';
import 'package:myshopzy_rider/core/state/availability_store.dart';
import 'package:myshopzy_rider/core/state/order_offer_store.dart';
import 'package:myshopzy_rider/core/theme/app_theme.dart';
import 'package:myshopzy_rider/history/history_page.dart';

void main() {
  testWidgets('left-swiped orders appear in a separate rejected history', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore();
    final rejectedDelivery = DemoDelivery(
      orderId: 'rejected-test-order',
      store: 'Green Basket',
      customer: 'Test Customer',
      pickup: '4 Main Road',
      drop: 'Lake View',
      distanceKm: 3.2,
      payout: 55,
      status: 'New Offer',
    );
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: null,
      offer: rejectedDelivery,
    );
    addTearDown(offerStore.dispose);
    addTearDown(availabilityStore.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HistoryPage(offerStore: offerStore),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rejected orders'), findsOneWidget);
    expect(find.text('Orders you reject will appear here.'), findsOneWidget);

    expect(offerStore.rejectOffer(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('rejected-test-order'), findsOneWidget);
    expect(find.text('Green Basket'), findsOneWidget);
    expect(find.text('Pickup · 4 Main Road'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.byKey(const ValueKey('rejected-order-count')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
