import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/demo_delivery.dart';
import 'availability_store.dart';

enum OrderOfferStatus { noOffer, available, accepted, rejected, expired }

class OrderOfferStore extends ChangeNotifier {
  OrderOfferStore({
    required this.availabilityStore,
    this.activeDelivery = DemoDelivery.batchThreeActive,
    this.offer = DemoDelivery.newOffer,
    this.offerDuration = const Duration(seconds: 20),
  }) : secondsRemaining = offerDuration.inSeconds {
    availabilityStore.addListener(_handleAvailabilityChanged);
    _updateTimer();
  }

  final AvailabilityStore availabilityStore;
  final DemoDelivery offer;
  final Duration offerDuration;

  DemoDelivery? activeDelivery;
  OrderOfferStatus status = OrderOfferStatus.available;
  int secondsRemaining;
  Timer? _timer;
  bool _disposed = false;

  bool get isBusy => activeDelivery != null;

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
    activeDelivery = offer.copyWith(status: 'On the Way');
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
    if (activeDelivery?.orderId != delivery.orderId) return false;

    _timer?.cancel();
    _timer = null;
    activeDelivery = null;
    status = OrderOfferStatus.noOffer;
    secondsRemaining = offerDuration.inSeconds;
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
