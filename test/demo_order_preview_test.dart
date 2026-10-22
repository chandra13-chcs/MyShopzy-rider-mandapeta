import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:myshopzy_rider/app/rider_app.dart';
import 'package:myshopzy_rider/delivery/delivery_page.dart';
import 'package:myshopzy_rider/orders/rider_map_view.dart';

void main() {
  testWidgets('incoming offer stays full screen until its 30-second expiry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const RiderApp(
        showDemoOrder: true,
        demoRiderLocation: LatLng(16.8668, 81.9296),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('New order!'), findsNothing);
    await _startSafeDelivery(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('New order!'), findsOneWidget);
    expect(find.text('Expected earnings'), findsOneWidget);
    expect(find.text('PICK UP'), findsOneWidget);
    expect(find.text('DROP OFF'), findsOneWidget);
    expect(find.byType(RiderMapView), findsOneWidget);
    expect(find.textContaining('Swipe right to accept'), findsOneWidget);
    expect(find.textContaining('left to reject'), findsOneWidget);
    expect(tester.getSize(find.byType(Dialog)), const Size(390, 844));

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('New order!'), findsOneWidget);

    for (var second = 0; second < 30; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump();
    expect(find.text('New order!'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('demo preview offers one order and opens its store route', (
    tester,
  ) async {
    await tester.pumpWidget(
      const RiderApp(
        showDemoOrder: true,
        demoRiderLocation: LatLng(16.8668, 81.9296),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('New order!'), findsNothing);
    await _startSafeDelivery(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('New order!'), findsOneWidget);
    expect(find.text('#MS-2051'), findsOneWidget);
    expect(find.text('30s'), findsOneWidget);
    expect(find.text('Accept order'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('incoming-order-open-pickup-map')),
      findsOneWidget,
    );
    expect(find.text('Open Google Maps to Pickup'), findsOneWidget);
    expect(find.text('Your current location (demo)'), findsOneWidget);
    expect(find.textContaining('DEMO · YOUR CURRENT LOCATION'), findsOneWidget);
    expect(find.textContaining('Pickup: 0.0 km'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );

    await tester.drag(
      find.byKey(const ValueKey('incoming-order-accept-track')),
      const Offset(500, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.byType(DeliveryPage), findsOneWidget);
    expect(find.text('Route to Store'), findsOneWidget);
    final routeMap = tester.widget<RiderMapView>(find.byType(RiderMapView));
    expect(routeMap.navigationTarget, const LatLng(16.8668, 81.9296));
    expect(find.text('ORDER JOURNEY'), findsOneWidget);
    expect(find.text('DEMO'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('safe start shows a demo order without GPS permission', (
    tester,
  ) async {
    await tester.pumpWidget(const RiderApp(showDemoOrder: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('New order!'), findsNothing);

    await _startSafeDelivery(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("You're online"), findsOneWidget);
    expect(find.text('New order!'), findsOneWidget);
    expect(find.text('#MS-2051'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> _startSafeDelivery(WidgetTester tester) async {
  await tester.tap(find.byType(Switch).first);
  await tester.pumpAndSettle();
  for (var index = 0; index < 3; index++) {
    await tester.tap(find.byType(Checkbox).at(index));
    await tester.pump();
  }
  await tester.tap(find.text('Start Safe Delivery').last);
  await tester.pump();
}
