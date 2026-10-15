import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myshopzy_rider/core/models/demo_delivery.dart';
import 'package:myshopzy_rider/core/network/rider_api_client.dart';
import 'package:myshopzy_rider/core/state/availability_store.dart';
import 'package:myshopzy_rider/core/state/order_offer_store.dart';

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

      expect(
        requests.map((request) => '${request.method} ${request.url.path}'),
        [
          'GET /api/v1/rider/orders/available',
          'POST /api/v1/rider/orders/$orderId/accept',
          'PATCH /api/v1/rider/orders/$orderId/status',
          'POST /api/v1/rider/location',
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
                  'payout': 85,
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
                'order': {'orderId': orderId, 'status': 'out_for_delivery'},
              },
            }),
            200,
          );
        }),
      );
      final availability = AvailabilityStore(
        apiClient: client,
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
      expect(store.status, OrderOfferStatus.accepted);
      expect(requests.map((request) => request.method), ['GET', 'POST']);
    },
  );

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
      final requests = <http.Request>[];
      final client = RiderApiClient.forTesting(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          requests.add(request);
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
        offer: DemoDelivery.newOffer,
        apiClient: client,
      );
      addTearDown(store.dispose);
      addTearDown(availability.dispose);
      addTearDown(connectivity.close);

      await availability.refreshConnectivity();
      await store.refreshAvailableOrders();
      expect(store.canAccept, isFalse);
      expect(await store.acceptAvailableOffer(), isFalse);
      expect(requests, isEmpty);

      connectivity.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      expect(availability.isOnlineForOrders, isTrue);
      expect(await store.acceptAvailableOffer(), isTrue);
      expect(requests.map((request) => request.method), ['POST']);
    },
  );
}
