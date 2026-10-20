import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../core/state/availability_store.dart';
import '../core/state/new_order_alert.dart';
import '../core/state/order_offer_store.dart';
import '../core/models/demo_delivery.dart';
import '../core/network/rider_api_client.dart';
import '../core/theme/app_theme.dart';
import '../delivery/delivery_page.dart';
import '../earnings/earnings_page.dart';
import '../gigs/gig_repository.dart';
import '../gigs/gigs_page.dart';
import '../home/home_demo_data.dart';
import '../home/home_page.dart';
import '../orders/incoming_order_offer_dialog.dart';
import '../orders/orders_page.dart';
import '../profile/profile_page.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({
    this.apiClient,
    this.showDemoOrder = false,
    this.demoRiderLocation,
    super.key,
  });

  final RiderApiClient? apiClient;
  final bool showDemoOrder;
  final LatLng? demoRiderLocation;

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isForeground = true;
  bool _incomingDialogShowing = false;
  String? _presentedOfferToken;
  bool _demoOfferInitialized = false;
  late final AnimationController _tabTransitionController;
  double _tabSlideDirection = 1;

  late final _availabilityStore = AvailabilityStore(
    initialStatus: widget.apiClient == null
        ? AvailabilityStatus.available
        : AvailabilityStatus.offline,
    apiClient: widget.apiClient,
  );
  late final _offerStore = OrderOfferStore(
    availabilityStore: _availabilityStore,
    activeDelivery: widget.showDemoOrder
        ? null
        : widget.apiClient == null
        ? HomeDemoData().activeDelivery
        : null,
    offer: widget.showDemoOrder
        ? null
        : widget.apiClient == null
        ? DemoDelivery.newOffer
        : null,
    apiClient: widget.apiClient,
  );
  late final _gigRepository = DemoGigRepository();
  late final _newOrderAlert = NewOrderAlert();
  late final _pages = [
    HomePage(availabilityStore: _availabilityStore, offerStore: _offerStore),
    OrdersPage(availabilityStore: _availabilityStore, offerStore: _offerStore),
    EarningsPage(offerStore: _offerStore),
    GigsPage(availabilityStore: _availabilityStore, repository: _gigRepository),
    ProfilePage(
      availabilityStore: _availabilityStore,
      newOrderAlert: _newOrderAlert,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..value = 1;
    WidgetsBinding.instance.addObserver(this);
    _offerStore.addListener(_handleOfferStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.showDemoOrder && widget.apiClient == null) {
        _offerStore.requireDemoOffersNearRider();
        final location = widget.demoRiderLocation;
        if (location == null) {
          unawaited(_availabilityStore.startLocalLocationTracking());
        } else {
          _offerStore.setDemoOfferForRiderLocation(
            latitude: location.latitude,
            longitude: location.longitude,
          );
          _demoOfferInitialized = true;
        }
      }
      if (widget.apiClient != null) {
        unawaited(_offerStore.refreshAvailableOrders());
        unawaited(_offerStore.refreshEarnings());
      }
      _handleOfferStoreChanged();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      if (widget.apiClient != null) {
        unawaited(_offerStore.refreshAvailableOrders());
      }
      _handleOfferStoreChanged();
    } else {
      unawaited(_newOrderAlert.stop());
    }
  }

  void _handleOfferStoreChanged() {
    if (widget.showDemoOrder &&
        !_demoOfferInitialized &&
        _offerStore.offer == null &&
        _offerStore.activeDelivery == null) {
      final position = _availabilityStore.lastPosition;
      if (position != null) {
        _demoOfferInitialized = true;
        _offerStore.setDemoOfferForRiderLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        return;
      }
    }

    if (!_offerStore.canShowOffer) {
      unawaited(_newOrderAlert.stop());
      if (_offerStore.status != OrderOfferStatus.available) {
        _presentedOfferToken = null;
      }
      if (_incomingDialogShowing &&
          _offerStore.status != OrderOfferStatus.accepted &&
          _offerStore.status != OrderOfferStatus.rejected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_incomingDialogShowing || _offerStore.canShowOffer) {
            return;
          }
          Navigator.of(context, rootNavigator: true).pop();
        });
      }
      return;
    }

    if (!_isForeground) return;

    final orderId = _offerStore.offer?.orderId;
    if (orderId == null) return;
    final offerToken = '$orderId:${_offerStore.offerRevision}';
    _newOrderAlert.start(offerToken);
    if (_presentedOfferToken == offerToken || _incomingDialogShowing) return;

    _presentedOfferToken = offerToken;
    _incomingDialogShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showIncomingOffer(orderId, offerToken);
    });
  }

  Future<void> _showIncomingOffer(String orderId, String offerToken) async {
    final currentOffer = _offerStore.offer;
    final currentOfferToken = currentOffer == null
        ? null
        : '${currentOffer.orderId}:${_offerStore.offerRevision}';
    if (!_offerStore.canShowOffer ||
        currentOfferToken != offerToken ||
        currentOffer?.orderId != orderId) {
      if (_presentedOfferToken == offerToken) {
        _presentedOfferToken = null;
      }
      _incomingDialogShowing = false;
      _handleOfferStoreChanged();
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppTheme.surface,
      useSafeArea: false,
      builder: (_) => IncomingOrderOfferDialog(
        offerStore: _offerStore,
        soundNeedsActivation: _newOrderAlert.soundNeedsActivation,
        onEnableSound: _newOrderAlert.enableSound,
      ),
    );
    _incomingDialogShowing = false;
    if (_presentedOfferToken == offerToken) {
      _presentedOfferToken = null;
    }

    if (!mounted) return;
    _handleOfferStoreChanged();
    if (accepted != true) return;
    final delivery = _offerStore.activeDelivery;
    if (delivery == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            DeliveryPage(delivery: delivery, offerStore: _offerStore),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabTransitionController.dispose();
    _offerStore.removeListener(_handleOfferStoreChanged);
    unawaited(_newOrderAlert.dispose());
    _offerStore.dispose();
    _availabilityStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _availabilityStore,
        builder: (context, _) => Column(
          children: [
            if (_availabilityStore.isOverspeeding)
              _OverspeedingBanner(speedKmh: _availabilityStore.speedKmh),
            Expanded(
              child: AnimatedBuilder(
                animation: _tabTransitionController,
                builder: (context, _) {
                  final progress = Curves.easeOutCubic.transform(
                    _tabTransitionController.value,
                  );
                  final remaining = 1 - progress;
                  var rotationX = 0.0;
                  var rotationY = 0.0;
                  var rotationZ = 0.0;
                  var slideX = 0.0;
                  var slideY = 0.0;
                  var startScale = 0.96;
                  switch (_selectedIndex) {
                    case 0:
                      rotationZ = -0.045;
                      rotationY = 0.08 * _tabSlideDirection;
                      slideY = 30;
                      startScale = 0.97;
                      break;
                    case 1:
                      rotationY = -0.34 * _tabSlideDirection;
                      slideX = 58 * _tabSlideDirection;
                      break;
                    case 2:
                      rotationX = 0.3;
                      slideY = 52;
                      startScale = 0.95;
                      break;
                    case 3:
                      rotationY = 0.36 * _tabSlideDirection;
                      rotationZ = 0.025 * _tabSlideDirection;
                      slideX = -58 * _tabSlideDirection;
                      startScale = 0.95;
                      break;
                    case 4:
                      rotationX = -0.28;
                      rotationZ = 0.035;
                      slideY = -44;
                      startScale = 0.94;
                      break;
                  }
                  final scale = startScale + ((1 - startScale) * progress);
                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..translateByDouble(
                      slideX * remaining,
                      slideY * remaining,
                      0,
                      1,
                    )
                    ..rotateX(rotationX * remaining)
                    ..rotateY(rotationY * remaining)
                    ..rotateZ(rotationZ * remaining)
                    ..scaleByDouble(scale, scale, scale, 1);
                  return ClipRect(
                    child: Opacity(
                      opacity: progress,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: transform,
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: _pages,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        animationDuration: const Duration(milliseconds: 200),
        onDestinationSelected: (index) {
          if (index == _selectedIndex) return;
          _tabSlideDirection = index > _selectedIndex ? 1 : -1;
          setState(() => _selectedIndex = index);
          if (MediaQuery.disableAnimationsOf(context)) {
            _tabTransitionController.value = 1;
          } else {
            _tabTransitionController.forward(from: 0);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Gigs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _OverspeedingBanner extends StatelessWidget {
  const _OverspeedingBanner({required this.speedKmh});

  final double? speedKmh;

  @override
  Widget build(BuildContext context) {
    final speed = speedKmh;
    final message = speed == null
        ? 'Overspeeding Alert: Please ride safely below 50 km/h!'
        : 'Overspeeding Alert: Please ride safely below 50 km/h! '
              'Current speed: ${speed.toStringAsFixed(1)} km/h.';

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          color: AppTheme.brandYellow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.darkGreen,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.darkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
