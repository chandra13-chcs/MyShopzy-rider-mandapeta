import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myshopzy_rider/app/rider_app.dart';

void main() {
  testWidgets('opens directly to the rider home demo', (tester) async {
    await tester.pumpWidget(const RiderApp());

    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Ravi Kumar 👋'), findsOneWidget);
    expect(find.text('You are online'), findsOneWidget);
  });

  testWidgets('online status can be toggled', (tester) async {
    await tester.pumpWidget(const RiderApp());

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('You are offline'), findsOneWidget);
    expect(find.text('Go online to receive orders'), findsOneWidget);
  });

  testWidgets('bottom navigation opens the requested sections', (tester) async {
    await tester.pumpWidget(const RiderApp());

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    expect(find.text('Your next delivery is waiting'), findsOneWidget);

    await tester.tap(find.text('Earnings').last);
    await tester.pumpAndSettle();
    expect(find.text('Earnings breakdown'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Rider · Mandapeta'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('You are offline'), findsOneWidget);
  });

  testWidgets('home links open their destinations and return to home', (
    tester,
  ) async {
    await tester.pumpWidget(const RiderApp());

    await tester.tap(find.byTooltip('Help and support'));
    await tester.pumpAndSettle();
    expect(find.text('Frequently asked'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Preferences'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Preferences'));
    await tester.pumpAndSettle();
    expect(find.text('Order alerts'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('History'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Delivery history'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('View order'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View order'));
    await tester.pumpAndSettle();
    expect(find.text('Delivery details'), findsOneWidget);
  });

  testWidgets('home and main sections fit a phone viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RiderApp());
    expect(tester.takeException(), isNull);

    for (final tab in ['Orders', 'Earnings', 'Profile', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      final layoutException = tester.takeException();
      expect(layoutException, isNull, reason: tab);
    }
  });
}
