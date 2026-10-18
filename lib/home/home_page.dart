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
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildAvailabilityCard(),
                      const SizedBox(height: 18),
                      _buildSafetyBanner(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.demoData.greeting,
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.demoData.riderName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Rider ID: ${widget.demoData.riderId}',
          style: AppTheme.secondaryTextStyle,
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
        Icon(
          isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          color: statusColor,
          size: 24,
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

    return Card(
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
    );
  }

  Widget _buildSafetyBanner() {
    final isCompact = _isCompactLayout(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0e9b52), Color(0xFF0b7d45)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
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
              onPressed: () {},
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

    return Card(
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

    return Card(
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

class _StatCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.brand, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
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
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.cardTitle,
                ),
                if (detail != null) Text(detail!, style: AppTheme.smallStatus),
              ],
            ),
          ],
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
