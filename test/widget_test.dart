import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myshopzy_rider/app/rider_app.dart';
import 'package:myshopzy_rider/core/state/availability_store.dart';
import 'package:myshopzy_rider/core/state/order_offer_store.dart';
import 'package:myshopzy_rider/core/models/demo_delivery.dart';
import 'package:myshopzy_rider/core/theme/app_theme.dart';
import 'package:myshopzy_rider/home/home_demo_data.dart';
import 'package:myshopzy_rider/home/home_page.dart';
import 'package:myshopzy_rider/orders/order_offer_page.dart';
import 'package:myshopzy_rider/orders/orders_page.dart';

void main() {
  testWidgets('home dashboard renders the local rider summary', (tester) async {
    await tester.pumpWidget(const RiderApp());

    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text("You're online"), findsOneWidget);
    expect(
      find.text("You're ready to receive delivery offers."),
      findsOneWidget,
    );
    expect(find.text("Today's summary"), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('₹650'), findsOneWidget);
    expect(find.text('18.6 km'), findsOneWidget);
    expect(find.text('4h 25m'), findsOneWidget);
  });

  testWidgets('online status can be toggled', (tester) async {
    await tester.pumpWidget(const RiderApp());

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text("You're offline"), findsOneWidget);
    expect(
      find.text("You're not available for new delivery offers."),
      findsOneWidget,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text("You're online"), findsOneWidget);
  });

  testWidgets('active delivery card shows its demo details', (tester) async {
    await tester.pumpWidget(const RiderApp());

    await _scrollHomeTo(tester, find.text('Active Delivery'));
    expect(find.text('#MS-2048'), findsOneWidget);
    expect(find.text('Fresh Basket'), findsNWidgets(2));
    expect(find.text('Ananya Reddy'), findsOneWidget);
    expect(find.text('12 Market Road'), findsOneWidget);
    expect(find.text('Lakshmi Nagar'), findsOneWidget);
    expect(find.text('On the Way'), findsOneWidget);
    expect(find.text('2.4 km'), findsOneWidget);
    expect(find.text('₹85'), findsNWidgets(2));
    expect(find.text('View Delivery'), findsOneWidget);
  });

  testWidgets('empty active delivery state is available for demo data', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore();
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomePage(
            availabilityStore: availabilityStore,
            offerStore: offerStore,
            demoData: HomeDemoData(activeDelivery: null),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await _scrollHomeTo(tester, find.text('No active delivery'));
    expect(find.text('No active delivery'), findsOneWidget);
    expect(
      find.text('Go online when you are ready to receive delivery offers.'),
      findsOneWidget,
    );
    await _scrollHomeToTop(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await _scrollHomeTo(tester, find.text('No active delivery'));
    expect(
      find.text('Stay online to receive nearby delivery offers.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('View Delivery opens existing delivery details', (tester) async {
    await tester.pumpWidget(const RiderApp());

    await _scrollHomeTo(tester, find.text('View Delivery'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Delivery'));
    await tester.pumpAndSettle();

    expect(find.text('Delivery details'), findsOneWidget);
    expect(find.text('Order #MS-2048'), findsOneWidget);
    expect(find.text('Fresh Basket'), findsOneWidget);
    expect(find.text('Lakshmi Nagar, Mandapeta'), findsOneWidget);
  });

  testWidgets('active delivery remains available when rider goes offline', (
    tester,
  ) async {
    await tester.pumpWidget(const RiderApp());
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text("You're offline"), findsOneWidget);
    await _scrollHomeTo(tester, find.text('#MS-2048'));
    expect(find.text('#MS-2048'), findsOneWidget);
    expect(find.text('View Delivery'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Delivery'));
    await tester.pumpAndSettle();
    expect(find.text('Delivery details'), findsOneWidget);
  });

  testWidgets('bottom navigation opens the requested sections', (tester) async {
    await tester.pumpWidget(const RiderApp());

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    expect(find.text("You're currently delivering"), findsOneWidget);

    await tester.tap(find.text('Earnings').last);
    await tester.pumpAndSettle();
    expect(find.text('Earnings breakdown'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Rider · Mandapeta'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text("You're offline"), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    expect(find.text("You're currently delivering"), findsOneWidget);
  });

  testWidgets('home quick actions open their destinations', (tester) async {
    await tester.pumpWidget(const RiderApp());

    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('home-action-Orders')),
    );
    await tester.tap(find.byKey(const ValueKey('home-action-Orders')));
    await tester.pumpAndSettle();
    expect(find.text("You're currently delivering"), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('home-action-History')),
    );
    await tester.tap(find.byKey(const ValueKey('home-action-History')));
    await tester.pumpAndSettle();
    expect(find.text('Delivery history'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('home-action-Earnings')),
    );
    await tester.tap(find.byKey(const ValueKey('home-action-Earnings')));
    await tester.pumpAndSettle();
    expect(find.text('Earnings breakdown'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('home-action-Help & Support')),
    );
    await tester.tap(find.byKey(const ValueKey('home-action-Help & Support')));
    await tester.pumpAndSettle();
    expect(find.text('Frequently asked'), findsOneWidget);
  });

  testWidgets('Home state stays intact across bottom tabs', (tester) async {
    await tester.pumpWidget(const RiderApp());
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    for (final tab in ['Orders', 'Earnings', 'Profile', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
    }

    expect(find.text("You're offline"), findsOneWidget);
    expect(
      find.text("You're not available for new delivery offers."),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text("You're online"), findsOneWidget);
  });

  testWidgets('offline rider cannot see a demo new-order offer', (
    tester,
  ) async {
    final harness = await _pumpOfferPage(
      tester,
      initialAvailability: AvailabilityStatus.offline,
      activeDelivery: null,
    );

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Go online to receive delivery offers.'), findsOneWidget);
    expect(find.text('New Delivery Offer'), findsNothing);
    expect(harness.offerStore.canShowOffer, isFalse);
    await _disposeOfferHarness(tester, harness);
  });

  testWidgets('online rider sees the local demo offer data', (tester) async {
    final harness = await _pumpOfferPage(tester, activeDelivery: null);

    expect(harness.offerStore.canShowOffer, isTrue);
    expect(find.text('New Delivery Offer'), findsNWidgets(2));
    expect(find.text('#MS-2051'), findsOneWidget);
    expect(find.text('Fresh Basket'), findsOneWidget);
    expect(find.text('Ananya Reddy'), findsOneWidget);
    expect(find.text('12 Market Road'), findsOneWidget);
    expect(find.text('Lakshmi Nagar'), findsOneWidget);
    expect(find.text('1.8 km away'), findsOneWidget);
    expect(find.text('2.4 km'), findsOneWidget);
    expect(find.text('4.2 km'), findsOneWidget);
    expect(find.text('₹95'), findsOneWidget);
    expect(find.text('Bike'), findsOneWidget);
    expect(find.text('ACCEPT'), findsOneWidget);
    expect(find.text('REJECT'), findsOneWidget);
    await _disposeOfferHarness(tester, harness);
  });

  testWidgets('accept marks rider busy and opens existing delivery details', (
    tester,
  ) async {
    final harness = await _pumpOfferPage(tester, activeDelivery: null);

    await tester.tap(find.text('ACCEPT'));
    await tester.pumpAndSettle();

    expect(harness.offerStore.status, OrderOfferStatus.accepted);
    expect(harness.offerStore.isBusy, isTrue);
    expect(harness.offerStore.activeDelivery?.orderId, '#MS-2051');
    expect(find.text('Delivery details'), findsOneWidget);
    expect(find.text('Order #MS-2051'), findsOneWidget);
    expect(find.text('₹ 95'), findsOneWidget);
    await _disposeOfferHarness(tester, harness);
  });

  testWidgets('reject hides offer and permits another demo offer', (
    tester,
  ) async {
    final harness = await _pumpOfferPage(tester, activeDelivery: null);

    await tester.tap(find.text('REJECT'));
    await tester.pumpAndSettle();

    expect(harness.offerStore.status, OrderOfferStatus.rejected);
    expect(harness.availabilityStore.isAvailable, isTrue);
    expect(find.text('Offer rejected'), findsNWidgets(2));
    expect(find.text('New Delivery Offer'), findsNothing);

    await tester.tap(find.text('Show another demo offer'));
    await tester.pumpAndSettle();

    expect(harness.offerStore.canShowOffer, isTrue);
    expect(find.text('New Delivery Offer'), findsNWidgets(2));
    await _disposeOfferHarness(tester, harness);
  });

  testWidgets('active delivery prevents another new offer', (tester) async {
    final harness = await _pumpOfferPage(
      tester,
      activeDelivery: DemoDelivery.batchThreeActive,
    );

    expect(find.text("You're currently delivering"), findsOneWidget);
    expect(
      find.text('Complete your current delivery to receive new offers.'),
      findsOneWidget,
    );
    expect(find.text('New Delivery Offer'), findsNothing);
    expect(harness.offerStore.canShowOffer, isFalse);
    await _disposeOfferHarness(tester, harness);
  });

  testWidgets('offer countdown expires and cannot be accepted', (tester) async {
    final harness = await _pumpOfferPage(
      tester,
      activeDelivery: null,
      offerDuration: const Duration(seconds: 3),
    );

    expect(find.text('3s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(harness.offerStore.status, OrderOfferStatus.expired);
    expect(find.text('Offer expired'), findsOneWidget);
    expect(find.text('No longer available'), findsOneWidget);
    expect(harness.offerStore.acceptOffer(), isFalse);
    expect(harness.offerStore.isBusy, isFalse);
    await _disposeOfferHarness(tester, harness);
  });

  testWidgets('offer countdown pauses while offline', (tester) async {
    final harness = await _pumpOfferPage(tester, activeDelivery: null);
    await tester.pump(const Duration(seconds: 1));
    expect(harness.offerStore.secondsRemaining, 19);

    harness.availabilityStore.setAvailable(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(harness.offerStore.secondsRemaining, 19);
    expect(harness.offerStore.status, OrderOfferStatus.available);
    expect(find.text("You're offline"), findsOneWidget);

    harness.availabilityStore.setAvailable(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(harness.offerStore.secondsRemaining, 18);
    await _disposeOfferHarness(tester, harness);
  });

  testWidgets('Orders links to an available demo offer', (tester) async {
    final availabilityStore = AvailabilityStore();
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: null,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: OrdersPage(
            availabilityStore: availabilityStore,
            offerStore: offerStore,
          ),
        ),
      ),
    );
    expect(find.text('New Delivery Offer'), findsOneWidget);

    await tester.tap(find.text('View offer'));
    await tester.pumpAndSettle();
    expect(find.text('ACCEPT'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('Home shows a compact offer only when eligible', (tester) async {
    final availabilityStore = AvailabilityStore();
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: null,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomePage(
            availabilityStore: availabilityStore,
            offerStore: offerStore,
            demoData: HomeDemoData(activeDelivery: null),
          ),
        ),
      ),
    );
    expect(find.text('New Delivery Offer'), findsOneWidget);

    availabilityStore.setAvailable(false);
    await tester.pump();
    expect(find.text('New Delivery Offer'), findsNothing);

    availabilityStore.setAvailable(true);
    await tester.pump();
    expect(find.text('New Delivery Offer'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('offer UI fits a 360x800 viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _pumpOfferPage(tester, activeDelivery: null);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('REJECT'));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('ACCEPT'));
    expect(tester.takeException(), isNull);
    await _disposeOfferHarness(tester, harness);
  });

  testWidgets('home dashboard fits a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RiderApp());
    expect(tester.takeException(), isNull);

    await _scrollHomeTo(tester, find.text('Quick actions'));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _scrollHomeTo(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 10 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
  }

  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _scrollHomeToTop(WidgetTester tester) async {
  for (
    var attempt = 0;
    attempt < 10 && find.byType(Switch).evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
  }

  expect(find.byType(Switch), findsOneWidget);
}

class _OfferHarness {
  const _OfferHarness({
    required this.availabilityStore,
    required this.offerStore,
  });

  final AvailabilityStore availabilityStore;
  final OrderOfferStore offerStore;
}

Future<_OfferHarness> _pumpOfferPage(
  WidgetTester tester, {
  AvailabilityStatus initialAvailability = AvailabilityStatus.available,
  DemoDelivery? activeDelivery = DemoDelivery.batchThreeActive,
  Duration offerDuration = const Duration(seconds: 20),
}) async {
  final availabilityStore = AvailabilityStore(
    initialStatus: initialAvailability,
  );
  final offerStore = OrderOfferStore(
    availabilityStore: availabilityStore,
    activeDelivery: activeDelivery,
    offerDuration: offerDuration,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: OrderOfferPage(offerStore: offerStore),
    ),
  );

  return _OfferHarness(
    availabilityStore: availabilityStore,
    offerStore: offerStore,
  );
}

Future<void> _disposeOfferHarness(
  WidgetTester tester,
  _OfferHarness harness,
) async {
  await tester.pumpWidget(const SizedBox());
  harness.offerStore.dispose();
  harness.availabilityStore.dispose();
}
