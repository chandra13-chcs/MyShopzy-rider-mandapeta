import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:myshopzy_rider/core/models/demo_delivery.dart';
import 'package:myshopzy_rider/core/network/rider_api_client.dart';
import 'package:myshopzy_rider/core/state/availability_store.dart';
import 'package:myshopzy_rider/core/state/order_offer_store.dart';
import 'package:myshopzy_rider/delivery/delivery_page.dart';

void main() {
  test('queues duty-offline status and syncs it when connectivity returns', () async {
    final connectivity = StreamController<List<ConnectivityResult>>();
    final synced = Completer<void>();
    final requests = <http.Request>[];
    final client = RiderApiClient.forTesting(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/availability') && !synced.isCompleted) {
          synced.complete();
        }
        return http.Response(jsonEncode({'data': {}}), 200);
      }),
    );
    final availability = AvailabilityStore(
      initialStatus: AvailabilityStatus.available,
      apiClient: client,
      checkConnectivity: () async => [ConnectivityResult.none],
      connectivityChanges: connectivity.stream,
    );
    addTearDown(connectivity.close);
    addTearDown(availability.dispose);

    await availability.refreshConnectivity();
    availability.setAvailable(false);

    expect(availability.hasQueuedAvailabilityUpdate, isTrue);
    expect(requests, isEmpty);

    connectivity.add([ConnectivityResult.wifi]);
    await synced.future.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);

    expect(availability.hasQueuedAvailabilityUpdate, isFalse);
    expect(requests, hasLength(1));
    expect(jsonDecode(requests.single.body), {'isOnline': false});
  });

  testWidgets('renders the rider-to-store-to-customer route polyline', (
    tester,
  ) async {
    const delivery = DemoDelivery(
      orderId: 'route-test-order',
      store: 'Green Basket',
      customer: 'Customer',
      pickup: '12 Market Road',
      drop: 'Lakshmi Nagar',
      distanceKm: 4,
      payout: 85,
      status: 'On the Way',
      pickupLatitude: 16.87,
      pickupLongitude: 81.93,
      dropLatitude: 16.88,
      dropLongitude: 81.94,
    );
    final position = Position(
      latitude: 16.86,
      longitude: 81.92,
      timestamp: DateTime(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    );
    final locationSynced = Completer<void>();
    final client = RiderApiClient.forTesting(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/location') &&
            !locationSynced.isCompleted) {
          locationSynced.complete();
        }
        return http.Response(jsonEncode({'data': {}}), 200);
      }),
    );
    final availability = AvailabilityStore(
      initialStatus: AvailabilityStatus.offline,
      apiClient: client,
      getCurrentPosition: () async => position,
      checkConnectivity: () async => [ConnectivityResult.wifi],
      connectivityChanges: const Stream<List<ConnectivityResult>>.empty(),
    );
    await availability.refreshConnectivity();
    availability.setAvailable(true);
    await locationSynced.future.timeout(const Duration(seconds: 2));
    final store = OrderOfferStore(
      availabilityStore: availability,
      activeDelivery: delivery,
      apiClient: client,
    );
    addTearDown(store.dispose);
    addTearDown(availability.dispose);

    await tester.pumpWidget(
      MaterialApp(home: DeliveryPage(delivery: delivery, offerStore: store)),
    );
    await tester.pump();

    final routeLayer = tester.widget<PolylineLayer>(
      find.byType(PolylineLayer),
    );
    expect(routeLayer.polylines, hasLength(1));
    expect(routeLayer.polylines.single.points, [
      const LatLng(16.86, 81.92),
      const LatLng(16.87, 81.93),
      const LatLng(16.88, 81.94),
    ]);
  });
}
