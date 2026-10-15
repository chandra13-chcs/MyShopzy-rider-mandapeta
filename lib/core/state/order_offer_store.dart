import 'dart:async';
import 'dart:math' as math;

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
    this.offerDuration = const Duration(seconds: 30),
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
  bool isUpdatingOrderStatus = false;
  int? todaySettlementMinor;
  int? todayCompletedDeliveries;
  int? _lastDeliveredPayoutMinor;
  String? earningsErrorMessage;
  Timer? _timer;
  Timer? _pollTimer;
  bool _disposed = false;
  bool _isFlushingQueuedStatuses = false;
  int _offerRevision = 0;
  final List<({String orderId, String status})> _queuedOrderStatuses = [];
  final Set<String> _rejectedOrderIds = {};

  bool get isBusy => activeDelivery != null;
  int get queuedOrderStatusCount => _queuedOrderStatuses.length;
  int get offerRevision => _offerRevision;

  String get activeDeliveryStatus => pickupStatus == PickupStatus.onTheWay
      ? deliveryStatus.label
      : pickupStatus.label;

  bool get canShowOffer =>
      availabilityStore.isOnlineForOrders &&
      activeDelivery == null &&
      status == OrderOfferStatus.available &&
      offer != null;

  bool get canAccept =>
      availabilityStore.isAvailable &&
      availabilityStore.isConnected &&
      canShowOffer &&
      secondsRemaining > 0 &&
      !isAccepting;

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
      if (availabilityStore.isConnected) {
        unawaited(_flushQueuedOrderStatuses());
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
          nextOffer = _estimateDistances(order);
          break;
        }
      }
      offer = nextOffer;
      if (nextOffer != null) _offerRevision++;
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
    if (apiClient != null || !canAccept || offer == null) return false;

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
      final response = await client.acceptOrder(currentOffer.orderId);
      if (_disposed || offer?.orderId != currentOffer.orderId) return false;
      final acceptedOrder =
          (response['data'] as Map<String, dynamic>?)?['order'];
      final enrichedOffer = acceptedOrder is Map<String, dynamic>
          ? _estimateDistances(DemoDelivery.fromRiderApiJson(acceptedOrder))
          : currentOffer;
      isAccepting = false;
      status = OrderOfferStatus.accepted;
      activeDelivery = enrichedOffer;
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
          : error is FormatException
          ? 'The server returned invalid order details.'
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
    return apiClient == null && _finalizeActiveDelivery(delivery);
  }

  bool _finalizeActiveDelivery(DemoDelivery delivery) {
    if (activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.onTheWay ||
        deliveryStatus != DeliveryStatus.handOver) {
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

  bool verifyPickup(DemoDelivery delivery, String enteredDigits) {
    if (apiClient != null ||
        activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.orderDetails) {
      return false;
    }

    if (!_hasValidPickupDigits(delivery, enteredDigits)) return false;

    pickupStatus = PickupStatus.pickedUp;
    notifyListeners();
    return true;
  }

  bool continueToDelivery(DemoDelivery delivery) {
    if (apiClient != null ||
        activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.pickedUp) {
      return false;
    }

    pickupStatus = PickupStatus.onTheWay;
    deliveryStatus = DeliveryStatus.goingToCustomer;
    notifyListeners();
    return true;
  }

  Future<bool> confirmPickup(
    DemoDelivery delivery,
    String enteredDigits,
  ) async {
    if (!_hasValidPickupDigits(delivery, enteredDigits) ||
        activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.orderDetails ||
        isUpdatingOrderStatus) {
      return false;
    }
    if (!await _updateRemoteStatus(delivery.orderId, 'picked_up')) {
      return false;
    }
    pickupStatus = PickupStatus.pickedUp;
    notifyListeners();
    return true;
  }

  Future<bool> startDelivery(DemoDelivery delivery) async {
    if (activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.pickedUp ||
        isUpdatingOrderStatus) {
      return false;
    }
    if (!await _updateRemoteStatus(delivery.orderId, 'out_for_delivery')) {
      return false;
    }
    pickupStatus = PickupStatus.onTheWay;
    deliveryStatus = DeliveryStatus.goingToCustomer;
    notifyListeners();
    return true;
  }

  Future<bool> completeDelivery(DemoDelivery delivery) async {
    if (apiClient == null) return completeActiveDelivery(delivery);
    if (activeDelivery?.orderId != delivery.orderId ||
        pickupStatus != PickupStatus.onTheWay ||
        deliveryStatus != DeliveryStatus.handOver ||
        isUpdatingOrderStatus) {
      return false;
    }
    if (!await _updateRemoteStatus(delivery.orderId, 'delivered')) {
      return false;
    }
    final completed = _finalizeActiveDelivery(delivery);
    if (completed) {
      final currentSettlement = todaySettlementMinor;
      final currentCount = todayCompletedDeliveries;
      if (currentSettlement != null && _lastDeliveredPayoutMinor != null) {
        todaySettlementMinor = currentSettlement + _lastDeliveredPayoutMinor!;
      }
      if (currentCount != null) todayCompletedDeliveries = currentCount + 1;
      offer = null;
      unawaited(refreshAvailableOrders());
      unawaited(refreshEarnings());
    }
    return completed;
  }

  Future<void> refreshEarnings() async {
    final client = apiClient;
    if (client == null || !availabilityStore.isConnected) return;
    try {
      final response = await client.getEarningsSummary();
      final data = response['data'];
      final summary = data is Map<String, dynamic> ? data['summary'] : null;
      if (summary is! Map<String, dynamic>) {
        throw const FormatException('Missing earnings summary.');
      }
      final payoutMinor = _readNonNegativeInt(summary['todayPayoutMinor']);
      final completed = _readNonNegativeInt(summary['todayDeliveries']);
      if (payoutMinor == null || completed == null) {
        throw const FormatException('Invalid earnings summary.');
      }
      todaySettlementMinor = payoutMinor;
      todayCompletedDeliveries = completed;
      earningsErrorMessage = null;
    } on Object catch (error) {
      earningsErrorMessage = error is RiderApiException
          ? error.message
          : 'Unable to load your earnings summary.';
    }
    if (!_disposed) notifyListeners();
  }

  static int? _readNonNegativeInt(Object? value) {
    final parsed = value is int ? value : int.tryParse('$value');
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  DemoDelivery _estimateDistances(DemoDelivery delivery) {
    final riderPosition = availabilityStore.lastPosition;
    final pickupDistance = riderPosition == null ||
            delivery.pickupLatitude == null ||
            delivery.pickupLongitude == null
        ? null
        : _distanceKm(
            riderPosition.latitude,
            riderPosition.longitude,
            delivery.pickupLatitude!,
            delivery.pickupLongitude!,
          );
    final deliveryDistance = delivery.pickupLatitude == null ||
            delivery.pickupLongitude == null ||
            delivery.dropLatitude == null ||
            delivery.dropLongitude == null
        ? null
        : _distanceKm(
            delivery.pickupLatitude!,
            delivery.pickupLongitude!,
            delivery.dropLatitude!,
            delivery.dropLongitude!,
          );
    if (pickupDistance == null && deliveryDistance == null) return delivery;
    final total = (pickupDistance ?? 0) + (deliveryDistance ?? 0);
    return delivery.copyWith(
      distanceKm: total,
      pickupDistanceKm: pickupDistance,
      deliveryDistanceKm: deliveryDistance,
      hasRouteEstimate: true,
    );
  }

  static double _distanceKm(
    double firstLatitude,
    double firstLongitude,
    double secondLatitude,
    double secondLongitude,
  ) {
    const earthRadiusKm = 6371.0088;
    final latitudeDelta = _radians(secondLatitude - firstLatitude);
    final longitudeDelta = _radians(secondLongitude - firstLongitude);
    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(_radians(firstLatitude)) *
            math.cos(_radians(secondLatitude)) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return earthRadiusKm * 2 * math.asin(math.sqrt(haversine.clamp(0, 1)));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

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

  Future<bool> _updateRemoteStatus(String orderId, String nextStatus) async {
    if (apiClient == null) return true;
    if (isUpdatingOrderStatus) return false;
    isUpdatingOrderStatus = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (!availabilityStore.isConnected) {
        _queueOrderStatus(orderId, nextStatus);
        errorMessage = 'Saved offline. This status will sync when connected.';
        return true;
      }
      final response = await apiClient!.updateOrderStatus(orderId, nextStatus);
      _recordDeliveredPayout(nextStatus, response);
      return true;
    } on Object catch (error) {
      if (error is RiderApiException && error.statusCode == 0) {
        _queueOrderStatus(orderId, nextStatus);
        availabilityStore.setConnectivityAvailable(false);
        errorMessage = 'Saved offline. This status will sync when connected.';
        return true;
      }
      _setStatusError(error);
      return false;
    } finally {
      isUpdatingOrderStatus = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _queueOrderStatus(String orderId, String status) {
    if (_queuedOrderStatuses.any(
      (entry) => entry.orderId == orderId && entry.status == status,
    )) {
      return;
    }
    _queuedOrderStatuses.add((orderId: orderId, status: status));
    notifyListeners();
  }

  Future<void> _flushQueuedOrderStatuses() async {
    if (_isFlushingQueuedStatuses ||
        _queuedOrderStatuses.isEmpty ||
        !availabilityStore.isConnected ||
        apiClient == null) {
      return;
    }

    _isFlushingQueuedStatuses = true;
    try {
      while (_queuedOrderStatuses.isNotEmpty &&
          availabilityStore.isConnected) {
        final queued = _queuedOrderStatuses.first;
        try {
          final response = await apiClient!.updateOrderStatus(
            queued.orderId,
            queued.status,
          );
          _queuedOrderStatuses.removeAt(0);
          _recordDeliveredPayout(queued.status, response);
          if (queued.status == 'delivered') unawaited(refreshEarnings());
          errorMessage = null;
          if (!_disposed) notifyListeners();
        } on Object catch (error) {
          _setStatusError(error);
          if (error is RiderApiException && error.statusCode == 0) {
            availabilityStore.setConnectivityAvailable(false);
          }
          if (!_disposed) notifyListeners();
          break;
        }
      }
    } finally {
      _isFlushingQueuedStatuses = false;
    }
  }

  void _recordDeliveredPayout(
    String status,
    Map<String, dynamic> response,
  ) {
    if (status != 'delivered') return;
    final data = response['data'];
    final order = data is Map<String, dynamic> ? data['order'] : null;
    _lastDeliveredPayoutMinor = order is Map<String, dynamic>
        ? _readNonNegativeInt(order['payoutMinor'])
        : null;
  }

  void _setStatusError(Object error) {
    if (error is RiderApiException && error.statusCode == 0) {
      availabilityStore.setConnectivityAvailable(false);
    }
    errorMessage = error is RiderApiException
        ? error.message
        : 'Unable to update the order status.';
  }

  static bool _hasValidPickupDigits(
    DemoDelivery delivery,
    String enteredDigits,
  ) {
    final expectedDigits = delivery.orderId.replaceAll(RegExp(r'\D'), '');
    final lastFourDigits = expectedDigits.length < 4
        ? expectedDigits
        : expectedDigits.substring(expectedDigits.length - 4);
    return RegExp(r'^\d{4}$').hasMatch(enteredDigits) &&
        enteredDigits == lastFourDigits;
  }
}
