import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myshopzy_rider/app/rider_app.dart';
import 'package:myshopzy_rider/core/state/availability_store.dart';
import 'package:myshopzy_rider/core/state/new_order_alert.dart';
import 'package:myshopzy_rider/core/state/order_offer_store.dart';
import 'package:myshopzy_rider/core/models/demo_delivery.dart';
import 'package:myshopzy_rider/core/theme/app_theme.dart';
import 'package:myshopzy_rider/delivery/delivery_page.dart';
import 'package:myshopzy_rider/earnings/earnings_page.dart';
import 'package:myshopzy_rider/gigs/gigs_page.dart';
import 'package:myshopzy_rider/history/history_page.dart';
import 'package:myshopzy_rider/help_support/help_support_page.dart';
import 'package:myshopzy_rider/home/home_demo_data.dart';
import 'package:myshopzy_rider/home/home_page.dart';
import 'package:myshopzy_rider/orders/incoming_order_offer_dialog.dart';
import 'package:myshopzy_rider/orders/order_offer_page.dart';
import 'package:myshopzy_rider/orders/orders_page.dart';
import 'package:myshopzy_rider/profile/profile_page.dart';
import 'package:myshopzy_rider/settings/settings_page.dart';

void main() {
  testWidgets('home dashboard renders the local rider summary', (tester) async {
    await tester.pumpWidget(const RiderApp());

    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('MyShopzy'), findsNothing);
    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text("You're online"), findsOneWidget);
    expect(
      find.text("You're currently delivering; new offers are paused."),
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

  testWidgets('home shows disconnected status while duty remains enabled', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore();
    availabilityStore.setConnectivityAvailable(false);
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomePage(
          availabilityStore: availabilityStore,
          offerStore: offerStore,
        ),
      ),
    );

    expect(find.text('Connection lost'), findsOneWidget);
    expect(
      find.text(
        "You're on duty, but new offers are paused until you're reconnected.",
      ),
      findsOneWidget,
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    availabilityStore.setConnectivityAvailable(true);
    await tester.pump();
    expect(find.text("You're online"), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('active delivery card shows its demo details', (tester) async {
    await tester.pumpWidget(const RiderApp());

    await _scrollHomeTo(tester, find.text('Current Delivery'));
    expect(find.text('#MS-2048'), findsOneWidget);
    expect(find.text('Going to Customer'), findsOneWidget);
    expect(find.text('Continue Delivery'), findsOneWidget);
    expect(find.text('Quick actions'), findsNothing);
    expect(find.text('Recent Delivery'), findsNothing);
  });

  testWidgets('empty active delivery state is available for demo data', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore();
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: null,
    );
    expect(offerStore.rejectOffer(), isTrue);

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
    expect(find.text('Go online to receive new orders.'), findsOneWidget);
    await _scrollHomeToTop(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for new orders'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('Continue Delivery opens active delivery details', (
    tester,
  ) async {
    await tester.pumpWidget(const RiderApp());

    await _scrollHomeTo(tester, find.text('Continue Delivery'));
    await tester.tap(find.text('Continue Delivery'));
    await tester.pumpAndSettle();

    expect(find.text('Delivery details'), findsOneWidget);
    expect(find.text('Order #MS-2048'), findsOneWidget);
    expect(find.text('Fresh Basket'), findsOneWidget);
    expect(find.text('Lakshmi Nagar, Mandapeta'), findsOneWidget);
  });

  testWidgets('eligible new offer opens popup and accepts into delivery flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const RiderApp());

    await _scrollHomeTo(tester, find.text('Continue Delivery'));
    await tester.tap(find.text('Continue Delivery'));
    await tester.pumpAndSettle();
    final reachedCustomerButton = find.widgetWithText(
      FilledButton,
      'Reached Customer',
    );
    await tester.dragFrom(const Offset(180, 700), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.ensureVisible(reachedCustomerButton);
    await tester.pumpAndSettle();
    await tester.tap(reachedCustomerButton);
    await tester.pumpAndSettle();
    final handOverButton = find.widgetWithText(FilledButton, 'Hand Over');
    await tester.dragFrom(const Offset(180, 700), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.ensureVisible(handOverButton);
    await tester.pumpAndSettle();
    await tester.tap(handOverButton);
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(180, 700), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mark Delivered'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark Delivered'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check for demo offer'));
    await tester.pumpAndSettle();
    expect(find.text('NEW ORDER'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('NEW ORDER'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('incoming-order-accept')));
    await tester.pumpAndSettle();
    expect(find.text('Delivery details'), findsOneWidget);
    expect(find.text('Order #MS-2051'), findsOneWidget);
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
    expect(find.text('Continue Delivery'), findsOneWidget);
    await tester.tap(find.text('Continue Delivery'));
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
    expect(find.text("TODAY'S EARNINGS"), findsOneWidget);

    await tester.tap(find.text('Gigs').last);
    await tester.pumpAndSettle();
    expect(find.text('Book a gig slot'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Rider ID: RDR-1001'), findsOneWidget);
    expect(find.text('My Gigs'), findsNothing);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text("You're offline"), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    expect(find.text("You're currently delivering"), findsOneWidget);
  });

  testWidgets('Gigs navigation permits booking multiple available slots', (
    tester,
  ) async {
    await tester.pumpWidget(const RiderApp());
    await tester.tap(find.text('Gigs').last);
    await tester.pumpAndSettle();

    expect(find.text('7:00–10:00'), findsOneWidget);
    expect(find.text('10:00–12:00'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gig-book-0')));
    await tester.pumpAndSettle();
    expect(find.text('Gig booked for 7:00–10:00.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('gig-book-0')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('gig-book-1')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('gig-book-1')));
    await tester.pumpAndSettle();
    expect(find.text('2 booked'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('gig-book-2')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('gig booking follows duty status, not connectivity', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore();
    availabilityStore.setConnectivityAvailable(false);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GigsPage(availabilityStore: availabilityStore),
      ),
    );

    expect(find.text('No internet connection'), findsNothing);
    expect(find.text("You're offline"), findsNothing);
    expect(find.text('Reconnect to book'), findsNothing);
    final bookingButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('gig-book-0')),
    );
    expect(bookingButton.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('gig-book-0')));
    await tester.pumpAndSettle();
    expect(find.text('Gig booked for 7:00–10:00.'), findsOneWidget);

    availabilityStore.setAvailable(false);
    await tester.pump();
    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Go online to book'), findsNWidgets(4));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('gig-book-1')))
          .onPressed,
      isNull,
    );

    availabilityStore.setAvailable(true);
    await tester.pump();
    expect(find.text("You're offline"), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('gig-book-1')))
          .onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox());
    availabilityStore.dispose();
  });

  testWidgets('gig API error is shown without disabling online booking', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore();
    availabilityStore.apiErrorMessage = 'Unable to update duty status.';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GigsPage(availabilityStore: availabilityStore),
      ),
    );

    expect(find.text('Unable to sync with server'), findsOneWidget);
    expect(find.text('Unable to update duty status.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('gig-book-0')))
          .onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox());
    availabilityStore.dispose();
  });

  test('demo offer is restored when no offer is currently assigned', () {
    final availabilityStore = AvailabilityStore();
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: null,
      offer: null,
    );

    final initialRevision = offerStore.offerRevision;
    expect(offerStore.showAnotherDemoOffer(), isTrue);
    expect(offerStore.offerRevision, initialRevision + 1);
    expect(offerStore.offer?.orderId, '#MS-2051');
    expect(offerStore.canShowOffer, isTrue);

    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets(
    'home header shows the dynamic rider without the brand wordmark',
    (tester) async {
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
              demoData: HomeDemoData(
                riderName: 'Mina Rao',
                activeDelivery: null,
              ),
            ),
          ),
        ),
      );

      expect(find.text('MyShopzy'), findsNothing);
      expect(find.text('Mina Rao'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      offerStore.dispose();
      availabilityStore.dispose();
    },
  );

  testWidgets(
    'incoming offer popup displays order data and accepts via store',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final availabilityStore = AvailabilityStore();
      final offerStore = OrderOfferStore(
        availabilityStore: availabilityStore,
        activeDelivery: null,
      );
      await _pumpIncomingOfferDialog(tester, offerStore);

      expect(find.text('NEW ORDER'), findsOneWidget);
      expect(find.text('#MS-2051'), findsOneWidget);
      expect(find.text('₹40'), findsOneWidget);
      expect(find.text('Fresh Basket'), findsOneWidget);
      expect(find.text('12 Market Road'), findsWidgets);
      expect(find.text('Lakshmi Nagar'), findsWidgets);
      expect(find.text('Pickup · 1.8 km'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('incoming-order-accept')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('incoming-order-accept')));
      await tester.pumpAndSettle();
      expect(offerStore.status, OrderOfferStatus.accepted);
      expect(offerStore.activeDelivery?.orderId, '#MS-2051');
      await tester.pumpWidget(const SizedBox());
      offerStore.dispose();
      availabilityStore.dispose();
    },
  );

  testWidgets('incoming offer popup rejects through the existing store', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore();
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: null,
    );
    await _pumpIncomingOfferDialog(tester, offerStore);

    await tester.tap(find.byKey(const ValueKey('incoming-order-reject')));
    await tester.pumpAndSettle();
    expect(offerStore.status, OrderOfferStatus.rejected);
    expect(offerStore.activeDelivery, isNull);
    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('incoming alert repeats until its 30-second window ends', (
    tester,
  ) async {
    var playCount = 0;
    var stopCount = 0;
    var activePlayers = 0;
    var maxActivePlayers = 0;
    final alert = NewOrderAlert(
      stopSound: () async {
        stopCount++;
      },
      playSound: () async {
        playCount++;
        activePlayers++;
        if (activePlayers > maxActivePlayers) {
          maxActivePlayers = activePlayers;
        }
        await Future<void>.delayed(const Duration(seconds: 8));
        activePlayers--;
      },
    );

    alert.start('#MS-2051');
    await tester.pump();
    expect(playCount, 1);

    await tester.pump(const Duration(seconds: 8));
    expect(playCount, 2);
    await tester.pump(const Duration(seconds: 8));
    expect(playCount, 3);
    await tester.pump(const Duration(seconds: 8));
    expect(playCount, 4);
    await tester.pump(const Duration(seconds: 5, milliseconds: 999));
    expect(stopCount, 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(stopCount, 1);
    expect(playCount, 4);
    await tester.pump(const Duration(seconds: 5));
    expect(playCount, 4);
    expect(maxActivePlayers, 1);
    await alert.dispose();
  });

  testWidgets('incoming alert stops early and ignores duplicate order IDs', (
    tester,
  ) async {
    var playCount = 0;
    var stopCount = 0;
    final alert = NewOrderAlert(
      stopSound: () async {
        stopCount++;
      },
      playSound: () async {
        playCount++;
        await Future<void>.delayed(const Duration(seconds: 10));
      },
    );

    alert.start('#MS-2051');
    await tester.pump();
    expect(playCount, 1);

    await tester.pump(const Duration(seconds: 2));
    await alert.stop();
    expect(stopCount, 1);
    alert.start('#MS-2051');
    await tester.pump();
    expect(playCount, 1);

    alert.start('#MS-2052');
    await tester.pump();
    expect(playCount, 2);
    await alert.dispose();
    expect(stopCount, 2);
    await tester.pump(const Duration(seconds: 10));
    expect(playCount, 2);
  });

  testWidgets('incoming alert repeats for a new revision of the same order', (
    tester,
  ) async {
    var playCount = 0;
    var stopCount = 0;
    final alert = NewOrderAlert(
      stopSound: () async {
        stopCount++;
      },
      playSound: () async {
        playCount++;
        await Future<void>.delayed(const Duration(seconds: 10));
      },
    );

    alert.start('#MS-2051:0');
    await tester.pump();
    expect(playCount, 1);

    alert.start('#MS-2051:1');
    await tester.pump();
    expect(stopCount, 1);
    expect(playCount, 2);

    await alert.dispose();
    await tester.pump(const Duration(seconds: 10));
    expect(playCount, 2);
  });

  testWidgets('home omits duplicate shortcuts and recent delivery', (
    tester,
  ) async {
    await tester.pumpWidget(const RiderApp());
    expect(find.text('Quick actions'), findsNothing);
    expect(find.text('Recent Delivery'), findsNothing);
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

  test('order acceptance requires duty status and network connectivity', () {
    final offlineDutyStore = AvailabilityStore(
      initialStatus: AvailabilityStatus.offline,
    );
    final offlineDutyOfferStore = OrderOfferStore(
      availabilityStore: offlineDutyStore,
      activeDelivery: null,
    );

    expect(offlineDutyStore.isConnected, isTrue);
    expect(offlineDutyOfferStore.canAccept, isFalse);
    expect(offlineDutyOfferStore.acceptOffer(), isFalse);
    expect(offlineDutyOfferStore.activeDelivery, isNull);

    final disconnectedStore = AvailabilityStore();
    disconnectedStore.setConnectivityAvailable(false);
    final disconnectedOfferStore = OrderOfferStore(
      availabilityStore: disconnectedStore,
      activeDelivery: null,
    );

    expect(disconnectedStore.isAvailable, isTrue);
    expect(disconnectedOfferStore.canAccept, isFalse);
    expect(disconnectedOfferStore.acceptOffer(), isFalse);
    expect(disconnectedOfferStore.activeDelivery, isNull);

    offlineDutyOfferStore.dispose();
    offlineDutyStore.dispose();
    disconnectedOfferStore.dispose();
    disconnectedStore.dispose();
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
    expect(find.text('Payout breakdown: Base: ₹40'), findsOneWidget);
    expect(find.text('₹40'), findsOneWidget);
    expect(find.text('Bike'), findsOneWidget);
    expect(find.text('ACCEPT'), findsOneWidget);
    expect(find.text('REJECT'), findsOneWidget);
    await _disposeOfferHarness(tester, harness);
  });

  testWidgets('accept marks rider busy and opens existing delivery details', (
    tester,
  ) async {
    final harness = await _pumpOfferPage(tester, activeDelivery: null);

    await tester.ensureVisible(find.text('ACCEPT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ACCEPT'));
    await tester.pumpAndSettle();

    expect(harness.offerStore.status, OrderOfferStatus.accepted);
    expect(harness.offerStore.isBusy, isTrue);
    expect(harness.offerStore.activeDelivery?.orderId, '#MS-2051');
    expect(harness.offerStore.pickupStatus, PickupStatus.goingToPickup);
    expect(find.text('Delivery details'), findsOneWidget);
    expect(find.text('Going to Pickup'), findsOneWidget);
    expect(find.textContaining('12 Market Road'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Reached Store'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Reached Store'), findsOneWidget);
    expect(find.text('1.8 km away'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(find.text('Order #MS-2051'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('₹ 40'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('₹ 40'), findsOneWidget);
    await _disposeOfferHarness(tester, harness);
  });

  testWidgets(
    'pickup and customer flow uses only the required explicit actions',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final availabilityStore = AvailabilityStore();
      final offerStore = OrderOfferStore(
        availabilityStore: availabilityStore,
        activeDelivery: null,
      );
      expect(offerStore.reachStore(DemoDelivery.newOffer), isFalse);
      expect(offerStore.acceptOffer(), isTrue);
      final delivery = offerStore.activeDelivery!;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: DeliveryPage(delivery: delivery, offerStore: offerStore),
        ),
      );

      expect(offerStore.pickupStatus, PickupStatus.goingToPickup);
      expect(offerStore.openOrderDetails(delivery), isFalse);
      expect(offerStore.verifyPickup(delivery, '2051'), isFalse);
      expect(offerStore.reachStore(DemoDelivery.batchThreeActive), isFalse);
      expect(offerStore.completeActiveDelivery(delivery), isFalse);
      expect(offerStore.isBusy, isTrue);
      expect(offerStore.showAnotherDemoOffer(), isFalse);
      expect(find.text('Going to Pickup'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Reached Store'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Reached Store'));
      await tester.pumpAndSettle();
      expect(offerStore.pickupStatus, PickupStatus.reachedPickup);
      expect(find.text('Reached Store'), findsOneWidget);
      expect(find.text('Order Details'), findsWidgets);
      expect(tester.takeException(), isNull);

      availabilityStore.setAvailable(false);
      await tester.pumpAndSettle();
      expect(offerStore.activeDelivery, same(delivery));
      expect(offerStore.pickupStatus, PickupStatus.reachedPickup);
      expect(offerStore.isBusy, isTrue);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Order Details'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Order Details'));
      await tester.pumpAndSettle();
      expect(offerStore.pickupStatus, PickupStatus.orderDetails);
      expect(find.text('Order Details'), findsWidgets);
      final verifyButton = find.widgetWithText(FilledButton, 'Verify Pickup');
      await tester.drag(find.byType(ListView).last, const Offset(0, -350));
      await tester.pumpAndSettle();
      await tester.ensureVisible(verifyButton);
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();
      expect(find.text('Enter the last 4 digits.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '1234');
      await tester.drag(find.byType(ListView).last, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.ensureVisible(verifyButton);
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();
      expect(find.text('Those digits do not match the order.'), findsOneWidget);
      expect(offerStore.pickupStatus, PickupStatus.orderDetails);
      expect(offerStore.verifyPickup(delivery, '20a51'), isFalse);

      await tester.enterText(find.byType(TextFormField), '2051');
      await tester.drag(find.byType(ListView).last, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.ensureVisible(verifyButton);
      await tester.tap(verifyButton);
      await tester.pumpAndSettle();
      expect(offerStore.pickupStatus, PickupStatus.pickedUp);
      expect(find.text('Pickup Confirmed'), findsWidgets);
      expect(find.text('Start Delivery'), findsOneWidget);
      expect(offerStore.isBusy, isTrue);
      expect(offerStore.showAnotherDemoOffer(), isFalse);
      expect(offerStore.completeActiveDelivery(delivery), isFalse);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Start Delivery'));
      await tester.tap(find.text('Start Delivery'));
      await tester.pumpAndSettle();
      expect(offerStore.pickupStatus, PickupStatus.onTheWay);
      expect(find.text('Going to Customer'), findsOneWidget);
      expect(find.text('Customer: Ananya Reddy'), findsOneWidget);
      expect(offerStore.completeActiveDelivery(delivery), isFalse);
      expect(offerStore.isBusy, isTrue);
      expect(tester.takeException(), isNull);

      expect(find.text('Reached Customer'), findsOneWidget);
      expect(offerStore.isBusy, isTrue);
      expect(offerStore.canAccept, isFalse);
      expect(offerStore.acceptOffer(), isFalse);
      expect(offerStore.showAnotherDemoOffer(), isFalse);
      expect(tester.takeException(), isNull);

      expect(offerStore.completeActiveDelivery(delivery), isFalse);
      await tester.dragFrom(const Offset(180, 650), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reached Customer'));
      await tester.pumpAndSettle();
      expect(offerStore.deliveryStatus, DeliveryStatus.reachedCustomer);
      expect(offerStore.isBusy, isTrue);
      expect(offerStore.showAnotherDemoOffer(), isFalse);
      expect(find.text('Customer & Order Details'), findsOneWidget);
      expect(find.text('Hand Over'), findsOneWidget);
      await tester.tap(find.text('Hand Over'));
      await tester.pumpAndSettle();
      expect(offerStore.deliveryStatus, DeliveryStatus.handOver);
      expect(offerStore.isBusy, isTrue);
      expect(offerStore.showAnotherDemoOffer(), isFalse);
      expect(find.text('Mark Delivered'), findsOneWidget);
      await _scrollDeliveryActionIntoView(tester, find.text('Mark Delivered'));
      await tester.tap(find.text('Mark Delivered'));
      await tester.pumpAndSettle();
      expect(offerStore.deliveryStatus, DeliveryStatus.delivered);
      expect(offerStore.activeDelivery, isNull);
      expect(offerStore.isBusy, isFalse);
      expect(offerStore.completeActiveDelivery(delivery), isFalse);
      expect(availabilityStore.isAvailable, isFalse);
      expect(offerStore.showAnotherDemoOffer(), isFalse);
      expect(find.text('Delivery completed successfully.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      offerStore.dispose();
      availabilityStore.dispose();
    },
  );

  testWidgets('pickup state persists across tabs and delivery navigation', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore();
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: null,
    );
    expect(offerStore.acceptOffer(), isTrue);
    final delivery = offerStore.activeDelivery!;
    expect(offerStore.reachStore(delivery), isTrue);
    var selectedTab = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                Row(
                  children: [
                    TextButton(
                      key: const ValueKey('tab-home'),
                      onPressed: () => setState(() => selectedTab = 0),
                      child: const Text('Home tab'),
                    ),
                    TextButton(
                      key: const ValueKey('tab-orders'),
                      onPressed: () => setState(() => selectedTab = 1),
                      child: const Text('Orders tab'),
                    ),
                  ],
                ),
                Expanded(
                  child: IndexedStack(
                    index: selectedTab,
                    children: [
                      HomePage(
                        availabilityStore: availabilityStore,
                        offerStore: offerStore,
                        demoData: HomeDemoData(activeDelivery: null),
                      ),
                      OrdersPage(
                        availabilityStore: availabilityStore,
                        offerStore: offerStore,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await _scrollHomeTo(tester, find.text('Continue Delivery'));
    await tester.tap(find.text('Continue Delivery'));
    await tester.pumpAndSettle();
    expect(find.text('Reached Store'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tab-orders')));
    await tester.pumpAndSettle();
    expect(find.text('Status: Reached Store'), findsOneWidget);
    expect(find.text('New Delivery Offer'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await tester.pumpAndSettle();
    await _scrollHomeTo(tester, find.text('Continue Delivery'));
    await tester.tap(find.text('Continue Delivery'));
    await tester.pumpAndSettle();
    expect(find.text('Reached Store'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('delivery stage persists across tabs and navigation', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore();
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: null,
    );
    expect(offerStore.acceptOffer(), isTrue);
    final delivery = offerStore.activeDelivery!;
    _advancePickupToPickedUp(offerStore);
    expect(offerStore.continueToDelivery(delivery), isTrue);
    expect(offerStore.arriveAtCustomer(delivery), isTrue);
    var selectedTab = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                Row(
                  children: [
                    TextButton(
                      key: const ValueKey('delivery-tab-home'),
                      onPressed: () => setState(() => selectedTab = 0),
                      child: const Text('Home tab'),
                    ),
                    TextButton(
                      key: const ValueKey('delivery-tab-orders'),
                      onPressed: () => setState(() => selectedTab = 1),
                      child: const Text('Orders tab'),
                    ),
                  ],
                ),
                Expanded(
                  child: IndexedStack(
                    index: selectedTab,
                    children: [
                      HomePage(
                        availabilityStore: availabilityStore,
                        offerStore: offerStore,
                        demoData: HomeDemoData(activeDelivery: null),
                      ),
                      OrdersPage(
                        availabilityStore: availabilityStore,
                        offerStore: offerStore,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('delivery-tab-orders')));
    await tester.pumpAndSettle();
    expect(find.text('Status: Reached Customer'), findsOneWidget);
    expect(offerStore.isBusy, isTrue);
    expect(offerStore.canAccept, isFalse);
    expect(find.text('New Delivery Offer'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('delivery-tab-home')));
    await tester.pumpAndSettle();
    await _scrollHomeTo(tester, find.text('Continue Delivery'));
    await tester.tap(find.text('Continue Delivery'));
    await tester.pumpAndSettle();
    expect(find.text('Reached Customer'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Customer & Order Details'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Customer & Order Details'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    availabilityStore.setAvailable(false);
    await tester.pumpAndSettle();
    expect(offerStore.activeDelivery, same(delivery));
    expect(offerStore.deliveryStatus, DeliveryStatus.reachedCustomer);
    expect(offerStore.isBusy, isTrue);
    expect(offerStore.handOverOrder(delivery), isTrue);

    await tester.tap(find.byKey(const ValueKey('delivery-tab-orders')));
    await tester.pumpAndSettle();
    expect(find.text('Status: Hand Over'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('delivery-tab-home')));
    await tester.pumpAndSettle();
    await _scrollHomeTo(tester, find.text('Continue Delivery'));
    expect(find.text('Hand Over'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('reject hides offer and permits another demo offer', (
    tester,
  ) async {
    final harness = await _pumpOfferPage(tester, activeDelivery: null);

    await tester.ensureVisible(find.text('REJECT'));
    await tester.pumpAndSettle();
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
    expect(harness.offerStore.showAnotherDemoOffer(), isFalse);
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
    expect(harness.availabilityStore.isAvailable, isTrue);
    expect(harness.offerStore.showAnotherDemoOffer(), isTrue);
    expect(harness.offerStore.status, OrderOfferStatus.available);
    await _disposeOfferHarness(tester, harness);
  });

  testWidgets('accepted delivery stays busy across Home and Orders', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore();
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: null,
    );

    expect(offerStore.acceptOffer(), isTrue);
    expect(offerStore.status, OrderOfferStatus.accepted);
    expect(offerStore.activeDelivery?.orderId, '#MS-2051');
    expect(offerStore.showAnotherDemoOffer(), isFalse);

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
    expect(
      find.text("You're currently delivering; new offers are paused."),
      findsOneWidget,
    );
    expect(find.text('#MS-2051'), findsOneWidget);
    expect(find.text('New order offer'), findsNothing);

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
    expect(find.text("You're currently delivering"), findsOneWidget);
    expect(find.text('New Delivery Offer'), findsNothing);

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
    expect(find.text('#MS-2051'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('completing delivery clears Busy and preserves Online', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore();
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: DemoDelivery.newOffer,
    );
    _advanceActiveDeliveryToConfirmation(offerStore);
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

    await _scrollHomeTo(tester, find.text('Continue Delivery'));
    await tester.tap(find.text('Continue Delivery'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Mark Delivered'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mark Delivered'));
    await tester.pumpAndSettle();

    expect(offerStore.activeDelivery, isNull);
    expect(offerStore.status, OrderOfferStatus.noOffer);
    expect(offerStore.isBusy, isFalse);
    expect(availabilityStore.isAvailable, isTrue);
    expect(offerStore.showAnotherDemoOffer(), isTrue);
    expect(offerStore.status, OrderOfferStatus.available);
    await _scrollHomeTo(tester, find.text('Waiting for new orders'));
    expect(find.text("You're currently delivering"), findsNothing);
    expect(find.text('Delivery marked complete'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('completing delivery preserves Offline availability', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore(
      initialStatus: AvailabilityStatus.offline,
    );
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: DemoDelivery.newOffer,
    );
    _advanceActiveDeliveryToConfirmation(offerStore);
    await _pumpDeliveryEntry(tester, offerStore);

    await tester.tap(find.text('Open delivery'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Mark Delivered'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mark Delivered'));
    await tester.pumpAndSettle();

    expect(offerStore.activeDelivery, isNull);
    expect(offerStore.status, OrderOfferStatus.noOffer);
    expect(offerStore.isBusy, isFalse);
    expect(availabilityStore.isAvailable, isFalse);
    expect(offerStore.showAnotherDemoOffer(), isFalse);
    expect(offerStore.completeActiveDelivery(DemoDelivery.newOffer), isFalse);
    expect(find.text('Delivery marked complete'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
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

  testWidgets('Orders shows Busy and Offline without offer messaging', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore(
      initialStatus: AvailabilityStatus.offline,
    );
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: DemoDelivery.batchThreeActive,
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

    expect(find.text("You're currently delivering"), findsOneWidget);
    expect(
      find.text("You're offline; your current delivery remains active."),
      findsOneWidget,
    );
    expect(find.text('Ready for delivery offers'), findsNothing);
    expect(find.text('New order offer'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('Home shows full offer only when online and eligible', (
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
    expect(find.text('New order offer'), findsOneWidget);
    expect(find.text('#MS-2051'), findsOneWidget);
    expect(find.text('Fresh Basket'), findsOneWidget);
    expect(find.text('12 Market Road'), findsOneWidget);
    expect(find.text('Lakshmi Nagar'), findsOneWidget);
    expect(find.text('1.8 km'), findsOneWidget);
    expect(find.text('2.4 km'), findsOneWidget);
    expect(find.text('4.2 km'), findsOneWidget);
    expect(find.text('Base: ₹40'), findsOneWidget);
    expect(find.text('₹40'), findsOneWidget);
    expect(find.text('Bike'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    availabilityStore.setAvailable(false);
    await tester.pump();
    expect(find.text('New order offer'), findsNothing);
    expect(offerStore.canAccept, isFalse);
    expect(offerStore.acceptOffer(), isFalse);

    availabilityStore.setAvailable(true);
    await tester.pump();
    expect(find.text('New order offer'), findsOneWidget);
    await _scrollHomeTo(tester, find.text('Reject'));
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    expect(offerStore.status, OrderOfferStatus.rejected);
    expect(offerStore.activeDelivery, isNull);
    expect(availabilityStore.isAvailable, isTrue);
    expect(find.text('New order offer'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('Home accepts the new order and prioritizes active delivery', (
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
        home: HomePage(
          availabilityStore: availabilityStore,
          offerStore: offerStore,
          demoData: HomeDemoData(activeDelivery: null),
        ),
      ),
    );

    await _scrollHomeTo(tester, find.text('Accept'));
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.text('Delivery details'), findsOneWidget);
    expect(offerStore.activeDelivery?.orderId, '#MS-2051');
    expect(offerStore.isBusy, isTrue);
    expect(offerStore.canShowOffer, isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Current Delivery'), findsOneWidget);
    expect(find.text('New order offer'), findsNothing);

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

  testWidgets('delivery completion action fits a 360x800 viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final availabilityStore = AvailabilityStore();
    final offerStore = OrderOfferStore(
      availabilityStore: availabilityStore,
      activeDelivery: DemoDelivery.newOffer,
    );
    _advanceActiveDeliveryToConfirmation(offerStore);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DeliveryPage(
            delivery: DemoDelivery.newOffer,
            offerStore: offerStore,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Mark Delivered'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Mark Delivered'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    offerStore.dispose();
    availabilityStore.dispose();
  });

  testWidgets('profile renders demo identity, performance, and verification', (
    tester,
  ) async {
    final availabilityStore = await _pumpProfilePage(tester);

    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.text('Rider ID: RDR-1001'), findsOneWidget);
    expect(find.text('+91 98765 43210'), findsWidgets);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('VERIFIED'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('4.8 ⭐'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('4.8 ⭐'), findsOneWidget);
    expect(find.text('1,248'), findsOneWidget);
    expect(find.text('1,220'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('₹1,24,800'), findsOneWidget);
    expect(find.text('186 deliveries'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Emergency Contact Number'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Alternate Number'), findsOneWidget);
    expect(find.text('+91 91234 56789'), findsOneWidget);
    expect(find.text('Suresh Kumar'), findsOneWidget);
    expect(find.text('+91 99887 77665'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Aadhaar ID'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('XXXX XXXX 1234'), findsOneWidget);
    expect(find.text('Bike'), findsOneWidget);
    expect(find.text('AP 05 XX 1234'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Account Status'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Availability'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    availabilityStore.setAvailable(false);
    await tester.pumpAndSettle();
    expect(find.text('Offline'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    availabilityStore.dispose();
  });

  testWidgets('profile SOS stays demo-only and can be cancelled', (
    tester,
  ) async {
    final availabilityStore = await _pumpProfilePage(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-trigger-sos')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('profile-trigger-sos')));
    await tester.pumpAndSettle();
    expect(find.text('Emergency Assistance'), findsOneWidget);
    expect(find.text('Are you sure you want to trigger SOS?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('SOS request recorded for demo.'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-trigger-sos')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-trigger-sos')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trigger SOS'));
    await tester.pumpAndSettle();
    expect(find.text('SOS request recorded for demo.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    availabilityStore.dispose();
  });

  testWidgets('profile edits only local editable fields', (tester) async {
    final availabilityStore = await _pumpProfilePage(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-edit')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('profile-edit')));
    await tester.tap(find.byKey(const ValueKey('profile-edit')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsNWidgets(2));
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text('Rider ID'), findsNothing);
    expect(find.text('Aadhaar ID'), findsNothing);
    expect(find.text('Overall rating'), findsNothing);
    expect(find.text('Total deliveries'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-name')),
      'Ravi Demo',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-alternate')),
      '+91 90000 00000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-emergency-contact')),
      'Kiran Kumar',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-emergency-number')),
      '+91 91111 11111',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('edit-profile-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-profile-save')));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(find.text('Ravi Demo'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Alternate Number'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('+91 90000 00000'), findsOneWidget);
    expect(find.text('Kiran Kumar'), findsOneWidget);
    expect(find.text('+91 91111 11111'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    availabilityStore.dispose();
  });

  testWidgets('profile opens existing Settings and Help destinations', (
    tester,
  ) async {
    final availabilityStore = await _pumpProfilePage(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-settings')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Order Alerts'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-help')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-help')));
    await tester.pumpAndSettle();
    expect(find.text('Help & support'), findsOneWidget);
    expect(find.text('Frequently asked'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    availabilityStore.dispose();
  });

  testWidgets(
    'profile emergency call, legal, and logout actions stay demo-only',
    (tester) async {
      final availabilityStore = await _pumpProfilePage(tester);

      await tester.scrollUntilVisible(
        find.text('Call Emergency Contact'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Call Emergency Contact'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Call Emergency Contact'));
      await tester.pumpAndSettle();
      expect(find.text('Demo action'), findsOneWidget);
      expect(
        find.text('Calls are not connected in this demo.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      for (final title in ['Privacy Policy', 'Terms & Conditions']) {
        await tester.scrollUntilVisible(
          find.text(title),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text(title));
        await tester.pumpAndSettle();
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        expect(find.text(title), findsNWidgets(2));
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('profile-logout')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('profile-logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-logout')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Authentication will be connected in a future backend phase.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      availabilityStore.dispose();
    },
  );

  testWidgets('profile fits common phone viewports', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final viewport in [const Size(360, 800), const Size(390, 844)]) {
      tester.view.physicalSize = viewport;
      final availabilityStore = await _pumpProfilePage(tester);

      expect(tester.takeException(), isNull);
      for (final target in [
        find.text('Rider performance'),
        find.text('Personal information'),
        find.text('Verification details'),
        find.text('Safety & emergency'),
        find.text('Account'),
        find.text('Legal'),
        find.byKey(const ValueKey('profile-logout')),
      ]) {
        await tester.scrollUntilVisible(
          target,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(const SizedBox());
      availabilityStore.dispose();
    }
  });

  testWidgets('home dashboard fits a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RiderApp());
    expect(tester.takeException(), isNull);

    expect(find.text('Quick actions'), findsNothing);
    expect(find.text('Recent Delivery'), findsNothing);
    expect(find.text("Today's summary"), findsOneWidget);
    expect(find.text('Continue Delivery'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('earnings dashboard renders summary and recent deliveries', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: EarningsPage()));

    expect(find.text('₹650'), findsNWidgets(2));
    expect(find.text('₹3,850'), findsNWidgets(2));
    expect(find.text('₹18,420'), findsNWidgets(2));
    expect(find.text('₹1,24,800'), findsOneWidget);
    expect(find.text('1,220'), findsOneWidget);
    expect(find.text('₹102'), findsOneWidget);
    expect(find.text('Earnings breakdown'), findsOneWidget);
    expect(find.text('742 km'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('#MS-2051'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('#MS-2051'), findsOneWidget);
    expect(find.text('Fresh Basket'), findsWidgets);
    expect(find.text('Today • 2:40 PM'), findsOneWidget);
    expect(find.text('4.2 km'), findsOneWidget);
  });

  testWidgets('history status and time filters filter local demo records', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HistoryPage()));

    expect(find.text('#MS-2051'), findsOneWidget);
    expect(find.text('#MS-2042'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('history-status-completed')));
    await tester.pumpAndSettle();
    expect(find.text('#MS-2051'), findsOneWidget);
    expect(find.text('#MS-2042'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('history-period-today')));
    await tester.pumpAndSettle();
    expect(find.text('#MS-2040'), findsNothing);
    expect(find.text('#MS-2051'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('history-period-thisWeek')));
    await tester.pumpAndSettle();
    expect(find.text('#MS-2040'), findsOneWidget);
    expect(find.text('#MS-2038'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('history-period-thisMonth')));
    await tester.pumpAndSettle();
    expect(find.text('#MS-2038'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('history-status-cancelled')));
    await tester.pumpAndSettle();
    expect(find.text('#MS-2042'), findsOneWidget);
    expect(find.text('#MS-2036'), findsOneWidget);
    expect(find.text('#MS-2051'), findsNothing);
  });

  testWidgets('history opens completed and cancelled detail records', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HistoryPage()));

    await tester.tap(find.byKey(const ValueKey('history-record-#MS-2051')));
    await tester.pumpAndSettle();
    expect(find.text('Delivery details'), findsOneWidget);
    expect(find.text('Ananya Reddy'), findsOneWidget);
    expect(find.text('12 Market Road'), findsOneWidget);
    expect(find.text('Lakshmi Nagar'), findsOneWidget);
    expect(find.text('Delivered'), findsWidgets);
    expect(find.text('₹95'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-status-cancelled')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-record-#MS-2042')));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsWidgets);
    expect(find.text('₹0'), findsOneWidget);
  });

  testWidgets('earnings history navigation remains available', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EarningsPage()));

    await tester.tap(find.byTooltip('Delivery history'));
    await tester.pumpAndSettle();

    expect(find.text('Delivery history'), findsOneWidget);
    expect(find.text('Completed Deliveries'), findsOneWidget);
  });

  testWidgets('earnings and history fit common phone viewports', (
    tester,
  ) async {
    for (final viewport in [const Size(360, 800), const Size(390, 844)]) {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(const MaterialApp(home: EarningsPage()));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const MaterialApp(home: HistoryPage()));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('settings shows local preferences and demo app information', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

    expect(find.text('APP PREFERENCES'), findsOneWidget);
    expect(find.text('Order Alerts'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('MyShopzy Rider'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);
    expect(find.text('Not Connected'), findsOneWidget);
  });

  testWidgets('sound, vibration, and dark mode preferences stay local', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    final brightnessBefore = Theme.of(tester.element(find.byType(SettingsPage)))
        .brightness;

    for (final preference in ['sound', 'vibration', 'dark-mode']) {
      final tile = find.byKey(ValueKey('settings-$preference'));
      final settingSwitch = find.descendant(
        of: tile,
        matching: find.byType(Switch),
      );
      expect(
        tester.widget<Switch>(settingSwitch).value,
        preference != 'dark-mode',
      );
      await tester.tap(settingSwitch);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Switch>(settingSwitch).value,
        preference == 'dark-mode',
      );
      expect(
        Theme.of(tester.element(find.byType(SettingsPage))).brightness,
        brightnessBefore,
      );
    }
  });

  testWidgets('settings legal information opens local dialogs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

    final privacy = find.byKey(const ValueKey('settings-privacy'));
    await tester.scrollUntilVisible(
      privacy,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(privacy);
    await tester.pumpAndSettle();
    expect(find.text('Privacy Policy'), findsWidgets);
    expect(
      find.textContaining('demo screen provides sample information'),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    final terms = find.byKey(const ValueKey('settings-terms'));
    await tester.scrollUntilVisible(
      terms,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(terms);
    await tester.pumpAndSettle();
    expect(find.text('Terms & Conditions'), findsWidgets);
    expect(find.textContaining('placeholder information'), findsOneWidget);
  });

  testWidgets('help page contains FAQs and quick help expands and collapses', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpSupportPage()));

    expect(find.text('Quick Help'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Frequently asked'), findsOneWidget);
    final acceptFaq = find.text('How do I accept an order?');
    await tester.scrollUntilVisible(
      acceptFaq,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(acceptFaq);
    await tester.pumpAndSettle();
    await tester.tap(acceptFaq);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Open the available demo offer'),
      findsOneWidget,
    );

    await tester.ensureVisible(acceptFaq);
    await tester.pumpAndSettle();
    await tester.tap(acceptFaq);
    await tester.pumpAndSettle();
    expect(find.textContaining('Open the available demo offer'), findsNothing);

    expect(
      find.text('What should I do if the customer is unavailable?'),
      findsOneWidget,
    );
  });

  testWidgets('quick help opens its matching expandable FAQ', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpSupportPage()));

    final pickupQuickHelp = find.text('How pickup works');
    await tester.scrollUntilVisible(
      pickupQuickHelp,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(pickupQuickHelp);
    await tester.pumpAndSettle();
    await tester.tap(pickupQuickHelp);
    await tester.pumpAndSettle();

    expect(find.textContaining('last four digits'), findsOneWidget);
  });

  testWidgets('help contact actions show demo dialogs only', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpSupportPage()));

    for (final action in [
      ('help-contact-center', 'Help Center'),
      ('help-report-issue', 'Report an Issue'),
      ('help-emergency', 'Emergency Help'),
    ]) {
      final finder = find.byKey(ValueKey(action.$1));
      await tester.scrollUntilVisible(
        finder,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(finder);
      await tester.pumpAndSettle();
      expect(find.text(action.$2), findsWidgets);
      if (action.$1 == 'help-emergency') {
        expect(
          find.textContaining(
            'For immediate danger, contact local emergency services.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('does not place calls'), findsOneWidget);
      } else {
        expect(
          find.textContaining(
            action.$1 == 'help-contact-center'
                ? 'Support services are not connected.'
                : 'No ticket or message has been sent.',
          ),
          findsOneWidget,
        );
      }
      await tester.tap(
        find.text(action.$1 == 'help-emergency' ? 'Understood' : 'Close'),
      );
      await tester.pumpAndSettle();
    }
  });

  testWidgets('settings and help layouts fit common phone viewports', (
    tester,
  ) async {
    for (final viewport in [const Size(360, 800), const Size(390, 844)]) {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Terms & Conditions'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const MaterialApp(home: HelpSupportPage()));
      expect(tester.takeException(), isNull);
      final emergency = find.byKey(const ValueKey('help-emergency'));
      await tester.scrollUntilVisible(
        emergency,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

void _advanceActiveDeliveryToConfirmation(OrderOfferStore offerStore) {
  final delivery = offerStore.activeDelivery;
  if (delivery == null ||
      !offerStore.arriveAtCustomer(delivery) ||
      !offerStore.handOverOrder(delivery)) {
    throw StateError('Could not advance active delivery to hand over');
  }
}

void _advancePickupToPickedUp(OrderOfferStore offerStore) {
  final delivery = offerStore.activeDelivery;
  if (delivery == null ||
      !offerStore.reachStore(delivery) ||
      !offerStore.openOrderDetails(delivery) ||
      !offerStore.verifyPickup(delivery, '2051')) {
    throw StateError('Could not advance pickup to verified state');
  }
}

Future<void> _pumpIncomingOfferDialog(
  WidgetTester tester,
  OrderOfferStore offerStore,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    IncomingOrderOfferDialog(offerStore: offerStore),
              ),
              child: const Text('Open incoming offer'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open incoming offer'));
  await tester.pumpAndSettle();
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

Future<void> _scrollDeliveryActionIntoView(
  WidgetTester tester,
  Finder action,
) async {
  await tester.scrollUntilVisible(
    action,
    200,
    scrollable: find
        .ancestor(of: action, matching: find.byType(Scrollable))
        .first,
  );
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

Future<void> _pumpDeliveryEntry(
  WidgetTester tester,
  OrderOfferStore offerStore,
) async {
  final delivery = offerStore.activeDelivery;
  if (delivery == null) {
    throw StateError('Cannot open delivery details without an active delivery');
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final completed = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) =>
                      DeliveryPage(delivery: delivery, offerStore: offerStore),
                ),
              );
              if (completed == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delivery marked complete')),
                );
              }
            },
            child: const Text('Open delivery'),
          ),
        ),
      ),
    ),
  );
}

Future<AvailabilityStore> _pumpProfilePage(WidgetTester tester) async {
  final availabilityStore = AvailabilityStore();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: ProfilePage(availabilityStore: availabilityStore),
    ),
  );
  return availabilityStore;
}
