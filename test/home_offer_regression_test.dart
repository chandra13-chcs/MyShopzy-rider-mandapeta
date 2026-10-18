import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myshopzy_rider/core/models/demo_delivery.dart';
import 'package:myshopzy_rider/core/network/rider_api_client.dart';
import 'package:myshopzy_rider/core/state/availability_store.dart';
import 'package:myshopzy_rider/core/state/new_order_alert.dart';
import 'package:myshopzy_rider/core/state/order_offer_store.dart';
import 'package:myshopzy_rider/core/theme/app_theme.dart';
import 'package:myshopzy_rider/home/home_page.dart';

void main() {
  test(
    'does not accept an order unless rider duty and connectivity are online',
    () async {
      for (final scenario in [
        (
          initialStatus: AvailabilityStatus.offline,
          connection: ConnectivityResult.wifi,
        ),
        (
          initialStatus: AvailabilityStatus.available,
          connection: ConnectivityResult.none,
        ),
      ]) {
        var acceptRequests = 0;
        final client = RiderApiClient.forTesting(
          baseUri: Uri.parse('http://localhost:3000'),
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/accept')) acceptRequests++;
            return http.Response(jsonEncode({'data': {}}), 200);
          }),
        );
        final availability = AvailabilityStore(
          initialStatus: scenario.initialStatus,
          checkConnectivity: () async => [scenario.connection],
          connectivityChanges: const Stream<List<ConnectivityResult>>.empty(),
        );
        await availability.refreshConnectivity();
        final store = OrderOfferStore(
          availabilityStore: availability,
          activeDelivery: null,
          offer: DemoDelivery.newOffer,
          apiClient: client,
        );
        addTearDown(store.dispose);
        addTearDown(availability.dispose);

        expect(store.canAccept, isFalse);
        expect(await store.acceptAvailableOffer(), isFalse);
        expect(acceptRequests, 0);
      }
    },
  );

  test('rechecks connectivity after notifying accepting state', () async {
    var acceptRequests = 0;
    final client = RiderApiClient.forTesting(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/accept')) acceptRequests++;
        return http.Response(jsonEncode({'data': {}}), 200);
      }),
    );
    final availability = AvailabilityStore(
      initialStatus: AvailabilityStatus.available,
      checkConnectivity: () async => [ConnectivityResult.wifi],
      connectivityChanges: const Stream<List<ConnectivityResult>>.empty(),
    );
    await availability.refreshConnectivity();
    final store = OrderOfferStore(
      availabilityStore: availability,
      activeDelivery: null,
      offer: DemoDelivery.newOffer,
      apiClient: client,
    );
    var disconnected = false;
    store.addListener(() {
      if (store.isAccepting && !disconnected) {
        disconnected = true;
        availability.setConnectivityAvailable(false);
      }
    });
    addTearDown(store.dispose);
    addTearDown(availability.dispose);

    expect(await store.acceptAvailableOffer(), isFalse);
    expect(acceptRequests, 0);
    expect(store.offer, isNull);
  });

  test(
    'assigns a fresh alert revision for every subsequent order offer',
    () async {
      final secondOfferLoaded = Completer<void>();
      final connectivity = StreamController<List<ConnectivityResult>>();
      final client = RiderApiClient.forTesting(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/available')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'orders': [
                    {
                      'orderId': 'first-order',
                      'store': 'First Store',
                      'pickup': {'locality': 'Mandapeta'},
                      'drop': {'formattedAddress': 'Market Road'},
                    },
                    {
                      'orderId': 'second-order',
                      'store': 'Second Store',
                      'pickup': {'locality': 'Mandapeta'},
                      'drop': {'formattedAddress': 'Lakshmi Nagar'},
                    },
                  ],
                },
              }),
              200,
            );
          }
          return http.Response(jsonEncode({'data': {}}), 200);
        }),
      );
      final availability = AvailabilityStore(
        initialStatus: AvailabilityStatus.available,
        checkConnectivity: () async => [ConnectivityResult.wifi],
        connectivityChanges: connectivity.stream,
      );
      await availability.refreshConnectivity();
      final store = OrderOfferStore(
        availabilityStore: availability,
        activeDelivery: null,
        offer: null,
        apiClient: client,
      );
      store.addListener(() {
        if (store.offer?.orderId == 'second-order' &&
            !secondOfferLoaded.isCompleted) {
          secondOfferLoaded.complete();
        }
      });
      addTearDown(store.dispose);
      addTearDown(connectivity.close);
      addTearDown(availability.dispose);

      await store.refreshAvailableOrders();
      expect(store.offer?.orderId, 'first-order');
      final firstRevision = store.offerRevision;
      expect(store.rejectOffer(), isTrue);
      await secondOfferLoaded.future.timeout(const Duration(seconds: 2));

      expect(store.offer?.orderId, 'second-order');
      expect(store.offerRevision, greaterThan(firstRevision));
    },
  );

  testWidgets('home header is left aligned and summary cards are white', (
    tester,
  ) async {
    final availability = AvailabilityStore();
    final store = OrderOfferStore(availabilityStore: availability);
    addTearDown(store.dispose);
    addTearDown(availability.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomePage(availabilityStore: availability, offerStore: store),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final logo = tester.getRect(find.byType(Image).first);
    final greeting = tester.getRect(find.text('Good morning,'));
    expect(logo.left, greeting.left);

    final summaryCard = tester.widget<Card>(
      find
          .ancestor(of: find.text('Deliveries'), matching: find.byType(Card))
          .first,
    );
    expect(summaryCard.color, Colors.white);
  });

  test('new alert revisions can each start a sound alert', () async {
    var soundCount = 0;
    final alert = NewOrderAlert(
      playSound: () async => soundCount++,
      alertDuration: const Duration(seconds: 2),
      vibrate: () async {},
    );
    addTearDown(alert.dispose);

    alert.start('order:1');
    await Future<void>.delayed(Duration.zero);
    await alert.stop();
    alert.start('order:2');
    await Future<void>.delayed(Duration.zero);

    expect(soundCount, 2);
  });
}
