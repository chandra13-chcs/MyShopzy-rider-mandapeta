import 'dart:async';

import 'package:flutter/material.dart';

import '../core/state/availability_store.dart';
import '../core/state/new_order_alert.dart';
import '../core/state/order_offer_store.dart';
import '../delivery/delivery_page.dart';
import '../earnings/earnings_page.dart';
import '../gigs/gigs_page.dart';
import '../home/home_demo_data.dart';
import '../home/home_page.dart';
import '../orders/incoming_order_offer_dialog.dart';
import '../orders/orders_page.dart';
import '../profile/profile_page.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({super.key});

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isForeground = true;
  bool _incomingDialogShowing = false;
  String? _presentedOfferId;

  late final _availabilityStore = AvailabilityStore();
  late final _offerStore = OrderOfferStore(
    availabilityStore: _availabilityStore,
    activeDelivery: HomeDemoData().activeDelivery,
  );
  late final _newOrderAlert = NewOrderAlert();
  late final _pages = [
    HomePage(availabilityStore: _availabilityStore, offerStore: _offerStore),
    OrdersPage(availabilityStore: _availabilityStore, offerStore: _offerStore),
    const EarningsPage(),
    const GigsPage(),
    ProfilePage(availabilityStore: _availabilityStore),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _offerStore.addListener(_handleOfferStoreChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleOfferStoreChanged();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      _handleOfferStoreChanged();
    } else {
      unawaited(_newOrderAlert.stop());
    }
  }

  void _handleOfferStoreChanged() {
    if (!_offerStore.canShowOffer) {
      unawaited(_newOrderAlert.stop());
      if (_offerStore.status != OrderOfferStatus.available) {
        _presentedOfferId = null;
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

    final orderId = _offerStore.offer.orderId;
    _newOrderAlert.start(orderId);
    if (_incomingDialogShowing || _presentedOfferId == orderId) return;

    _presentedOfferId = orderId;
    _incomingDialogShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showIncomingOffer(orderId);
    });
  }

  Future<void> _showIncomingOffer(String orderId) async {
    if (!_offerStore.canShowOffer || _offerStore.offer.orderId != orderId) {
      _incomingDialogShowing = false;
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingOrderOfferDialog(offerStore: _offerStore),
    );
    _incomingDialogShowing = false;

    if (!mounted || accepted != true) return;
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
      body: IndexedStack(index: _selectedIndex, children: _pages),
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
