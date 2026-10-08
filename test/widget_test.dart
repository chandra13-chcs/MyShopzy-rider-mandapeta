import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myshopzy_rider/app/rider_app.dart';
import 'package:myshopzy_rider/core/state/availability_store.dart';
import 'package:myshopzy_rider/home/home_demo_data.dart';
import 'package:myshopzy_rider/home/home_page.dart';

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
    addTearDown(availabilityStore.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: HomePage(
            availabilityStore: availabilityStore,
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
    expect(find.text("You're offline"), findsOneWidget);
    expect(
      find.text('New delivery offers are unavailable while you are offline.'),
      findsOneWidget,
    );

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
    expect(find.text('Your next delivery is waiting'), findsOneWidget);
    expect(find.text('NEW ORDER'), findsOneWidget);
  });

  testWidgets('home quick actions open their destinations', (tester) async {
    await tester.pumpWidget(const RiderApp());

    await _scrollHomeTo(
      tester,
      find.byKey(const ValueKey('home-action-Orders')),
    );
    await tester.tap(find.byKey(const ValueKey('home-action-Orders')));
    await tester.pumpAndSettle();
    expect(find.text('Your next delivery is waiting'), findsOneWidget);
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
