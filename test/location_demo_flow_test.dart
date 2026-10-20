import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myshopzy_rider/core/state/availability_store.dart';
import 'package:myshopzy_rider/core/state/order_offer_store.dart';

void main() {
  test(
    'local demo completes pickup and delivery at the current GPS point',
    () async {
      final position = Position(
        latitude: 16.8668,
        longitude: 81.9296,
        timestamp: DateTime.utc(2026, 10, 19),
        accuracy: 3,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      final availabilityStore = AvailabilityStore(initialPosition: position);
      final offerStore = OrderOfferStore(
        availabilityStore: availabilityStore,
        activeDelivery: null,
        offer: null,
      );
      addTearDown(offerStore.dispose);
      addTearDown(availabilityStore.dispose);

      offerStore.setDemoOfferForRiderLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final offer = offerStore.offer!;
      expect(offer.isLocationDemo, isTrue);
      expect(offer.pickupLatitude, position.latitude);
      expect(offer.pickupLongitude, position.longitude);
      expect(offer.dropLatitude, position.latitude);
      expect(offer.dropLongitude, position.longitude);
      expect(offer.pickupDistanceKm, 0);
      expect(offer.deliveryDistanceKm, 0);

      expect(offerStore.acceptOffer(), isTrue);
      expect(offerStore.pickupStatus, PickupStatus.reachedPickup);
      expect(offerStore.openOrderDetails(offer), isTrue);
      expect(await offerStore.confirmPickupAndStartDelivery(offer), isTrue);
      expect(offerStore.pickupStatus, PickupStatus.onTheWay);
      expect(offerStore.deliveryStatus, DeliveryStatus.reachedCustomer);
      expect(offerStore.handOverOrder(offer), isTrue);
      expect(await offerStore.completeDelivery(offer), isTrue);
      expect(offerStore.activeDelivery, isNull);
      expect(offerStore.deliveryStatus, DeliveryStatus.delivered);
    },
  );
}
