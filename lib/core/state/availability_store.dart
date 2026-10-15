import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../network/rider_api_client.dart';

enum AvailabilityStatus { offline, available }

class AvailabilityStore extends ValueNotifier<AvailabilityStatus> {
  AvailabilityStore({
    AvailabilityStatus initialStatus = AvailabilityStatus.available,
    this.apiClient,
    Future<Position> Function()? getCurrentPosition,
    this.checkConnectivity,
    this.connectivityChanges,
  }) : _getCurrentPosition = getCurrentPosition ?? _getDevicePosition,
       super(initialStatus) {
    if (apiClient != null ||
        checkConnectivity != null ||
        connectivityChanges != null) {
      isConnected = false;
      final connectivity = Connectivity();
      _connectivitySubscription = (connectivityChanges ??
              connectivity.onConnectivityChanged)
          .listen(
            _handleConnectivityChanged,
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('Rider connectivity monitoring failed: $error');
              lastError = 'Unable to check internet connection.';
              setConnectivityAvailable(false);
            },
          );
      unawaited(refreshConnectivity());
    }
  }

  final RiderApiClient? apiClient;
  final Future<Position> Function() _getCurrentPosition;
  final Future<List<ConnectivityResult>> Function()? checkConnectivity;
  final Stream<List<ConnectivityResult>>? connectivityChanges;
  int _requestGeneration = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool isConnected = true;

  String? lastError;

  bool get isAvailable => value == AvailabilityStatus.available;
  bool get isOnlineForOrders => isAvailable && isConnected;

  Future<void> refreshConnectivity() async {
    try {
      final results = await (checkConnectivity?.call() ??
          Connectivity().checkConnectivity());
      _handleConnectivityChanged(results);
    } on Object catch (error) {
      debugPrint('Rider connectivity check failed: $error');
      lastError = 'Unable to check internet connection.';
      setConnectivityAvailable(false);
    }
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    setConnectivityAvailable(!results.contains(ConnectivityResult.none));
  }

  void setConnectivityAvailable(bool available) {
    if (isConnected == available) return;
    isConnected = available;
    notifyListeners();
  }

  void setAvailable(bool isAvailable) {
    final nextValue = isAvailable
        ? AvailabilityStatus.available
        : AvailabilityStatus.offline;
    if (value == nextValue) return;
    final generation = ++_requestGeneration;
    lastError = null;
    value = nextValue;
    if (isAvailable && apiClient != null) {
      unawaited(_updateLocation(generation));
    }
  }

  void toggle() => setAvailable(!isAvailable);

  Future<void> _updateLocation(int generation) async {
    try {
      await refreshConnectivity();
      if (generation != _requestGeneration ||
          !isAvailable ||
          !isConnected) {
        return;
      }
      final position = await _getCurrentPosition();
      if (generation != _requestGeneration || !isAvailable) return;
      await apiClient!.updateLocation(position.latitude, position.longitude);
      if (generation == _requestGeneration && isAvailable) {
        lastError = null;
      }
    } on Object catch (error) {
      if (generation != _requestGeneration || !isAvailable) return;
      lastError = error is RiderApiException
          ? error.message
          : 'Unable to get or send your location. Check location permissions.';
      value = AvailabilityStatus.offline;
    }
  }

  @override
  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    super.dispose();
  }

  static Future<Position> _getDevicePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission was not granted.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}
