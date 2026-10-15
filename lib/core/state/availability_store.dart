import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../network/rider_api_client.dart';

enum AvailabilityStatus { offline, available }

class AvailabilityStore extends ValueNotifier<AvailabilityStatus> {
  AvailabilityStore({
    AvailabilityStatus initialStatus = AvailabilityStatus.available,
    this.apiClient,
    Future<Position> Function()? getCurrentPosition,
    Stream<Position> Function()? positionStream,
    Future<void> Function()? playOverspeedSound,
    this.checkConnectivity,
    this.connectivityChanges,
  }) : _getCurrentPosition = getCurrentPosition ?? _getDevicePosition,
       _positionStream =
           positionStream ??
           (getCurrentPosition == null ? _getDevicePositionStream : null),
       _playOverspeedSound = playOverspeedSound ?? _playSystemAlertSound,
       super(initialStatus) {
    if (apiClient != null ||
        checkConnectivity != null ||
        connectivityChanges != null) {
      isConnected = false;
      final connectivity = Connectivity();
      _connectivitySubscription =
          (connectivityChanges ?? connectivity.onConnectivityChanged).listen(
            _handleConnectivityStreamChanged,
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
  final Stream<Position> Function()? _positionStream;
  final Future<void> Function() _playOverspeedSound;
  final Future<List<ConnectivityResult>> Function()? checkConnectivity;
  final Stream<List<ConnectivityResult>>? connectivityChanges;
  int _requestGeneration = 0;
  int _connectivityCheckGeneration = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  Position? _pendingLocation;
  int? _startingGeneration;
  bool _locationTrackingRequested = false;
  bool _isFlushingLocations = false;
  bool _isFlushingAvailability = false;
  bool? _queuedAvailabilityUpdate;
  bool isConnected = true;
  Position? get lastPosition => _lastPosition;
  bool _hasPostedLocation = false;
  bool get hasQueuedAvailabilityUpdate => _queuedAvailabilityUpdate != null;
  static const double overspeedLimitKmh = 50;
  double? speedKmh;
  bool isOverspeeding = false;

  String? lastError;

  bool get isAvailable => value == AvailabilityStatus.available;
  bool get hasQueuedLocation => _pendingLocation != null;
  bool get isOnlineForOrders =>
      isAvailable && isConnected && (apiClient == null || _hasPostedLocation);

  Future<void> refreshConnectivity() async {
    final generation = ++_connectivityCheckGeneration;
    try {
      final results =
          await (checkConnectivity?.call() ??
              Connectivity().checkConnectivity());
      if (generation != _connectivityCheckGeneration) return;
      _handleConnectivityChanged(results);
    } on Object catch (error) {
      if (generation != _connectivityCheckGeneration) return;
      debugPrint('Rider connectivity check failed: $error');
      lastError = 'Unable to check internet connection.';
      setConnectivityAvailable(false);
    }
  }

  void _handleConnectivityStreamChanged(List<ConnectivityResult> results) {
    _connectivityCheckGeneration++;
    _handleConnectivityChanged(results);
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    final connected = !results.contains(ConnectivityResult.none);
    final wasConnected = isConnected;
    setConnectivityAvailable(connected);
    if (connected) unawaited(_flushQueuedAvailability());
    if (connected &&
        !wasConnected &&
        isAvailable &&
        apiClient != null &&
        _locationTrackingRequested) {
      final position = _lastPosition ?? _pendingLocation;
      if (position != null) {
        _pendingLocation ??= position;
        unawaited(_flushQueuedLocations(_requestGeneration));
      } else {
        unawaited(_startLocationTracking(_requestGeneration));
      }
    }
  }

  void setConnectivityAvailable(bool available) {
    if (isConnected == available) return;
    isConnected = available;
    if (!available) {
      _hasPostedLocation = false;
      if (isAvailable && _locationTrackingRequested) {
        lastError = 'Connection lost. Your latest location will sync when connected.';
      }
    } else {
      unawaited(_flushQueuedAvailability());
    }
    notifyListeners();
  }

  void setAvailable(bool isAvailable) {
    final nextValue = isAvailable
        ? AvailabilityStatus.available
        : AvailabilityStatus.offline;
    if (value == nextValue) return;
    final generation = ++_requestGeneration;
    lastError = null;
    if (!isAvailable) {
      speedKmh = null;
      isOverspeeding = false;
      _pendingLocation = null;
    } else {
      _queuedAvailabilityUpdate = null;
    }
    value = nextValue;
    if (apiClient == null) return;
    if (isAvailable) {
      _hasPostedLocation = false;
      _locationTrackingRequested = true;
      if (isConnected) unawaited(_startLocationTracking(generation));
    } else {
      _hasPostedLocation = false;
      _locationTrackingRequested = false;
      unawaited(_stopLocationTracking());
      unawaited(_setRemoteOffline());
    }
  }

  void toggle() => setAvailable(!isAvailable);

  Future<void> _startLocationTracking(int generation) async {
    if (_startingGeneration == generation ||
        _positionSubscription != null ||
        !isAvailable ||
        !isConnected) {
      return;
    }
    _startingGeneration = generation;
    try {
      final position = await _getCurrentPosition();
      if (generation != _requestGeneration || !isAvailable) return;
      await _postPosition(position, generation);
      final positions = _positionStream?.call();
      if (positions != null &&
          generation == _requestGeneration &&
          isAvailable) {
        _positionSubscription = positions.listen(
          (nextPosition) => unawaited(_postPosition(nextPosition, generation)),
          onError: (Object error, StackTrace stackTrace) {
            if (generation != _requestGeneration || !isAvailable) return;
            debugPrint('Rider location stream failed: $error');
            lastError = 'Unable to keep sharing your location.';
            setAvailable(false);
          },
        );
      }
    } on Object catch (error) {
      if (generation != _requestGeneration || !isAvailable) return;
      lastError = error is RiderApiException
          ? error.message
          : 'Unable to get or send your location. Check location permissions.';
      setAvailable(false);
      lastError = error is RiderApiException
          ? error.message
          : 'Unable to get or send your location. Check location permissions.';
      notifyListeners();
    } finally {
      if (_startingGeneration == generation) _startingGeneration = null;
    }
  }

  Future<void> _postPosition(Position position, int generation) async {
    if (generation != _requestGeneration ||
        !isAvailable ||
        apiClient == null) {
      return;
    }

    _updateSpeedWarning(position);
    _lastPosition = position;
    _pendingLocation = position;
    if (!isConnected) return;
    await _flushQueuedLocations(generation);
  }

  Future<void> _flushQueuedLocations(int generation) async {
    if (_isFlushingLocations ||
        generation != _requestGeneration ||
        !isAvailable ||
        !isConnected ||
        apiClient == null) {
      return;
    }

    _isFlushingLocations = true;
    try {
      while (_pendingLocation != null &&
          generation == _requestGeneration &&
          isAvailable &&
          isConnected) {
        final position = _pendingLocation!;
        _pendingLocation = null;
        try {
          await apiClient!.updateLocation(
            position.latitude,
            position.longitude,
          );
        } on Object catch (error) {
          _pendingLocation ??= position;
          if (generation != _requestGeneration || !isAvailable) return;
          if (error is RiderApiException && error.statusCode == 0) {
            setConnectivityAvailable(false);
          } else {
            final message = error is RiderApiException
                ? error.message
                : 'Unable to send your location.';
            setAvailable(false);
            lastError = message;
            notifyListeners();
          }
          return;
        }
        if (generation == _requestGeneration && isAvailable && isConnected) {
          _hasPostedLocation = true;
          lastError = null;
          notifyListeners();
        }
      }
    } finally {
      _isFlushingLocations = false;
    }
  }

  void _updateSpeedWarning(Position position) {
    final speed = position.speed;
    speedKmh = speed.isFinite && speed >= 0 ? speed * 3.6 : null;
    final overspeeding =
        speedKmh != null && speedKmh! > overspeedLimitKmh;
    if (isOverspeeding == overspeeding) return;

    isOverspeeding = overspeeding;
    notifyListeners();
    if (overspeeding) unawaited(_playOverspeedSoundSafely());
  }

  Future<void> _playOverspeedSoundSafely() async {
    try {
      await _playOverspeedSound();
    } on Exception catch (error) {
      debugPrint('Unable to play the overspeeding warning: $error');
    }
  }

  static Future<void> _playSystemAlertSound() =>
      SystemSound.play(SystemSoundType.alert);

  Future<void> _setRemoteOffline() async {
    _queuedAvailabilityUpdate = false;
    if (!isConnected) {
      lastError = 'Duty status saved offline. It will sync when connected.';
      notifyListeners();
      return;
    }
    await _flushQueuedAvailability();
  }

  Future<void> _flushQueuedAvailability() async {
    if (_isFlushingAvailability ||
        _queuedAvailabilityUpdate == null ||
        !isConnected ||
        apiClient == null) {
      return;
    }

    _isFlushingAvailability = true;
    try {
      final requestedAvailability = _queuedAvailabilityUpdate!;
      await apiClient!.updateAvailability(requestedAvailability);
      if (_queuedAvailabilityUpdate == requestedAvailability) {
        _queuedAvailabilityUpdate = null;
        lastError = null;
      }
    } on Object catch (error) {
      if (error is RiderApiException && error.statusCode == 0) {
        setConnectivityAvailable(false);
      }
      lastError = error is RiderApiException
          ? error.message
          : 'Unable to update your duty status.';
    } finally {
      _isFlushingAvailability = false;
      notifyListeners();
    }
  }

  Future<void> _stopLocationTracking() async {
    final subscription = _positionSubscription;
    _positionSubscription = null;
    await subscription?.cancel();
  }

  @override
  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    unawaited(_stopLocationTracking());
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

  static Stream<Position> _getDevicePositionStream() =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
}
