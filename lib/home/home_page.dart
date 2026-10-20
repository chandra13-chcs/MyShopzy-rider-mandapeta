import 'dart:async';

import 'package:flutter/material.dart';

import '../core/state/availability_store.dart';
import '../core/state/order_offer_store.dart';
import '../core/models/demo_delivery.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/section_title.dart';
import '../core/widgets/status_badge.dart';
import '../delivery/delivery_page.dart';
import 'home_demo_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.availabilityStore,
    required this.offerStore,
    this.demoData = const HomeDemoData(),
    super.key,
  });

  final AvailabilityStore availabilityStore;
  final OrderOfferStore offerStore;
  final HomeDemoData demoData;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _openDeliveryPage(DemoDelivery delivery) async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            DeliveryPage(delivery: delivery, offerStore: widget.offerStore),
      ),
    );
    if (!mounted) return;
    if (completed == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Delivery marked complete')));
    }
  }

  bool _isCompactLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 340;

  Future<void> _showSafetyChecklist() {
    final checkedItems = [false, false, false];
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isReady = checkedItems.every((checked) => checked);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick safety check', style: AppTheme.screenTitle),
                  const SizedBox(height: 6),
                  Text(
                    'Take a moment before starting your ride.',
                    style: AppTheme.secondaryTextStyle,
                  ),
                  const SizedBox(height: 18),
                  _SafetyCheckItem(
                    icon: Icons.sports_motorsports_rounded,
                    title: 'Wear and fasten your helmet',
                    checked: checkedItems[0],
                    onChanged: (checked) =>
                        setSheetState(() => checkedItems[0] = checked ?? false),
                  ),
                  _SafetyCheckItem(
                    icon: Icons.tire_repair_rounded,
                    title: 'Check your brakes and tires',
                    checked: checkedItems[1],
                    onChanged: (checked) =>
                        setSheetState(() => checkedItems[1] = checked ?? false),
                  ),
                  _SafetyCheckItem(
                    icon: Icons.phone_android_rounded,
                    title: 'Secure your phone before moving',
                    checked: checkedItems[2],
                    onChanged: (checked) =>
                        setSheetState(() => checkedItems[2] = checked ?? false),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isReady
                          ? () => Navigator.of(context).pop()
                          : null,
                      child: const Text('Ready to ride safely'),
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

  @override
  Widget build(BuildContext context) {
    final isCompact = _isCompactLayout(context);

    return AnimatedBuilder(
      animation: widget.availabilityStore,
      builder: (context, _) => AnimatedBuilder(
        animation: widget.offerStore,
        builder: (context, _) {
          final delivery = widget.offerStore.activeDelivery;
          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 14 : 20,
                    16,
                    isCompact ? 14 : 20,
                    28,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _PremiumEntrance(child: _buildHeader()),
                      const SizedBox(height: 20),
                      _PremiumEntrance(
                        delay: const Duration(milliseconds: 55),
                        child: _buildAvailabilityCard(),
                      ),
                      const SizedBox(height: 18),
                      _PremiumEntrance(
                        delay: const Duration(milliseconds: 110),
                        child: _buildSafetyBanner(),
                      ),
                      const SizedBox(height: 22),
                      SectionTitle(title: "Today's summary"),
                      const SizedBox(height: 10),
                      _buildDailySummary(),
                      const SizedBox(height: 22),
                      if (delivery case final activeDelivery?) ...[
                        SectionTitle(title: 'Current Delivery'),
                        const SizedBox(height: 10),
                        _buildActiveDelivery(activeDelivery),
                      ] else if (widget.offerStore.canShowOffer) ...[
                        const SectionTitle(title: 'New Order'),
                        const SizedBox(height: 10),
                        _buildNewOrder(),
                      ] else
                        _buildWaitingState(),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.demoData.greeting,
                style: const TextStyle(
                  color: AppTheme.brand,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.demoData.riderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 25,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.brand.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  'Rider ID: ${widget.demoData.riderId}',
                  style: AppTheme.smallStatus.copyWith(
                    color: AppTheme.darkGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A8A5B), AppTheme.darkGreen],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.darkGreen.withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.delivery_dining_rounded,
            color: Colors.white,
            size: 31,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCard() {
    final isAvailable = widget.availabilityStore.isAvailable;
    final isConnected = widget.availabilityStore.isConnected;
    final isBusy = widget.offerStore.isBusy;
    final isOnline = isAvailable && isConnected;
    final lastError = widget.availabilityStore.lastError;
    final statusColor = isOnline ? AppTheme.success : AppTheme.error;
    final isCompact = _isCompactLayout(context);

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: statusColor,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                !isAvailable
                    ? "You're offline"
                    : isConnected
                    ? "You're online"
                    : 'Connection lost',
                style: AppTheme.cardTitle.copyWith(color: statusColor),
              ),
              const SizedBox(height: 3),
              Text(
                !isAvailable
                    ? "You're not available for new delivery offers."
                    : !isConnected
                    ? "You're on duty, but new offers are paused until you're reconnected."
                    : isBusy
                    ? "You're currently delivering; new offers are paused."
                    : "You're ready to receive delivery offers.",
                style: AppTheme.secondaryTextStyle,
              ),
              if (isConnected && lastError != null) ...[
                const SizedBox(height: 4),
                Text(
                  lastError,
                  style: AppTheme.secondaryTextStyle.copyWith(
                    color: AppTheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return _PremiumTilt(
      child: Card(
        color: isOnline ? AppTheme.onlineBox : AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Switch.adaptive(
                        value: isAvailable,
                        activeTrackColor: AppTheme.success,
                        onChanged: widget.availabilityStore.setAvailable,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: content),
                    Switch.adaptive(
                      value: isAvailable,
                      activeTrackColor: AppTheme.success,
                      onChanged: widget.availabilityStore.setAvailable,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSafetyBanner() {
    final isCompact = _isCompactLayout(context);

    return _PremiumTilt(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF18A45F), Color(0xFF0B7043), Color(0xFF075332)],
            stops: [0, 0.56, 1],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B7D45).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 18 : 24,
          vertical: isCompact ? 18 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety First.\nEvery Ride.',
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 28 : 42,
                height: 0.95,
                fontWeight: FontWeight.w800,
                shadows: const [
                  Shadow(
                    color: Color(0x55000000),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Wear your helmet.\nDeliver safely.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.96),
                fontSize: isCompact ? 18 : 24,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _showSafetyChecklist,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.brandYellow,
                  foregroundColor: AppTheme.darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: TextStyle(
                    fontSize: isCompact ? 18 : 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Start Delivering Safely'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummary() {
    final data = widget.demoData;
    final settlementMinor = widget.offerStore.todaySettlementMinor;
    final completedToday = widget.offerStore.todayCompletedDeliveries;
    final isLiveApi = widget.offerStore.apiClient != null;
    final earnings = settlementMinor == null && !isLiveApi
        ? '₹${data.todayEarnings}'
        : '₹${((settlementMinor ?? 0) / 100).toStringAsFixed(2)}';
    final isCompact = _isCompactLayout(context);

    final cards = [
      _StatCard(
        icon: Icons.check_circle_outline_rounded,
        label: 'Deliveries',
        value:
            '${completedToday ?? (isLiveApi ? 0 : data.deliveriesCompleted)}',
        detail: 'completed',
      ),
      _StatCard(
        icon: Icons.payments_outlined,
        label: "Today's earnings",
        value: earnings,
      ),
    ];

    final distanceCards = [
      _StatCard(
        icon: Icons.route_outlined,
        label: 'Distance',
        value: '${data.distanceKm.toStringAsFixed(1)} km',
      ),
      _StatCard(
        icon: Icons.schedule_outlined,
        label: 'Online time',
        value: data.onlineTime,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          ...cards.map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: card,
            ),
          ),
          ...distanceCards.map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: card,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: 10),
            Expanded(child: cards.last),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: distanceCards.first),
            const SizedBox(width: 10),
            Expanded(child: distanceCards.last),
          ],
        ),
      ],
    );
  }

  Widget _buildNewOrder() {
    final offer = widget.offerStore.offer;
    if (offer == null) return const SizedBox.shrink();
    final isCompact = _isCompactLayout(context);

    return _PremiumTilt(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('New order offer', style: AppTheme.cardTitle),
                  ),
                  StatusBadge(
                    label: '${widget.offerStore.secondsRemaining}s',
                    color: AppTheme.brand,
                    backgroundColor: AppTheme.brandSoft,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(offer.orderId, style: AppTheme.bodyText),
              const SizedBox(height: 10),
              ...[
                _OfferSummaryRow(label: 'Store', value: offer.store),
                _OfferSummaryRow(label: 'Pickup', value: offer.pickup),
                _OfferSummaryRow(
                  label: 'Pickup distance',
                  value: offer.pickupDistanceLabel,
                ),
                _OfferSummaryRow(label: 'Drop', value: offer.drop),
                _OfferSummaryRow(
                  label: 'Delivery distance',
                  value: offer.deliveryDistanceLabel,
                ),
                _OfferSummaryRow(
                  label: 'Total distance',
                  value: offer.totalDistanceLabel,
                ),
                _OfferSummaryRow(
                  label: 'Payout breakdown',
                  value: offer.payoutBreakdown,
                ),
                _OfferSummaryRow(
                  label: 'Estimated payout',
                  value: '₹${offer.calculatedPayout}',
                ),
                _OfferSummaryRow(label: 'Vehicle', value: offer.vehicle),
              ],
              const SizedBox(height: 14),
              if (isCompact)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.offerStore.canAccept
                            ? () => widget.offerStore.rejectOffer()
                            : null,
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.offerStore.canAccept
                            ? () => _acceptOffer(offer)
                            : null,
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.offerStore.canAccept
                            ? () => widget.offerStore.rejectOffer()
                            : null,
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: widget.offerStore.canAccept
                            ? () => _acceptOffer(offer)
                            : null,
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptOffer(DemoDelivery delivery) async {
    final accepted = await widget.offerStore.acceptAvailableOffer();
    if (!mounted) return;
    if (!accepted) {
      final message =
          widget.offerStore.errorMessage ??
          'This order is no longer available.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    await _openDeliveryPage(delivery);
  }

  Widget _buildActiveDelivery(DemoDelivery delivery) {
    final isCompact = _isCompactLayout(context);

    return _PremiumTilt(
      child: Card(
        color: AppTheme.currentDeliveryCard,
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      delivery.orderId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.cardTitle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: widget.offerStore.activeDeliveryStatus,
                    color: AppTheme.brand,
                    backgroundColor: AppTheme.brandSoft,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openDeliveryPage(delivery),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continue Delivery'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.darkGreen,
                    foregroundColor: AppTheme.surface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingState() {
    final isAvailable = widget.availabilityStore.isAvailable;
    final message = widget.offerStore.errorMessage;
    return Card(
      child: ListTile(
        leading: Icon(
          isAvailable ? Icons.hourglass_empty_rounded : Icons.wifi_off_rounded,
          color: isAvailable ? AppTheme.brand : AppTheme.secondaryText,
        ),
        title: Text(
          isAvailable ? 'Waiting for new orders' : "You're offline",
          style: AppTheme.cardTitle,
        ),
        subtitle: Text(
          message ??
              (widget.offerStore.isLoadingOffers
                  ? 'Checking for available orders...'
                  : isAvailable
                  ? 'A new order will appear here.'
                  : 'Go online to receive new orders.'),
          style: AppTheme.secondaryTextStyle.copyWith(
            color: message == null ? null : AppTheme.error,
          ),
        ),
      ),
    );
  }
}

class _PremiumEntrance extends StatefulWidget {
  const _PremiumEntrance({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_PremiumEntrance> createState() => _PremiumEntranceState();
}

class _PremiumEntranceState extends State<_PremiumEntrance> {
  Timer? _delayTimer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _ready = true;
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    if (!_ready) return widget.child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: widget.child,
      builder: (context, progress, child) {
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translateByDouble(0.0, 10 * (1 - progress), 0.0, 1.0)
          ..rotateX(0.018 * (1 - progress))
          ..scaleByDouble(
            0.985 + (0.015 * progress),
            0.985 + (0.015 * progress),
            0.985 + (0.015 * progress),
            1.0,
          );
        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: child,
        );
      },
    );
  }
}

class _PremiumTilt extends StatefulWidget {
  const _PremiumTilt({required this.child});

  final Widget child;

  @override
  State<_PremiumTilt> createState() => _PremiumTiltState();
}

class _PremiumTiltState extends State<_PremiumTilt> {
  double _tiltX = 0;
  double _tiltY = 0;
  bool _isHovered = false;

  void _setTilt(PointerEvent event) {
    final size = context.size;
    if (size == null) return;
    setState(() {
      _isHovered = true;
      _tiltX = ((event.localPosition.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
      _tiltY = ((event.localPosition.dy / size.height) * 2 - 1).clamp(
        -1.0,
        1.0,
      );
    });
  }

  void _resetTilt(PointerEvent event) {
    setState(() {
      _isHovered = false;
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(_tiltY * 0.018)
      ..rotateY(-_tiltX * 0.018)
      ..scaleByDouble(
        _isHovered ? 1.012 : 1.0,
        _isHovered ? 1.012 : 1.0,
        _isHovered ? 1.012 : 1.0,
        1.0,
      );
    return MouseRegion(
      onHover: _setTilt,
      onExit: _resetTilt,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: transform,
        child: widget.child,
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  double _tiltX = 0;
  double _tiltY = 0;

  void _setTilt(PointerEvent event) {
    final size = context.size;
    if (size == null) return;
    setState(() {
      _tiltX = ((event.localPosition.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
      _tiltY = ((event.localPosition.dy / size.height) * 2 - 1).clamp(
        -1.0,
        1.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final motionDisabled = MediaQuery.disableAnimationsOf(context);
    final tiltX = motionDisabled ? 0.0 : _tiltX;
    final tiltY = motionDisabled ? 0.0 : _tiltY;
    final isHovered = !motionDisabled && (_tiltX != 0 || _tiltY != 0);
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(tiltY * 0.025)
      ..rotateY(-tiltX * 0.025)
      ..scaleByDouble(
        isHovered ? 1.015 : 1.0,
        isHovered ? 1.015 : 1.0,
        isHovered ? 1.015 : 1.0,
        1.0,
      );
    return MouseRegion(
      onHover: _setTilt,
      onExit: (_) => setState(() {
        _tiltX = 0;
        _tiltY = 0;
      }),
      child: AnimatedContainer(
        duration: motionDisabled
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: transform,
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: AppTheme.brand, size: 18),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.smallStatus,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 5,
                  children: [
                    Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.cardTitle,
                    ),
                    if (widget.detail != null)
                      Text(widget.detail!, style: AppTheme.smallStatus),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferSummaryRow extends StatelessWidget {
  const _OfferSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTheme.secondaryTextStyle),
                    const SizedBox(height: 2),
                    Text(value, style: AppTheme.bodyText),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 124,
                      child: Text(label, style: AppTheme.secondaryTextStyle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(value, style: AppTheme.bodyText)),
                  ],
                ),
        );
      },
    );
  }
}

class _SafetyCheckItem extends StatelessWidget {
  const _SafetyCheckItem({
    required this.icon,
    required this.title,
    required this.checked,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.lightGreenSurface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppTheme.brand, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Checkbox(value: checked, onChanged: onChanged),
        ],
      ),
    );
  }
}
