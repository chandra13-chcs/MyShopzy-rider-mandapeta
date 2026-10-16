import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_theme.dart';

class RiderMapView extends StatefulWidget {
  const RiderMapView({
    this.pickupLocation,
    this.dropoffLocation,
    this.routePoints = const [],
    this.encodedRoute,
    this.riderLocation,
    this.initialLocation,
    this.showTiles = true,
    this.showCurrentLocation = true,
    this.followRider = true,
    this.height = 300,
    super.key,
  });

  final LatLng? pickupLocation;
  final LatLng? dropoffLocation;
  final List<LatLng> routePoints;
  final String? encodedRoute;
  final LatLng? riderLocation;
  final LatLng? initialLocation;
  final bool showTiles;
  final bool showCurrentLocation;
  final bool followRider;
  final double height;

  @override
  State<RiderMapView> createState() => _RiderMapViewState();
}

class _RiderMapViewState extends State<RiderMapView>
    with SingleTickerProviderStateMixin {
  static const _defaultCenter = LatLng(16.95, 81.99);
  static const _bikeAsset = 'assets/icons/bike.png';

  final MapController _mapController = MapController();
  late final AnimationController _cameraAnimationController;
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _riderLocation;
  LatLng? _cameraCenter;
  LatLng? _animationStart;
  LatLng? _animationEnd;
  String? _locationMessage;
  double _riderHeading = 0;
  double _cameraZoom = 14;
  bool _isLocating = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _riderLocation = widget.riderLocation;
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(_moveCameraFrame);
    if (widget.showCurrentLocation) {
      unawaited(_startLocationTracking());
    }
  }

  @override
  void didUpdateWidget(covariant RiderMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showCurrentLocation != widget.showCurrentLocation) {
      if (widget.showCurrentLocation) {
        unawaited(_startLocationTracking());
      } else {
        unawaited(_positionSubscription?.cancel());
        _positionSubscription = null;
        setState(() => _isLocating = false);
      }
    }
    if (oldWidget.pickupLocation != widget.pickupLocation ||
        oldWidget.dropoffLocation != widget.dropoffLocation ||
        oldWidget.routePoints != widget.routePoints ||
        oldWidget.encodedRoute != widget.encodedRoute ||
        oldWidget.riderLocation != widget.riderLocation ||
        oldWidget.initialLocation != widget.initialLocation) {
      _riderLocation = widget.riderLocation ?? _riderLocation;
      _centerOnAvailableLocation();
    }
  }

  @override
  void dispose() {
    unawaited(_positionSubscription?.cancel());
    _cameraAnimationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setLocationError(
          'Turn on location services to show your live position.',
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setLocationError(
          'Location permission is required to show your live position.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      if (!mounted) return;
      _updateRiderLocation(position);
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen(
            _updateRiderLocation,
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('Rider map location tracking failed: $error');
              _setLocationError('Live location updates are unavailable.');
            },
          );
    } on Object catch (error) {
      debugPrint('Unable to get rider map location: $error');
      _setLocationError('Unable to determine your current location.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _updateRiderLocation(Position position) {
    if (!mounted) return;
    final nextLocation = LatLng(position.latitude, position.longitude);
    final heading = position.heading >= 0 && position.speed > 0.5
        ? position.heading
        : _riderLocation == null
        ? _riderHeading
        : _bearingBetween(_riderLocation!, nextLocation);
    setState(() {
      _riderLocation = nextLocation;
      _riderHeading = heading;
      _locationMessage = null;
    });
    if (widget.followRider) {
      _animateCameraTo(nextLocation, zoom: 16);
    }
  }

  void _setLocationError(String message) {
    if (!mounted) return;
    setState(() {
      _locationMessage = message;
      _isLocating = false;
    });
  }

  void _onMapReady() {
    _mapReady = true;
    _cameraCenter = _initialCenter;
    _cameraZoom = _initialZoom;
    _mapController.move(_initialCenter, _initialZoom);
    final rider = _riderLocation;
    if (widget.followRider && rider != null) {
      _animateCameraTo(rider, zoom: 16);
    }
  }

  void _centerOnAvailableLocation() {
    if (!_mapReady) return;
    final location = _riderLocation ?? _initialCenter;
    _animateCameraTo(
      location,
      zoom: _riderLocation == null ? _initialZoom : 16,
    );
  }

  void _animateCameraTo(LatLng target, {required double zoom}) {
    if (!_mapReady) return;
    _animationStart = _cameraCenter ?? target;
    _animationEnd = target;
    _cameraZoom = zoom;
    _cameraAnimationController.forward(from: 0);
  }

  void _moveCameraFrame() {
    final start = _animationStart;
    final end = _animationEnd;
    if (!_mapReady || start == null || end == null) return;
    final t = Curves.easeOutCubic.transform(_cameraAnimationController.value);
    final center = LatLng(
      start.latitude + (end.latitude - start.latitude) * t,
      start.longitude + (end.longitude - start.longitude) * t,
    );
    _cameraCenter = center;
    _mapController.move(center, _cameraZoom);
  }

  LatLng get _initialCenter {
    final points = _routePoints;
    if (points.isEmpty) {
      return widget.initialLocation ?? _defaultCenter;
    }
    return LatLng(
      points.map((point) => point.latitude).reduce((a, b) => a + b) /
          points.length,
      points.map((point) => point.longitude).reduce((a, b) => a + b) /
          points.length,
    );
  }

  double get _initialZoom {
    final points = _routePoints;
    if (points.length < 2) return 14;
    final latitudes = points.map((point) => point.latitude);
    final longitudes = points.map((point) => point.longitude);
    final latitudeSpan =
        latitudes.reduce(math.max) - latitudes.reduce(math.min);
    final longitudeSpan =
        (longitudes.reduce(math.max) - longitudes.reduce(math.min)) *
        math.cos(_initialCenter.latitude * math.pi / 180);
    final span = math.max(latitudeSpan, longitudeSpan).clamp(0.001, 360);
    return (math.log(360 / span) / math.ln2 - 1).clamp(3, 16).toDouble();
  }

  List<LatLng> get _routePoints {
    if (widget.routePoints.isNotEmpty) return widget.routePoints;
    final encodedRoute = widget.encodedRoute;
    if (encodedRoute != null && encodedRoute.isNotEmpty) {
      try {
        final decoded = PolylinePoints()
            .decodePolyline(encodedRoute)
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList(growable: false);
        if (decoded.length >= 2) return decoded;
      } on RangeError catch (error) {
        debugPrint('Invalid encoded rider route: $error');
      }
    }
    return [?widget.pickupLocation, ?widget.dropoffLocation];
  }

  double _bearingBetween(LatLng from, LatLng to) {
    final fromLatitude = _radians(from.latitude);
    final toLatitude = _radians(to.latitude);
    final longitudeDelta = _radians(to.longitude - from.longitude);
    final y = math.sin(longitudeDelta) * math.cos(toLatitude);
    final x =
        math.cos(fromLatitude) * math.sin(toLatitude) -
        math.sin(fromLatitude) *
            math.cos(toLatitude) *
            math.cos(longitudeDelta);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _radians(double degrees) => degrees * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final routePoints = _routePoints;
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: _initialZoom,
                minZoom: 3,
                maxZoom: 18,
                onMapReady: _onMapReady,
              ),
              children: [
                if (widget.showTiles)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.myshopzy.rider',
                  ),
                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: AppTheme.brandYellow,
                        strokeWidth: 6,
                        borderColor: AppTheme.darkGreen,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_riderLocation case final rider?)
                      Marker(
                        point: rider,
                        width: 56,
                        height: 56,
                        rotate: false,
                        child: Transform.rotate(
                          angle: _riderHeading * math.pi / 180,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.brand,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              _bikeAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.two_wheeler_rounded,
                                    color: AppTheme.brand,
                                    size: 30,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.pickupLocation case final pickup?)
                      Marker(
                        point: pickup,
                        width: 48,
                        height: 68,
                        alignment: Alignment.topCenter,
                        child: const _StopMarker(
                          color: AppTheme.brand,
                          icon: Icons.storefront_rounded,
                          label: 'Pickup',
                        ),
                      ),
                    if (widget.dropoffLocation case final dropoff?)
                      Marker(
                        point: dropoff,
                        width: 48,
                        height: 68,
                        alignment: Alignment.topCenter,
                        child: const _StopMarker(
                          color: AppTheme.brandYellow,
                          icon: Icons.location_on_rounded,
                          label: 'Drop-off',
                          darkIcon: true,
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: const [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            if (_isLocating || _locationMessage != null)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Material(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        if (_isLocating)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.brand,
                            ),
                          )
                        else
                          const Icon(
                            Icons.location_off_rounded,
                            size: 18,
                            color: AppTheme.warning,
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationMessage ?? 'Finding your live location...',
                            style: AppTheme.smallStatus,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StopMarker extends StatelessWidget {
  const _StopMarker({
    required this.color,
    required this.icon,
    required this.label,
    this.darkIcon = false,
  });

  final Color color;
  final IconData icon;
  final String label;
  final bool darkIcon;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: darkIcon ? AppTheme.darkGreen : Colors.white,
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
