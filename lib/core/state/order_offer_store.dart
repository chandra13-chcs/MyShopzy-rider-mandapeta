import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/demo_delivery.dart';
import '../network/rider_api_client.dart';
import 'availability_store.dart';

enum OrderOfferStatus { noOffer, available, accepted, rejected, expired }

enum PickupStatus {
  goingToPickup,
  reachedPickup,
  orderDetails,
  pickedUp,
  onTheWay,
}

enum DeliveryStatus { goingToCustomer, reachedCustomer, handOver, delivered }

extension PickupStatusLabel on PickupStatus {
  String get label => switch (this) {
    PickupStatus.goingToPickup => 'Going to Pickup',
    PickupStatus.reachedPickup => 'Reached Store',
    PickupStatus.orderDetails => 'Order Details',
    PickupStatus.pickedUp => 'Pickup Confirmed',
    PickupStatus.onTheWay => 'Going to Customer',
  };
}

extension DeliveryStatusLabel on DeliveryStatus {
  String get label => switch (this) {
    DeliveryStatus.goingToCustomer => 'Going to Customer',
    DeliveryStatus.reachedCustomer => 'Reached Customer',
    DeliveryStatus.handOver => 'Hand Over',
    DeliveryStatus.delivered => 'Delivered',
  };
}

class OrderOfferStore extends ChangeNotifier {
  OrderOfferStore({
    required this.availabilityStore,
    DemoDelivery? activeDelivery = DemoDelivery.batchThreeActive,
    DemoDelivery? offer = DemoDelivery.newOffer,
    this.apiClient,
    this.offerDuration = const Duration(seconds: 20),
  }) : activeDelivery = activeDelivery,
       offer = offer,
       pickupStatus = activeDelivery == null
           ? PickupStatus.goingToPickup
           : PickupStatus.onTheWay,
       deliveryStatus = DeliveryStatus.goingToCustomer,
       status = offer == null
           ? OrderOfferStatus.noOffer
           : OrderOfferStatus.available,
       secondsRemaining = offerDuration.inSeconds {
    availabilityStore.addListener(_handleAvailabilityChanged);
    _updateTimer();
  }

  final AvailabilityStore availabilityStore;
  final RiderApiClient? apiClient;
  final Duration offerDuration;

  DemoDelivery? offer;
  DemoDelivery? activeDelivery;
  PickupStatus pickupStatus;
  DeliveryStatus deliveryStatus;
  OrderOfferStatus status;
  int secondsRemaining;
  String? errorMessage;
  bool isLoadingOffers = false;
  bool isAccepting = false;
  Timer? _timer;
  Timer? _pollTimer;
  bool _disposed = false;
  final Set<String> _rejectedOrderIds = {};

  bool get isBusy => activeDelivery != null;

  String get activeDeliveryStatus => pickupStatus == PickupStatus.onTheWay
      ? deliveryStatus.label
      : pickupStatus.label;

  bool get canShowOffer =>
      availabilityStore.isOnlineForOrders &&
      activeDelivery == null &&
      status == OrderOfferStatus.available &&
      offer != null;

  bool get canAccept =>
      canShowOffer && secondsRemaining > 0 && !isAccepting;

  void _handleAvailabilityChanged() {
    if (apiClient != null) {
      if (availabilityStore.isOnlineForOrders) {
        unawaited(refreshAvailableOrders());
        _startPolling();
      } else {
        _pollTimer?.cancel();
        _pollTimer = null;
        if (activeDelivery == null && !isAccepting) {
          offer = null;
          status = OrderOfferStatus.noOffer;
          _timer?.cancel();
          _timer = null;
        }
      }
    }
    _updateTimer();
    notifyListeners();
  }

