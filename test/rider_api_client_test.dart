import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myshopzy_rider/core/models/demo_delivery.dart';
import 'package:myshopzy_rider/core/network/rider_api_client.dart';
import 'package:myshopzy_rider/core/state/availability_store.dart';
import 'package:myshopzy_rider/core/state/order_offer_store.dart';
import 'package:myshopzy_rider/delivery/delivery_page.dart';

void main() {
  const orderId = 'd1ca6b39-b9d9-423b-b93b-3e513f232d9a';

  test(
    'uses Rider API paths, JSON headers, and the backend demo rider UUID',
    () async {
      final requests = <http.Request>[];
      final client = RiderApiClient.forTesting(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/accept')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'order': {
                    'orderId': orderId,
                    'store': 'Green Basket',
                    'pickup': {'locality': 'Mandapeta'},
                    'drop': {'formattedAddress': '12 Market Road'},
                    'status': 'out_for_delivery',
                  },
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'data': {'orders': []},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await client.getAvailableOrders();
      await client.acceptOrder(orderId);
      await client.updateOrderStatus(orderId, 'delivered');
      await client.updateLocation(16.87, 81.93);
      await client.updateAvailability(false);
      await client.getEarningsSummary();

      expect(
        requests.map((request) => '${request.method} ${request.url.path}'),
        [
          'GET /api/v1/rider/orders/available',
          'POST /api/v1/rider/orders/$orderId/accept',
          'PATCH /api/v1/rider/orders/$orderId/status',
          'POST /api/v1/rider/location',
          'PATCH /api/v1/rider/availability',
          'GET /api/v1/rider/earnings/summary',
        ],
      );
      for (final request in requests) {
        expect(request.headers['content-type'], 'application/json');
        expect(
          request.headers['x-rider-id'],
          '00000000-0000-4000-8000-000000000001',
        );
      }
      expect(jsonDecode(requests[2].body), {'status': 'delivered'});
      expect(jsonDecode(requests[3].body), {
        'latitude': 16.87,
        'longitude': 81.93,
      });
      expect(jsonDecode(requests[4].body), {'isOnline': false});
    },
  );

  test('parses available order fields from the API contract', () async {
    final client = RiderApiClient.forTesting(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'data': {
              'orders': [
                {
                  'orderId': orderId,
                  'status': 'getting_packed',
                  'store': 'Green Basket',
                  'pickup': {'locality': 'Mandapeta'},
                  'drop': {'formattedAddress': '12 Market Road'},
                  'customerName': 'Rider Customer',
                  'customerPhone': '+911234567890',
                  'pickupLatitude': -16.87,
                  'pickupLongitude': 81.93,
                  'dropLatitude': 16.88,
                  'dropLongitude': 81.94,
                  'payout': '85.00',
                },
              ],
            },
          }),
          200,
        );
      }),
    );

    final orders = await client.getAvailableOrders();
    expect(orders, hasLength(1));
    expect(orders.single.orderId, orderId);
    expect(orders.single.store, 'Green Basket');
    expect(orders.single.pickup, 'Mandapeta');
    expect(orders.single.drop, '12 Market Road');
    expect(orders.single.payout, 85);
    expect(orders.single.customer, 'Rider Customer');
    expect(orders.single.customerPhone, '+911234567890');
    expect(orders.single.pickupLatitude, -16.87);
    expect(orders.single.dropLongitude, 81.94);
    expect(orders.single.totalDistanceLabel, 'Not provided');
  });

  test('reports API errors with the backend error code and message', () async {
    final client = RiderApiClient.forTesting(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'ORDER_NOT_AVAILABLE',
              'message': 'This order is no longer available.',
            },
          }),
          409,
        );
      }),
    );

    await expectLater(
      client.acceptOrder(orderId),
      throwsA(
        isA<RiderApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having((error) => error.code, 'code', 'ORDER_NOT_AVAILABLE')
            .having(
              (error) => error.message,
              'message',
              'This order is no longer available.',
            ),
      ),
    );
  });

  test('parses the backend offline acceptance response', () async {
    final client = RiderApiClient.forTesting(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Rider is offline'}),
          403,
        );
      }),
    );

    await expectLater(
      client.acceptOrder(orderId),
      throwsA(
        isA<RiderApiException>()
            .having((error) => error.code, 'code', 'RIDER_OFFLINE')
            .having((error) => error.message, 'message', 'Rider is offline'),
      ),
    );
  });

  test(
    'fetches remote offers and accepts before setting the active delivery',
    () async {
      final requests = <http.Request>[];
      final offerAvailable = Completer<void>();
      final client = RiderApiClient.forTesting(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/available')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'orders': [
                    {
                      'orderId': orderId,
                      'status': 'getting_packed',
                      'store': 'Green Basket',
                      'pickup': {'locality': 'Mandapeta'},
                      'drop': {'formattedAddress': '12 Market Road'},
                    },
                  ],
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'data': {
                'order': {
                  'orderId': orderId,
                  'status': 'out_for_delivery',
                  'store': 'Green Basket',
                  'pickup': {'locality': 'Mandapeta'},
                  'drop': {'formattedAddress': '12 Market Road'},
                  'customerName': 'Customer',
                  'customerPhone': '+911234567890',
                  'storePhone': '+911098765432',
                  'pickupLatitude': 16.87,
                  'pickupLongitude': 81.93,
                  'dropLatitude': 16.88,
                  'dropLongitude': 81.94,
                  'payout': '85.00',
                },
              },
            }),
            200,
          );
        }),
      );
      final availability = AvailabilityStore(
        checkConnectivity: () async => [ConnectivityResult.wifi],
        connectivityChanges: const Stream.empty(),
      );
      final store = OrderOfferStore(
        availabilityStore: availability,
        activeDelivery: null,
        offer: null,
        apiClient: client,
      );
      addTearDown(store.dispose);
      addTearDown(availability.dispose);
      store.addListener(() {
        if (store.offer != null && !offerAvailable.isCompleted) {
          offerAvailable.complete();
        }
      });

      await offerAvailable.future;
      expect(store.offer?.orderId, orderId);
      expect(store.canAccept, isTrue);

      expect(await store.acceptAvailableOffer(), isTrue);
      expect(store.activeDelivery?.orderId, orderId);
      expect(store.activeDelivery?.storePhone, '+911098765432');
      expect(store.activeDelivery?.customerPhone, '+911234567890');
      expect(store.activeDelivery?.pickupLatitude, 16.87);
      expect(store.activeDelivery?.dropLongitude, 81.94);
      expect(store.status, OrderOfferStatus.accepted);
      expect(requests.map((request) => request.method), ['GET', 'POST']);
    },
  );

  test(
    'confirms pickup, delivery and settlement only after API success',
    () async {
      final requests = <http.Request>[];
      final earningsLoaded = Completer<void>();
      final orderJson = {
        'orderId': orderId,
        'status': 'out_for_delivery',
        'store': 'Green Basket',
        'pickup': {'locality': 'Mandapeta'},
        'drop': {'formattedAddress': '12 Market Road'},
        'customerName': 'Customer',
        'customerPhone': '+911234567890',
        'payout': 85,
      };
      final client = RiderApiClient.forTesting(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/available')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'orders': [
                    {...orderJson, 'status': 'getting_packed'},
                  ],
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/summary')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'summary': {
                    'todayPayoutMinor': '12500',
                    'todayDeliveries': 3,
                    'lifetimePayoutMinor': '90000',
                    'lifetimeDeliveries': 20,
                  },
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'data': {'order': orderJson},
            }),
            200,
          );
        }),
      );
      final availability = AvailabilityStore(
        initialStatus: AvailabilityStatus.available,
        checkConnectivity: () async => [ConnectivityResult.wifi],
        connectivityChanges: const Stream.empty(),
      );
      await availability.refreshConnectivity();
      final store = OrderOfferStore(
        availabilityStore: availability,
        activeDelivery: null,
        offer: null,
        apiClient: client,
      );
      addTearDown(store.dispose);
      addTearDown(availability.dispose);
      store.addListener(() {
        if (store.todaySettlementMinor == 12500 &&
            !earningsLoaded.isCompleted) {
          earningsLoaded.complete();
        }
      });

      await store.refreshAvailableOrders();
      final delivery = store.offer!;
      expect(await store.acceptAvailableOffer(), isTrue);
      expect(store.reachStore(delivery), isTrue);
      expect(store.openOrderDetails(delivery), isTrue);
      expect(await store.confirmPickup(delivery, '3d9a'), isFalse);
      expect(await store.confirmPickup(delivery, '2329'), isTrue);
      expect(await store.startDelivery(delivery), isTrue);
      expect(store.arriveAtCustomer(delivery), isTrue);
      expect(store.handOverOrder(delivery), isTrue);
      expect(await store.completeDelivery(delivery), isTrue);
      await earningsLoaded.future.timeout(const Duration(seconds: 2));

      expect(store.activeDelivery, isNull);
      expect(store.todaySettlementMinor, 12500);
      expect(store.todayCompletedDeliveries, 3);
      expect(
        requests
            .where((request) => request.url.path.endsWith('/status'))
            .map((request) => jsonDecode(request.body)['status']),
        ['picked_up', 'out_for_delivery', 'delivered'],
      );
      expect(
        requests.any(
          (request) => request.url.path.endsWith('/earnings/summary'),
        ),
        isTrue,
      );
    },
  );

  test('queues offline order statuses and syncs on reconnect', () async {
    final connectivity = StreamController<List<ConnectivityResult>>();
    final deliveredSynced = Completer<void>();
    final requests = <http.Request>[];
    final client = RiderApiClient.forTesting(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/status')) {
          if (!deliveredSynced.isCompleted) deliveredSynced.complete();
          return http.Response(
            jsonEncode({
              'data': {
                'order': {
                  'orderId': DemoDelivery.batchThreeActive.orderId,
                  'status': 'delivered',
                  'payoutMinor': '8500',
                },
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'data': {
              'summary': {
                'todayPayoutMinor': '8500',
                'todayDeliveries': 1,
                'lifetimePayoutMinor': '8500',
                'lifetimeDeliveries': 1,
              },
            },
          }),
          200,
        );
      }),
    );
    final availability = AvailabilityStore(
      initialStatus: AvailabilityStatus.available,
      apiClient: client,
      checkConnectivity: () async => [ConnectivityResult.none],
      connectivityChanges: connectivity.stream,
    );
    await availability.refreshConnectivity();
    final store = OrderOfferStore(
      availabilityStore: availability,
      apiClient: client,
    );
    addTearDown(store.dispose);
    addTearDown(connectivity.close);
    addTearDown(availability.dispose);

    final delivery = store.activeDelivery!;
    expect(store.arriveAtCustomer(delivery), isTrue);
    expect(store.handOverOrder(delivery), isTrue);
    expect(await store.completeDelivery(delivery), isTrue);
    expect(store.queuedOrderStatusCount, 1);
    expect(
      requests.where((request) => request.url.path.endsWith('/status')),
      isEmpty,
    );

    connectivity.add([ConnectivityResult.wifi]);
    await deliveredSynced.future.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);

    expect(store.queuedOrderStatusCount, 0);
    expect(
      requests
          .where((request) => request.url.path.endsWith('/status'))
          .map((request) => jsonDecode(request.body)['status']),
      ['delivered'],
    );
  });

  testWidgets('delivery view shows the route and contact actions', (
    tester,
  ) async {
    const delivery = DemoDelivery(
      orderId: '0000-1234',
      store: 'Green Basket',
      customer: 'Rider Customer',
      pickup: '12 Market Road',
      drop: 'Lakshmi Nagar',
      distanceKm: 4,
      payout: 85,
      status: 'New Offer',
      storePhone: '+911098765432',
      customerPhone: '+911234567890',
      pickupLatitude: 16.87,
      pickupLongitude: 81.93,
      dropLatitude: 16.88,
      dropLongitude: 81.94,
    );
    final availability = AvailabilityStore();
    final store = OrderOfferStore(
      availabilityStore: availability,
      activeDelivery: null,
      offer: delivery,
    );
    expect(store.acceptOffer(), isTrue);
    expect(store.pickupStatus, PickupStatus.goingToPickup);
    expect(store.activeDelivery?.storePhone, '+911098765432');
    addTearDown(store.dispose);
    addTearDown(availability.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 2000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DeliveryPage(delivery: delivery, offerStore: store),
      ),
    );
    expect(find.byKey(const ValueKey('delivery-route-map')), findsOneWidget);
    expect(find.text('Call Store'), findsOneWidget);
    expect(find.text('Rider GPS unavailable'), findsOneWidget);

    store.reachStore(delivery);
    store.openOrderDetails(delivery);
    expect(store.verifyPickup(delivery, '1234'), isTrue);
    expect(store.continueToDelivery(delivery), isTrue);
    await tester.pump();
    expect(find.text('Call'), findsOneWidget);
  });

  test('syncs a GPS fix when duty status changes to online', () async {
    var postedLocation = false;
    final client = RiderApiClient.forTesting(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        postedLocation =
            request.url.path == '/api/v1/rider/location' &&
            jsonDecode(request.body)['latitude'] == 16.87 &&
            jsonDecode(request.body)['longitude'] == 81.93;
        return http.Response(
          jsonEncode({
            'data': {'location': {}},
          }),
          200,
        );
      }),
    );
    final position = Position(
      latitude: 16.87,
      longitude: 81.93,
      timestamp: DateTime(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    );
    final availability = AvailabilityStore(
      initialStatus: AvailabilityStatus.offline,
      apiClient: client,
      getCurrentPosition: () async => position,
      checkConnectivity: () async => [ConnectivityResult.wifi],
      connectivityChanges: const Stream.empty(),
    );
    addTearDown(availability.dispose);

    availability.setAvailable(true);
    await Future<void>.delayed(Duration.zero);

    expect(postedLocation, isTrue);
    expect(availability.isAvailable, isTrue);
    expect(availability.lastError, isNull);
  });

  test(
    'streams GPS fixes while on duty and reports duty-off to the backend',
    () async {
      final positions = StreamController<Position>();
      final initialLocationSent = Completer<void>();
      final secondLocationSent = Completer<void>();
      final dutyOffSent = Completer<void>();
      final requests = <http.Request>[];
      var postedLocations = 0;
      final client = RiderApiClient.forTesting(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/location')) {
            postedLocations++;
            if (postedLocations == 1 && !initialLocationSent.isCompleted) {
              initialLocationSent.complete();
            }
            if (postedLocations == 2 && !secondLocationSent.isCompleted) {
              secondLocationSent.complete();
            }
          }
          if (request.url.path.endsWith('/availability') &&
              !dutyOffSent.isCompleted) {
            dutyOffSent.complete();
          }
          return http.Response(jsonEncode({'data': {}}), 200);
        }),
      );
      Position makePosition(double latitude) => Position(
        latitude: latitude,
        longitude: 81.93,
        timestamp: DateTime(2026),
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );
      final availability = AvailabilityStore(
        initialStatus: AvailabilityStatus.offline,
        apiClient: client,
        getCurrentPosition: () async => makePosition(16.87),
        positionStream: () => positions.stream,
        checkConnectivity: () async => [ConnectivityResult.wifi],
        connectivityChanges: const Stream.empty(),
      );
      addTearDown(positions.close);
      addTearDown(availability.dispose);

      availability.setAvailable(true);
      await initialLocationSent.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(Duration.zero);
      positions.add(makePosition(16.88));
      await secondLocationSent.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(Duration.zero);
      availability.setAvailable(false);
      await dutyOffSent.future.timeout(const Duration(seconds: 2));

      expect(
        requests.where((request) => request.url.path.endsWith('/location')),
        hasLength(2),
      );
      expect(requests.last.url.path, '/api/v1/rider/availability');
      expect(jsonDecode(requests.last.body), {'isOnline': false});
    },
  );

  test(
    'queues the latest location while offline and flushes on reconnect',
    () async {
      final positions = StreamController<Position>();
      final connectivity = StreamController<List<ConnectivityResult>>();
      final firstLocation = Completer<void>();
      final secondLocation = Completer<void>();
      final requests = <http.Request>[];
      Position makePosition(double latitude) => Position(
        latitude: latitude,
        longitude: 81.93,
        timestamp: DateTime(2026),
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );
      final client = RiderApiClient.forTesting(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          requests.add(request);
          final locationRequests = requests
              .where((item) => item.url.path.endsWith('/location'))
              .length;
          if (locationRequests == 1 && !firstLocation.isCompleted) {
            firstLocation.complete();
          }
          if (locationRequests == 2 && !secondLocation.isCompleted) {
            secondLocation.complete();
          }
          return http.Response(jsonEncode({'data': {}}), 200);
        }),
      );
      final availability = AvailabilityStore(
        initialStatus: AvailabilityStatus.offline,
        apiClient: client,
        getCurrentPosition: () async => makePosition(16.87),
        positionStream: () => positions.stream,
        checkConnectivity: () async => [ConnectivityResult.wifi],
        connectivityChanges: connectivity.stream,
      );
      addTearDown(positions.close);
      addTearDown(connectivity.close);
      addTearDown(availability.dispose);

      availability.setAvailable(true);
      await firstLocation.future.timeout(const Duration(seconds: 2));
      connectivity.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      positions.add(makePosition(16.88));
      positions.add(makePosition(16.89));
      await Future<void>.delayed(Duration.zero);

      expect(
        requests.where((request) => request.url.path.endsWith('/location')),
        hasLength(1),
      );
      expect(availability.hasQueuedLocation, isTrue);

      connectivity.add([ConnectivityResult.wifi]);
      await secondLocation.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(Duration.zero);
      final locationRequests = requests
          .where((request) => request.url.path.endsWith('/location'))
          .toList();
      expect(locationRequests, hasLength(2));
      expect(jsonDecode(locationRequests.last.body)['latitude'], 16.89);
      expect(availability.hasQueuedLocation, isFalse);
    },
  );

  test(
    'reverts duty status and exposes the server error when location fails',
    () async {
      final client = RiderApiClient.forTesting(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'RIDER_NOT_ALLOWED',
                'message': 'The rider account is not active.',
              },
            }),
            403,
          );
        }),
      );
      final position = Position(
        latitude: 16.87,
        longitude: 81.93,
        timestamp: DateTime(2026),
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      );
      final availability = AvailabilityStore(
        initialStatus: AvailabilityStatus.offline,
        apiClient: client,
        getCurrentPosition: () async => position,
        checkConnectivity: () async => [ConnectivityResult.wifi],
        connectivityChanges: const Stream.empty(),
      );
      addTearDown(availability.dispose);

      availability.setAvailable(true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(availability.isAvailable, isFalse);
      expect(availability.lastError, 'The rider account is not active.');
    },
  );

  test('alerts once when GPS speed exceeds 50 km/h', () async {
    final positions = StreamController<Position>();
    final initialLocationSent = Completer<void>();
    var warningSounds = 0;
    final client = RiderApiClient.forTesting(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((_) async {
        if (!initialLocationSent.isCompleted) initialLocationSent.complete();
        return http.Response(jsonEncode({'data': {}}), 200);
      }),
    );
    Position makePosition(double metersPerSecond) => Position(
      latitude: 16.87,
      longitude: 81.93,
      timestamp: DateTime(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: metersPerSecond,
      speedAccuracy: 1,
    );
    final availability = AvailabilityStore(
      initialStatus: AvailabilityStatus.offline,
      apiClient: client,
      getCurrentPosition: () async => makePosition(0),
      positionStream: () => positions.stream,
      playOverspeedSound: () async {
        warningSounds++;
      },
      checkConnectivity: () async => [ConnectivityResult.wifi],
      connectivityChanges: const Stream.empty(),
    );
    addTearDown(positions.close);
    addTearDown(availability.dispose);

    availability.setAvailable(true);
    await initialLocationSent.future.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);

    positions.add(makePosition(50 / 3.6));
    await Future<void>.delayed(Duration.zero);
    expect(availability.speedKmh, closeTo(50, 1e-8));
    expect(availability.isOverspeeding, isFalse);
    expect(warningSounds, 0);

    positions.add(makePosition(14));
    await Future<void>.delayed(Duration.zero);
    expect(availability.speedKmh, closeTo(50.4, 1e-8));
    expect(availability.isOverspeeding, isTrue);
    expect(warningSounds, 1);

    positions.add(makePosition(15));
    await Future<void>.delayed(Duration.zero);
    expect(warningSounds, 1);

    positions.add(makePosition(10));
    await Future<void>.delayed(Duration.zero);
    expect(availability.isOverspeeding, isFalse);

    positions.add(makePosition(14));
    await Future<void>.delayed(Duration.zero);
    expect(warningSounds, 2);

    availability.setAvailable(false);
    expect(availability.isOverspeeding, isFalse);
    expect(availability.speedKmh, isNull);
  });

  test('maps Rider API orders without silently inventing required fields', () {
    expect(
      () => DemoDelivery.fromRiderApiJson({'store': 'Missing ID'}),
      throwsFormatException,
    );
  });

  test(
    'does not poll or accept offers while connectivity is offline',
    () async {
      final connectivity = StreamController<List<ConnectivityResult>>();
      final offerLoaded = Completer<void>();
      final requests = <http.Request>[];
      final client = RiderApiClient.forTesting(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/available')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'orders': [
                    {
                      'orderId': orderId,
                      'status': 'getting_packed',
                      'store': 'Green Basket',
                      'pickup': {'locality': 'Mandapeta'},
                      'drop': {'formattedAddress': '12 Market Road'},
                    },
                  ],
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/accept')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'order': {
                    'orderId': orderId,
                    'status': 'out_for_delivery',
                    'store': 'Green Basket',
                    'pickup': {'locality': 'Mandapeta'},
                    'drop': {'formattedAddress': '12 Market Road'},
                  },
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'data': {'orders': []},
            }),
            200,
          );
        }),
      );
      final availability = AvailabilityStore(
        initialStatus: AvailabilityStatus.available,
        checkConnectivity: () async => [ConnectivityResult.none],
        connectivityChanges: connectivity.stream,
      );
      final store = OrderOfferStore(
        availabilityStore: availability,
        activeDelivery: null,
        offer: null,
        apiClient: client,
      );
      store.addListener(() {
        if (store.offer != null && !offerLoaded.isCompleted) {
          offerLoaded.complete();
        }
      });
      addTearDown(store.dispose);
      addTearDown(availability.dispose);
      addTearDown(connectivity.close);

      await availability.refreshConnectivity();
      await store.refreshAvailableOrders();
      expect(store.canAccept, isFalse);
      expect(await store.acceptAvailableOffer(), isFalse);
      expect(requests, isEmpty);

      connectivity.add([ConnectivityResult.wifi]);
      await offerLoaded.future.timeout(const Duration(seconds: 1));

      expect(availability.isOnlineForOrders, isTrue);
      expect(await store.acceptAvailableOffer(), isTrue);
      expect(requests.map((request) => request.method), ['GET', 'POST']);
    },
  );
}
