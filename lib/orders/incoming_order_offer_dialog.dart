import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models/demo_delivery.dart';
import '../core/state/order_offer_store.dart';
import '../core/theme/app_theme.dart';
import 'rider_map_view.dart';

const _offerSheetColor = Color(0xFFF1F7F2);
const _offerAccentColor = Color(0xFF176B45);

class IncomingOrderOfferDialog extends StatelessWidget {
  const IncomingOrderOfferDialog({
    required this.offerStore,
    required this.soundNeedsActivation,
    required this.onEnableSound,
    super.key,
  });

  final OrderOfferStore offerStore;
  final bool soundNeedsActivation;
  final VoidCallback onEnableSound;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: offerStore,
      builder: (context, child) {
        final delivery = offerStore.offer;
        if (delivery == null || !offerStore.canShowOffer) {
          return const SizedBox.shrink();
        }

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: PopScope<Object?>(
            canPop: false,
            child: Dialog.fullscreen(
              backgroundColor: _offerSheetColor,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final mapHeight = (constraints.maxHeight * 0.44)
                        .clamp(220.0, 370.0)
                        .toDouble();
                    return Column(
                      children: [
                        SizedBox(
                          height: mapHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _OfferMapPreview(delivery: delivery),
                              Positioned(
                                top: 14,
                                left: 16,
                                right: 16,
                                child: _OfferTimer(
                                  offerStore: offerStore,
                                  soundNeedsActivation: soundNeedsActivation,
                                  onEnableSound: onEnableSound,
                                ),
                              ),
                              Positioned(
                                top: 62,
                                left: 16,
                                right: 16,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value:
                                        (offerStore.secondsRemaining /
                                                offerStore
                                                    .offerDuration
                                                    .inSeconds)
                                            .clamp(0.0, 1.0),
                                    minHeight: 5,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.7,
                                    ),
                                    color: offerStore.secondsRemaining <= 5
                                        ? AppTheme.error
                                        : _offerAccentColor,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: 42,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        _offerSheetColor.withValues(alpha: 0),
                                        _offerSheetColor,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 16,
                                bottom: 12,
                                child: FilledButton.icon(
                                  key: const ValueKey(
                                    'incoming-order-open-pickup-map',
                                  ),
                                  onPressed: () => _openPickupInGoogleMaps(
                                    context,
                                    delivery,
                                  ),
                                  icon: const Icon(Icons.navigation_rounded),
                                  label: const Text(
                                    'Open Google Maps to Pickup',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _offerAccentColor,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: _offerSheetColor,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    clipBehavior: Clip.none,
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      0,
                                      18,
                                      8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: Transform.translate(
                                              offset: const Offset(0, -17),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _offerSheetColor,
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  border: Border.all(
                                                    color: _offerAccentColor,
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color(0x26000000),
                                                      blurRadius: 10,
                                                      offset: Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: const Text(
                                                  'New order!',
                                                  style: TextStyle(
                                                    color: _offerAccentColor,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        if (delivery.isLocationDemo) ...[
                                          Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 11,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE2F1E7),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _offerAccentColor
                                                      .withValues(alpha: 0.16),
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.my_location_rounded,
                                                    size: 14,
                                                    color: _offerAccentColor,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      'DEMO · YOUR CURRENT LOCATION',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color:
                                                            _offerAccentColor,
                                                        fontSize: 10,
                                                        letterSpacing: 0.45,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        const Text(
                                          'Expected earnings',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppTheme.primaryText,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '₹${delivery.calculatedPayout}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: AppTheme.primaryText,
                                            fontSize: 36,
                                            height: 1.05,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pickup: ${_formatDistance(delivery.pickupDistanceKm)}'
                                          '  |  Drop: ${_formatDistance(delivery.hasRouteEstimate ? delivery.effectiveDeliveryDistance : null)}',
                                          textAlign: TextAlign.center,
                                          style: AppTheme.secondaryTextStyle,
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(13),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: _offerAccentColor
                                                  .withValues(alpha: 0.16),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  _PlaceTag(
                                                    label: 'PICK UP',
                                                    color: _offerAccentColor,
                                                  ),
                                                  const Spacer(),
                                                  Icon(
                                                    Icons.near_me_rounded,
                                                    size: 15,
                                                    color: _offerAccentColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${_formatDistance(delivery.pickupDistanceKm)} away',
                                                    style: AppTheme.smallStatus
                                                        .copyWith(
                                                          color:
                                                              _offerAccentColor,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                delivery.store,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.cardTitle
                                                    .copyWith(fontSize: 17),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                delivery.pickup,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    AppTheme.secondaryTextStyle,
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 9,
                                                ),
                                                child: Divider(height: 1),
                                              ),
                                              _PlaceTag(
                                                label: 'DROP OFF',
                                                color: AppTheme.darkGreen,
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '${delivery.customer} · ${delivery.drop}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme
                                                    .secondaryTextStyle
                                                    .copyWith(
                                                      color:
                                                          AppTheme.primaryText,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          delivery.orderId,
                                          textAlign: TextAlign.center,
                                          style: AppTheme.smallStatus,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    6,
                                    16,
                                    14,
                                  ),
                                  child: _OfferSwipeAction(
                                    key: const ValueKey(
                                      'incoming-order-accept',
                                    ),
                                    enabled: offerStore.canAccept,
                                    onAccept: () => _accept(context),
                                    onReject: () => _reject(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _accept(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final accepted = await offerStore.acceptAvailableOffer();
    if (!context.mounted) return accepted;
    if (accepted) {
      navigator.pop(true);
    } else if (offerStore.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(offerStore.errorMessage!)));
    }
    return accepted;
  }

  bool _reject(BuildContext context) {
    if (!offerStore.rejectOffer()) return false;
    Navigator.of(context).pop(false);
    return true;
  }

  Future<void> _openPickupInGoogleMaps(
    BuildContext context,
    DemoDelivery delivery,
  ) async {
    final destination =
        delivery.pickupLatitude != null && delivery.pickupLongitude != null
        ? '${delivery.pickupLatitude},${delivery.pickupLongitude}'
        : delivery.pickup;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    });

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('No application can open this link.');
      }
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Google Maps.')),
      );
    }
  }
}

class _OfferMapPreview extends StatelessWidget {
  const _OfferMapPreview({required this.delivery});

  final DemoDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final pickup = _coordinate(
      delivery.pickupLatitude,
      delivery.pickupLongitude,
    );
    final dropoff = _coordinate(delivery.dropLatitude, delivery.dropLongitude);
    if (pickup == null && dropoff == null) {
      return const ColoredBox(
        color: AppTheme.lightGreenSurface,
        child: Center(
          child: Icon(Icons.map_outlined, size: 68, color: AppTheme.brand),
        ),
      );
    }

    return RiderMapView(
      pickupLocation: pickup,
      dropoffLocation: delivery.isLocationDemo ? null : dropoff,
      initialLocation: pickup ?? dropoff,
      showCurrentLocation: false,
      height: 340,
    );
  }

  LatLng? _coordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }
}

class _OfferTimer extends StatelessWidget {
  const _OfferTimer({
    required this.offerStore,
    required this.soundNeedsActivation,
    required this.onEnableSound,
  });

  final OrderOfferStore offerStore;
  final bool soundNeedsActivation;
  final VoidCallback onEnableSound;

  @override
  Widget build(BuildContext context) {
    final urgent = offerStore.secondsRemaining <= 5;
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          'New order. ${offerStore.secondsRemaining} seconds remaining to accept or reject.',
      child: Row(
        children: [
          if (soundNeedsActivation)
            TextButton.icon(
              onPressed: onEnableSound,
              icon: const Icon(Icons.volume_up_rounded, size: 17),
              label: const Text('Enable sound'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.darkGreen,
                backgroundColor: AppTheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 38),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: urgent ? AppTheme.error : AppTheme.darkGreen,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 17),
                const SizedBox(width: 5),
                Text(
                  '${offerStore.secondsRemaining}s',
                  key: const ValueKey('offer-countdown'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceTag extends StatelessWidget {
  const _PlaceTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _OfferSwipeAction extends StatefulWidget {
  const _OfferSwipeAction({
    required this.enabled,
    required this.onAccept,
    required this.onReject,
    super.key,
  });

  final bool enabled;
  final Future<bool> Function() onAccept;
  final bool Function() onReject;

  @override
  State<_OfferSwipeAction> createState() => _OfferSwipeActionState();
}

class _OfferSwipeActionState extends State<_OfferSwipeAction> {
  double _progress = 0;
  bool _isCompleting = false;
  double? _dragStartX;

  Future<void> _complete() async {
    if (_isCompleting || !widget.enabled) return;
    if (_progress.abs() < 0.65) {
      setState(() => _progress = 0);
      return;
    }

    setState(() => _isCompleting = true);
    final completed = _progress > 0
        ? await widget.onAccept()
        : widget.onReject();
    if (!mounted || completed) return;
    setState(() {
      _progress = 0;
      _isCompleting = false;
    });
  }

  Future<void> _activateAccessibly() async {
    if (_isCompleting || !widget.enabled) return;
    setState(() => _progress = 1);
    await _complete();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: widget.enabled,
    label: 'Swipe right to accept or left to reject this order',
    onTap: widget.enabled ? _activateAccessibly : null,
    child: LayoutBuilder(
      builder: (context, constraints) {
        const thumbSize = 54.0;
        const inset = 6.0;
        final travel = (constraints.maxWidth - thumbSize - inset * 2).clamp(
          1.0,
          double.infinity,
        );
        final halfTravel = travel / 2;
        final offset = inset + halfTravel * (1 + _progress);

        return GestureDetector(
          key: const ValueKey('incoming-order-accept-track'),
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _activateAccessibly : null,
          onHorizontalDragStart: widget.enabled
              ? (details) => _dragStartX = details.localPosition.dx
              : null,
          onHorizontalDragUpdate: widget.enabled
              ? (details) {
                  final start = _dragStartX;
                  if (start == null || _isCompleting) return;
                  setState(() {
                    _progress =
                        ((details.localPosition.dx - start) / halfTravel).clamp(
                          -1.0,
                          1.0,
                        );
                  });
                }
              : null,
          onHorizontalDragEnd: widget.enabled ? (_) => _complete() : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _progress < -0.2
                    ? const [Color(0xFFD82B46), Color(0xFFB42318)]
                    : const [Color(0xFF21B653), Color(0xFF07943A)],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: widget.enabled
                    ? const Color(0xFF087D35)
                    : AppTheme.divider,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x302E7D32),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _progress < -0.2
                            ? 'Release to reject'
                            : _progress > 0.2
                            ? 'Release to accept'
                            : 'Accept order',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (_progress.abs() <= 0.2) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'Swipe right to accept · left to reject',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xE6FFFFFF),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOut,
                  left: offset,
                  top: inset,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? const Color(0xFFFFDDF0)
                          : AppTheme.divider,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.darkGreen.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: AnimatedScale(
                      scale: 1 + _progress.abs() * 0.12,
                      duration: const Duration(milliseconds: 120),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.002)
                          ..rotateY(_progress * 0.32),
                        child: Icon(
                          _progress < -0.2
                              ? Icons.keyboard_double_arrow_left_rounded
                              : Icons.keyboard_double_arrow_right_rounded,
                          color: _offerAccentColor,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

String _formatDistance(double? distance) =>
    distance == null ? '—' : '${distance.toStringAsFixed(1)} km';
