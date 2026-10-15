import 'dart:async';

import 'package:flutter/material.dart';

import '../core/state/availability_store.dart';
import '../core/state/new_order_alert.dart';
import '../core/state/order_offer_store.dart';
import '../core/models/demo_delivery.dart';
import '../core/network/rider_api_client.dart';
import '../core/theme/app_theme.dart';
import '../delivery/delivery_page.dart';
import '../earnings/earnings_page.dart';
import '../gigs/gigs_page.dart';
import '../home/home_demo_data.dart';
import '../home/home_page.dart';
import '../orders/incoming_order_offer_dialog.dart';
import '../orders/orders_page.dart';
import '../profile/profile_page.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({this.apiClient, super.key});

  final RiderApiClient? apiClient;

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isForeground = true;
  bool _incomingDialogShowing = false;
  String? _presentedOfferToken;

  late final _availabilityStore = AvailabilityStore(
    initialStatus: widget.apiClient == null
        ? AvailabilityStatus.available
        : AvailabilityStatus.offline,
    apiClient: widget.apiClient,
  );
  late final _offerStore = OrderOfferStore(
    availabilityStore: _availabilityStore,
    activeDelivery: widget.apiClient == null
        ? HomeDemoData().activeDelivery
        : null,
    offer: widget.apiClient == null ? DemoDelivery.newOffer : null,
    apiClient: widget.apiClient,
  );
  late final _newOrderAlert = NewOrderAlert();
  late final _pages = [
    HomePage(availabilityStore: _availabilityStore, offerStore: _offerStore),
    OrdersPage(availabilityStore: _availabilityStore, offerStore: _offerStore),
    EarningsPage(offerStore: _offerStore),
    const GigsPage(),
    ProfilePage(availabilityStore: _availabilityStore),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _offerStore.addListener(_handleOfferStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
          Navigator.of(context, rootNavigator: true).maybePop();
        });
      }
      return;
    }

    if (!_isForeground) return;

    final orderId = _offerStore.offer?.orderId;
    if (orderId == null) return;
    final offerToken = '$orderId:${_offerStore.offerRevision}';
    _newOrderAlert.start(offerToken);
    if (_incomingDialogShowing || _presentedOfferToken == offerToken) return;

    _presentedOfferToken = offerToken;
    _incomingDialogShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showIncomingOffer(orderId, offerToken);
    });
  }

  Future<void> _showIncomingOffer(String orderId, String offerToken) async {
    if (!_offerStore.canShowOffer || _offerStore.offer?.orderId != orderId) {
      _incomingDialogShowing = false;
      _handleOfferStoreChanged();
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingOrderOfferDialog(offerStore: _offerStore),
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
              child: IndexedStack(index: _selectedIndex, children: _pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        animationDuration: const Duration(milliseconds: 200),
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
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