  void _startPolling() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(refreshAvailableOrders());
    });
  }

  Future<void> refreshAvailableOrders() async {
    final client = apiClient;
    if (client == null ||
        !availabilityStore.isOnlineForOrders ||
        activeDelivery != null ||
        isLoadingOffers ||
        (offer != null && status == OrderOfferStatus.available)) {
      return;
    }

    isLoadingOffers = true;
    errorMessage = null;
    notifyListeners();
    try {
      final orders = await client.getAvailableOrders();
      if (_disposed || !availabilityStore.isOnlineForOrders) return;
      DemoDelivery? nextOffer;
      for (final order in orders) {
        if (!_rejectedOrderIds.contains(order.orderId)) {
          nextOffer = order;
          break;
        }
      }
      offer = nextOffer;
      status = nextOffer == null
          ? OrderOfferStatus.noOffer
          : OrderOfferStatus.available;
      secondsRemaining = offerDuration.inSeconds;
      _updateTimer();
    } on Object catch (error) {
      if (error is RiderApiException && error.statusCode == 0) {
        availabilityStore.setConnectivityAvailable(false);
      }
      if (!_disposed) {
        offer = null;
        status = OrderOfferStatus.noOffer;
        errorMessage = error is RiderApiException
            ? error.message
            : 'Unable to load available orders.';
      }
    } finally {
      isLoadingOffers = false;
      if (!_disposed) notifyListeners();
    }
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
        final expiredOrderId = offer?.orderId;
        if (expiredOrderId != null && apiClient != null) {
          _rejectedOrderIds.add(expiredOrderId);
          offer = null;
        }
        _timer?.cancel();
        _timer = null;
        if (apiClient != null) unawaited(refreshAvailableOrders());
      } else {
        secondsRemaining--;
      }
      if (!_disposed) notifyListeners();
    });
  }

  bool acceptOffer() {
    if (!canAccept || offer == null) return false;

    _timer?.cancel();
    _timer = null;
    status = OrderOfferStatus.accepted;
    activeDelivery = offer;
    pickupStatus = PickupStatus.goingToPickup;
    deliveryStatus = DeliveryStatus.goingToCustomer;
    notifyListeners();
    return true;
  }

  Future<bool> acceptAvailableOffer() async {
    final client = apiClient;
    final currentOffer = offer;
    if (client == null) return acceptOffer();
    if (!canAccept || currentOffer == null) return false;

    isAccepting = true;
    errorMessage = null;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
    try {
      await client.acceptOrder(currentOffer.orderId);
      if (_disposed || offer?.orderId != currentOffer.orderId) return false;
      isAccepting = false;
      status = OrderOfferStatus.accepted;
      activeDelivery = currentOffer;
      pickupStatus = PickupStatus.goingToPickup;
      deliveryStatus = DeliveryStatus.goingToCustomer;
      notifyListeners();
      return true;
    } on Object catch (error) {
      if (_disposed) return false;
      isAccepting = false;
      if (availabilityStore.isOnlineForOrders) {
        status = OrderOfferStatus.available;
        secondsRemaining = offerDuration.inSeconds;
      } else {
        offer = null;
        status = OrderOfferStatus.noOffer;
      }
      if (error is RiderApiException && error.statusCode == 0) {
        availabilityStore.setConnectivityAvailable(false);
      }
      errorMessage = error is RiderApiException
          ? error.message
          : 'Unable to accept this order.';
      _updateTimer();
      notifyListeners();
      return false;
    }
  }

  bool rejectOffer() {
    if (!canAccept || offer == null) return false;

    _timer?.cancel();
    _timer = null;
    if (apiClient != null) {
      _rejectedOrderIds.add(offer!.orderId);
      offer = null;
    }
    status = OrderOfferStatus.rejected;
    if (apiClient != null) unawaited(refreshAvailableOrders());
    notifyListeners();
    return true;
  }

  bool completeActiveDelivery(DemoDelivery delivery) {
    if (activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.onTheWay ||
        deliveryStatus != DeliveryStatus.handOver) {
      return false;
    }

    _timer?.cancel();
    _timer = null;
    final orderId = delivery.orderId;
    deliveryStatus = DeliveryStatus.delivered;
    activeDelivery = null;
    pickupStatus = PickupStatus.goingToPickup;
    status = OrderOfferStatus.noOffer;
    secondsRemaining = offerDuration.inSeconds;
    if (apiClient != null) {
      _updateRemoteStatus(orderId, 'delivered');
      offer = null;
      unawaited(refreshAvailableOrders());
    }
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

  bool verifyPickup(DemoDelivery delivery, String enteredDigits) {
    if (activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.orderDetails) {
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
    _updateRemoteStatus(delivery.orderId, 'picked_up');
    notifyListeners();
    return true;
  }

  bool continueToDelivery(DemoDelivery delivery) {
    if (activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.pickedUp) {
      return false;
    }

    pickupStatus = PickupStatus.onTheWay;
    deliveryStatus = DeliveryStatus.goingToCustomer;
    notifyListeners();
    return true;
  }

  bool arriveAtCustomer(DemoDelivery delivery) => _advanceDelivery(
    delivery,
    DeliveryStatus.goingToCustomer,
    DeliveryStatus.reachedCustomer,
  );

  bool handOverOrder(DemoDelivery delivery) => _advanceDelivery(
    delivery,
    DeliveryStatus.reachedCustomer,
    DeliveryStatus.handOver,
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
    _pollTimer?.cancel();
    availabilityStore.removeListener(_handleAvailabilityChanged);
    super.dispose();
  }

  void _updateRemoteStatus(String orderId, String nextStatus) {
    final client = apiClient;
    if (client == null) return;
    unawaited(
      client
          .updateOrderStatus(orderId, nextStatus)
          .catchError((Object error) {
            if (_disposed) return <String, dynamic>{};
            errorMessage = error is RiderApiException
                ? error.message
                : 'Unable to update the order status.';
            notifyListeners();
            return <String, dynamic>{};
          }),
    );
  }
}
