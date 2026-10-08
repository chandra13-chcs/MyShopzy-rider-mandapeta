import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/demo_delivery.dart';
import 'availability_store.dart';

enum OrderOfferStatus { noOffer, available, accepted, rejected, expired }

enum PickupStatus {
  goingToPickup,
  reachedPickup,
  orderDetails,
  pickupVerification,
  pickedUp,
  onTheWay,
}

enum DeliveryStatus { onTheWay, arriving, confirmingDelivery, delivered }

extension PickupStatusLabel on PickupStatus {
  String get label => switch (this) {
    PickupStatus.goingToPickup => 'Going to Pickup',
    PickupStatus.reachedPickup => 'At Store',
    PickupStatus.orderDetails => 'Order Verification',
    PickupStatus.pickupVerification => 'Verify Pickup',
    PickupStatus.pickedUp => 'Picked Up',
    PickupStatus.onTheWay => 'On the Way',
  };
}

extension DeliveryStatusLabel on DeliveryStatus {
  String get label => switch (this) {
    DeliveryStatus.onTheWay => 'On the Way',
    DeliveryStatus.arriving => 'Arriving',
    DeliveryStatus.confirmingDelivery => 'Confirm Delivery',
    DeliveryStatus.delivered => 'Delivered',
  };
}

class OrderOfferStore extends ChangeNotifier {
  OrderOfferStore({
    required this.availabilityStore,
    DemoDelivery? activeDelivery = DemoDelivery.batchThreeActive,
    this.offer = DemoDelivery.newOffer,
    this.offerDuration = const Duration(seconds: 20),
  }) : activeDelivery = activeDelivery,
       pickupStatus = activeDelivery == null
           ? PickupStatus.goingToPickup
           : PickupStatus.onTheWay,
       deliveryStatus = DeliveryStatus.onTheWay,
       secondsRemaining = offerDuration.inSeconds {
    availabilityStore.addListener(_handleAvailabilityChanged);
    _updateTimer();
  }

  final AvailabilityStore availabilityStore;
  final DemoDelivery offer;
  final Duration offerDuration;

  DemoDelivery? activeDelivery;
  PickupStatus pickupStatus;
  DeliveryStatus deliveryStatus;
  OrderOfferStatus status = OrderOfferStatus.available;
  int secondsRemaining;
  Timer? _timer;
  bool _disposed = false;

  bool get isBusy => activeDelivery != null;

  String get activeDeliveryStatus => pickupStatus == PickupStatus.onTheWay
      ? deliveryStatus.label
      : pickupStatus.label;

  bool get canShowOffer =>
      availabilityStore.isAvailable &&
      activeDelivery == null &&
      status == OrderOfferStatus.available;

  bool get canAccept => canShowOffer && secondsRemaining > 0;

  void _handleAvailabilityChanged() {
    _updateTimer();
    notifyListeners();
  }

  void _updateTimer() {
    if (!canShowOffer || secondsRemaining <= 0) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsRemaining <= 1) {
        secondsRemaining = 0;
        status = OrderOfferStatus.expired;
        _timer?.cancel();
        _timer = null;
      } else {
        secondsRemaining--;
      }
      if (!_disposed) notifyListeners();
    });
  }

  bool acceptOffer() {
    if (!canAccept) return false;

    _timer?.cancel();
    _timer = null;
    status = OrderOfferStatus.accepted;
    activeDelivery = offer;
    pickupStatus = PickupStatus.goingToPickup;
    deliveryStatus = DeliveryStatus.onTheWay;
    notifyListeners();
    return true;
  }

  bool rejectOffer() {
    if (!canAccept) return false;

    _timer?.cancel();
    _timer = null;
    status = OrderOfferStatus.rejected;
    notifyListeners();
    return true;
  }

  bool completeActiveDelivery(DemoDelivery delivery) {
    if (activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.onTheWay ||
        deliveryStatus != DeliveryStatus.confirmingDelivery) {
      return false;
    }

    _timer?.cancel();
    _timer = null;
    deliveryStatus = DeliveryStatus.delivered;
    activeDelivery = null;
    pickupStatus = PickupStatus.goingToPickup;
    status = OrderOfferStatus.noOffer;
    secondsRemaining = offerDuration.inSeconds;
    notifyListeners();
    return true;
  }

  bool reachStore(DemoDelivery delivery) => _advancePickup(
    delivery,
    PickupStatus.goingToPickup,
    PickupStatus.reachedPickup,
  );

  bool openOrderDetails(DemoDelivery delivery) => _advancePickup(
    delivery,
    PickupStatus.reachedPickup,
    PickupStatus.orderDetails,
  );

  bool beginPickupVerification(DemoDelivery delivery) => _advancePickup(
    delivery,
    PickupStatus.orderDetails,
    PickupStatus.pickupVerification,
  );

  bool verifyPickup(DemoDelivery delivery, String enteredDigits) {
    if (activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.pickupVerification) {
      return false;
    }

    final expectedDigits = delivery.orderId.replaceAll(RegExp(r'\D'), '');
    final lastFourDigits = expectedDigits.length < 4
        ? expectedDigits
        : expectedDigits.substring(expectedDigits.length - 4);
    if (!RegExp(r'^\d{4}$').hasMatch(enteredDigits) ||
        enteredDigits != lastFourDigits) {
      return false;
    }

    pickupStatus = PickupStatus.pickedUp;
    notifyListeners();
    return true;
  }

  bool continueToDelivery(DemoDelivery delivery) {
    if (activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.pickedUp) {
      return false;
    }

    pickupStatus = PickupStatus.onTheWay;
    deliveryStatus = DeliveryStatus.onTheWay;
    notifyListeners();
    return true;
  }

  bool arriveAtCustomer(DemoDelivery delivery) => _advanceDelivery(
    delivery,
    DeliveryStatus.onTheWay,
    DeliveryStatus.arriving,
  );

  bool startDeliveryConfirmation(DemoDelivery delivery) => _advanceDelivery(
    delivery,
    DeliveryStatus.arriving,
    DeliveryStatus.confirmingDelivery,
  );

  bool _advancePickup(
    DemoDelivery delivery,
    PickupStatus expected,
    PickupStatus next,
  ) {
    if (activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != expected) {
      return false;
    }

    pickupStatus = next;
    notifyListeners();
    return true;
  }

  bool _advanceDelivery(
    DemoDelivery delivery,
    DeliveryStatus expected,
    DeliveryStatus next,
  ) {
    if (activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.onTheWay ||
        deliveryStatus != expected) {
      return false;
    }

    deliveryStatus = next;
    notifyListeners();
    return true;
  }

  bool showAnotherDemoOffer() {
    if (!availabilityStore.isAvailable || isBusy) return false;

    _timer?.cancel();
    _timer = null;
    secondsRemaining = offerDuration.inSeconds;
    status = OrderOfferStatus.available;
    _updateTimer();
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    availabilityStore.removeListener(_handleAvailabilityChanged);
    super.dispose();
  }
}
