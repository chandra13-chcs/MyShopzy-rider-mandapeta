import 'dart:async';

import 'package:flutter/material.dart';

import '../core/state/availability_store.dart';
import '../core/theme/app_theme.dart';
import 'gig_repository.dart';

class GigsPage extends StatefulWidget {
  const GigsPage({
    required this.availabilityStore,
    this.repository,
    this.clock,
    super.key,
  });

  final AvailabilityStore availabilityStore;
  final GigRepository? repository;
  final DateTime Function()? clock;

  @override
  State<GigsPage> createState() => _GigsPageState();
}

class _GigsPageState extends State<GigsPage> {
  static const List<GigSession> _sessions = [
    GigSession(id: 'morning', name: 'Morning', startHour: 7, endHour: 10),
    GigSession(
      id: 'late-morning',
      name: 'Late Morning',
      startHour: 10,
      endHour: 13,
    ),
    GigSession(id: 'afternoon', name: 'Afternoon', startHour: 13, endHour: 16),
    GigSession(id: 'evening', name: 'Evening', startHour: 16, endHour: 19),
    GigSession(id: 'night', name: 'Night', startHour: 19, endHour: 23),
  ];

  late final GigRepository _repository =
      widget.repository ?? DemoGigRepository();
  final List<GigBooking> _bookings = [];
  Map<String, GigAvailability> _availability = const {};
  final Set<String> _busySessionIds = {};
  int _selectedTab = 0;
  bool _isLoading = true;
  late bool _wasOnline;
  String? _loadError;
  DateTime get _now => (widget.clock?.call() ?? DateTime.now()).toLocal();
  DateTime get _today => DateTime(_now.year, _now.month, _now.day);
  bool get _isDemo => _repository.isDemo;

  @override
  void initState() {
    super.initState();
    _wasOnline = widget.availabilityStore.isOnline;
    widget.availabilityStore.addListener(_handleAvailabilityChanged);
    unawaited(_refreshBookings());
  }

  @override
  void dispose() {
    widget.availabilityStore.removeListener(_handleAvailabilityChanged);
    super.dispose();
  }

  void _handleAvailabilityChanged() {
    final isOnline = widget.availabilityStore.isOnline;
    final cameOnline = isOnline && !_wasOnline;
    _wasOnline = isOnline;
    if (mounted) setState(() {});
    if (cameOnline) unawaited(_refreshBookings());
  }

  Future<void> _refreshBookings() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await _repository.getGigData(_today);
      if (!mounted) return;
      setState(() {
        _bookings
          ..clear()
          ..addAll(
            data.bookings.where((booking) => _sameDate(booking.date, _today)),
          );
        _availability = data.availability;
        _isLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _errorMessage(error);
        _isLoading = false;
      });
    }
  }

  String _errorMessage(Object error) => error is GigRepositoryException
      ? error.message
      : 'Unable to load your gig bookings. Please try again.';

  bool _isBooked(GigSession session) => _bookings.any(
    (booking) =>
        booking.sessionId == session.id &&
        _sameDate(booking.date, _today) &&
        booking.status != GigBookingStatus.cancelled,
  );

  bool _canBook(GigSession session) {
    final endsAt = DateTime(
      _today.year,
      _today.month,
      _today.day,
      session.endHour,
    );
    return widget.availabilityStore.isOnline &&
        _loadError == null &&
        !_isBooked(session) &&
        !_busySessionIds.contains(session.id) &&
        (_availability[session.id]?.availableSlots ?? 1) > 0 &&
        _now.isBefore(endsAt);
  }

  Future<bool> _bookSession(GigSession session) async {
    if (!_canBook(session)) return false;
    setState(() {
      _busySessionIds.add(session.id);
    });
    try {
      final booking = await _repository.bookSession(session, _today);
      if (!mounted) return false;
      setState(() {
        _bookings.add(booking);
        _busySessionIds.remove(session.id);
      });
      unawaited(_refreshBookings());
      return true;
    } on Object {
      if (!mounted) return false;
      setState(() {
        _busySessionIds.remove(session.id);
      });
      rethrow;
    }
  }

  Future<void> _openSession(GigSession session) async {
    final booked = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => GigSessionDetailsPage(
          session: session,
          date: _today,
          availabilityStore: widget.availabilityStore,
          isBooked: () => _isBooked(session),
          canBook: () => _canBook(session),
          isFull: () => (_availability[session.id]?.availableSlots ?? 1) <= 0,
          isDemo: _isDemo,
          onBook: () => _bookSession(session),
          onGoOnline: () async {
            widget.availabilityStore.setAvailable(true);
            await _refreshBookings();
          },
          loadError: () => _loadError,
          clock: () => _now,
        ),
      ),
    );
    if (booked == true && mounted) setState(() => _selectedTab = 1);
  }

  Future<void> _cancelBooking(GigBooking booking) async {
    final session = _sessionFor(booking.sessionId);
    if (session == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _CancelSessionDialog(
        session: session,
        date: booking.date,
        cancel: () => _repository.cancelBooking(booking),
        errorMessage: _errorMessage,
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      final index = _bookings.indexWhere((item) => item.id == booking.id);
      if (index != -1) {
        _bookings[index] = booking.copyWith(status: GigBookingStatus.cancelled);
      }
    });
    unawaited(_refreshBookings());
    await _showOutcomeDialog(
      context,
      title: 'Session cancelled',
      message: '${session.name} has been cancelled successfully.',
      icon: Icons.check_circle_rounded,
    );
  }

  Future<void> _showOutcomeDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: _OutcomeContent(title: title, message: message, icon: icon),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return Scaffold(
      appBar: AppBar(title: const Text('Gigs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.calendar_month_rounded),
                  label: Text('Book a session'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.work_history_rounded),
                  label: Text('My Gigs'),
                ),
              ],
              selected: {_selectedTab},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _selectedTab = selection.first),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: duration,
              child: _selectedTab == 0
                  ? _buildSessions(context)
                  : _buildMyGigs(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessions(BuildContext context) {
    final isOnline = widget.availabilityStore.isOnline;
    final dateLabel = _formatDate(context, _today);
    return ListView(
      key: const ValueKey('available-sessions'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _PageIntro(
          title: "Today's gig sessions",
          subtitle: dateLabel,
          icon: Icons.calendar_today_rounded,
        ),
        if (_isDemo) ...[
          const SizedBox(height: 12),
          const _InfoBanner(
            icon: Icons.science_outlined,
            text: 'Demo mode: bookings are simulated in memory and are not saved to MyShopzy. Slot counts are not connected.',
          ),
        ],
        if (!isOnline) ...[
          const SizedBox(height: 12),
          _GoOnlineBanner(
            onGoOnline: () => widget.availabilityStore.setAvailable(true),
          ),
        ],
        if (_loadError != null) ...[
          const SizedBox(height: 12),
          _InfoBanner(
            icon: Icons.cloud_off_rounded,
            text: _loadError!,
            action: TextButton(
              onPressed: _refreshBookings,
              child: const Text('Retry'),
            ),
          ),
        ],
        const SizedBox(height: 18),
        for (var index = 0; index < _sessions.length; index++) ...[
          _buildSessionCard(context, _sessions[index], index),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    GigSession session,
    int index,
  ) {
    final isBooked = _isBooked(session);
    final isPast = !_now.isBefore(
      DateTime(_today.year, _today.month, _today.day, session.endHour),
    );
    final isOnline = widget.availabilityStore.isOnline;
    final availability = _availability[session.id];
    final isFull = availability != null && availability.availableSlots <= 0;
    final canBook = _canBook(session) && !isFull;
    final status = isBooked
        ? 'Booked'
        : isFull
        ? 'Full'
        : isPast
        ? 'Session ended'
        : !isOnline
        ? 'Go online to book'
        : _loadError != null
        ? 'Booking unavailable'
        : 'Open for booking';
    final color = isBooked
        ? AppTheme.brand
        : isFull || isPast
        ? AppTheme.secondaryText
        : const Color(0xFFE23744);

    return TweenAnimationBuilder<double>(
      key: ValueKey('session-card-${session.id}'),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Duration(milliseconds: 180 + index * 45),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openSession(session),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 290;
                final slots = availability != null
                    ? '${availability.availableSlots} / ${availability.totalSlots} slots'
                    : 'Slot counts unavailable';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_sessionIcon(session), color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(session.name, style: AppTheme.cardTitle),
                              const SizedBox(height: 3),
                              Text(
                                _timeRange(context, session),
                                style: AppTheme.secondaryTextStyle,
                              ),
                            ],
                          ),
                        ),
                        if (!compact) _StatusPill(label: status, color: color),
                      ],
                    ),
                    if (compact) ...[
                      const SizedBox(height: 10),
                      _StatusPill(label: status, color: color),
                    ],
                    const SizedBox(height: 14),
                    if (compact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(context, _today),
                            style: AppTheme.secondaryTextStyle,
                          ),
                          const SizedBox(height: 5),
                          Text(slots, style: AppTheme.smallStatus),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 17,
                            color: AppTheme.secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatDate(context, _today),
                              style: AppTheme.secondaryTextStyle,
                            ),
                          ),
                          Text(slots, style: AppTheme.smallStatus),
                        ],
                      ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: ValueKey('gig-book-${_sessions.indexOf(session)}'),
                        onPressed: canBook ? () => _openSession(session) : null,
                        child: Text(
                          isBooked
                              ? 'Booked'
                              : isFull || isPast
                              ? (isFull ? 'Session full' : 'Session ended')
                              : _loadError != null
                              ? 'Unavailable'
                              : !isOnline
                              ? 'Go online to book'
                              : 'Book Session',
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
  }

  Widget _buildMyGigs(BuildContext context) {
    final active = _bookings.where(
      (booking) =>
          booking.status == GigBookingStatus.booked &&
          !_isSessionEnded(booking),
    );
    final completed = _bookings.where(
      (booking) =>
          booking.status == GigBookingStatus.booked && _isSessionEnded(booking),
    );
    final cancelled = _bookings.where(
      (booking) => booking.status == GigBookingStatus.cancelled,
    );
    final upcoming = _sessions.where((session) {
      final startsAt = DateTime(
        _today.year,
        _today.month,
        _today.day,
        session.startHour,
      );
      return startsAt.isAfter(_now) &&
          !_isBooked(session) &&
          (_availability[session.id]?.availableSlots != 0);
    });
    final dateLabel = _formatDate(context, _today);

    return ListView(
      key: const ValueKey('my-gigs'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _PageIntro(
          title: 'My Gigs',
          subtitle: 'Today · $dateLabel',
          icon: Icons.work_history_rounded,
        ),
        if (_isDemo) ...[
          const SizedBox(height: 12),
          const _InfoBanner(
            icon: Icons.science_outlined,
            text: 'Demo bookings only stay in memory for this app session. They are not production reservations.',
          ),
        ],
        const SizedBox(height: 18),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          _bookingSection(
            context,
            title: "Today's bookings",
            bookings: active,
            emptyMessage: 'You have no booked sessions today.',
            showCancel: true,
          ),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upcoming sessions today', style: AppTheme.sectionTitle),
              const SizedBox(height: 10),
              if (upcoming.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No unbooked sessions are upcoming today.',
                      style: AppTheme.secondaryTextStyle,
                    ),
                  ),
                )
              else
                for (var index = 0; index < upcoming.length; index++) ...[
                  _buildSessionCard(context, upcoming.elementAt(index), index),
                  const SizedBox(height: 10),
                ],
            ],
          ),
          const SizedBox(height: 18),
          _bookingSection(
            context,
            title: 'Completed sessions',
            bookings: completed,
            emptyMessage: 'Completed sessions will appear here.',
          ),
          const SizedBox(height: 18),
          _bookingSection(
            context,
            title: 'Cancelled sessions',
            bookings: cancelled,
            emptyMessage: 'Cancelled sessions will appear here.',
          ),
          if (_bookings.isEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _selectedTab = 0),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Browse today’s sessions'),
              ),
            ),
          ],
        ],
        if (_loadError != null && !_isLoading) ...[
          const SizedBox(height: 16),
          _InfoBanner(
            icon: Icons.cloud_off_rounded,
            text: _loadError!,
            action: TextButton(
              onPressed: _refreshBookings,
              child: const Text('Retry'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _bookingSection(
    BuildContext context, {
    required String title,
    required Iterable<GigBooking> bookings,
    required String emptyMessage,
    bool showCancel = false,
  }) {
    final items = bookings.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.sectionTitle),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_busy_rounded,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      emptyMessage,
                      style: AppTheme.secondaryTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final booking in items) ...[
            _bookingCard(context, booking, showCancel: showCancel),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _bookingCard(
    BuildContext context,
    GigBooking booking, {
    required bool showCancel,
  }) {
    final session = _sessionFor(booking.sessionId);
    if (session == null) return const SizedBox.shrink();
    final status = booking.status == GigBookingStatus.cancelled
        ? 'Cancelled'
        : _isSessionEnded(booking)
        ? 'Completed'
        : _isSessionInProgress(booking)
        ? 'In Progress'
        : 'Booked';
    final statusColor = status == 'Cancelled'
        ? AppTheme.error
        : status == 'Completed' || status == 'In Progress'
        ? AppTheme.brand
        : const Color(0xFFE23744);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(session.name, style: AppTheme.cardTitle)),
                _StatusPill(label: status, color: statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_timeRange(context, session)} · ${_formatDate(context, booking.date)}',
              style: AppTheme.secondaryTextStyle,
            ),
            if (showCancel &&
                booking.status == GigBookingStatus.booked &&
                !_isSessionEnded(booking)) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _cancelBooking(booking),
                  child: const Text('Cancel Session'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSessionEnded(GigBooking booking) {
    final session = _sessionFor(booking.sessionId);
    if (session == null) return false;
    return !_now.isBefore(
      DateTime(
        booking.date.year,
        booking.date.month,
        booking.date.day,
        session.endHour,
      ),
    );
  }

  bool _isSessionInProgress(GigBooking booking) {
    final session = _sessionFor(booking.sessionId);
    if (session == null) return false;
    final startsAt = DateTime(
      booking.date.year,
      booking.date.month,
      booking.date.day,
      session.startHour,
    );
    return !_now.isBefore(startsAt) && !_isSessionEnded(booking);
  }

  GigSession? _sessionFor(String id) {
    for (final session in _sessions) {
      if (session.id == id) return session;
    }
    return null;
  }
}

class GigSessionDetailsPage extends StatefulWidget {
  const GigSessionDetailsPage({
    required this.session,
    required this.date,
    required this.availabilityStore,
    required this.isBooked,
    required this.canBook,
    required this.isFull,
    required this.isDemo,
    required this.onBook,
    required this.onGoOnline,
    required this.loadError,
    required this.clock,
    super.key,
  });

  final GigSession session;
  final DateTime date;
  final AvailabilityStore availabilityStore;
  final bool Function() isBooked;
  final bool Function() canBook;
  final bool Function() isFull;
  final bool isDemo;
  final Future<bool> Function() onBook;
  final Future<void> Function() onGoOnline;
  final String? Function() loadError;
  final DateTime Function() clock;

  @override
  State<GigSessionDetailsPage> createState() => _GigSessionDetailsPageState();
}

class _GigSessionDetailsPageState extends State<GigSessionDetailsPage> {
  bool _isSubmitting = false;
  String? _error;

  Future<void> _goOnline() async {
    await widget.onGoOnline();
    if (!mounted) return;
    setState(() => _error = widget.loadError());
  }

  Future<void> _book() async {
    if (_isSubmitting || !widget.canBook()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final succeeded = await widget.onBook();
      if (!mounted) return;
      if (!succeeded) {
        setState(() {
          _isSubmitting = false;
          _error = "You're offline or this session is no longer available.";
        });
        return;
      }
      setState(() => _isSubmitting = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: _OutcomeContent(
            title: 'Gig Session Booked!',
            message: widget.isDemo
                ? 'This demo booking stays in memory and is not confirmed by MyShopzy.'
                : 'Your session is booked for today.',
            icon: Icons.check_circle_rounded,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('View My Gigs'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error is GigRepositoryException
            ? error.message
            : 'Booking failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.availabilityStore,
    builder: (context, _) => _buildDetails(context),
  );

  Widget _buildDetails(BuildContext context) {
    final endsAt = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      widget.session.endHour,
    );
    final isPast = !widget.clock().isBefore(endsAt);
    final error = _error ?? widget.loadError();
    return Scaffold(
      appBar: AppBar(title: const Text('Session details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.delivery_dining_rounded,
                    color: Color(0xFFE23744),
                    size: 34,
                  ),
                  const SizedBox(height: 14),
                  Text(widget.session.name, style: AppTheme.greetingTitle),
                  const SizedBox(height: 6),
                  Text(
                    _timeRange(context, widget.session),
                    style: AppTheme.secondaryTextStyle,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: _formatDate(context, widget.date),
                  ),
                  const SizedBox(height: 12),
                  const _DetailRow(
                    icon: Icons.rule_rounded,
                    label: 'Booking is subject to available session capacity.',
                  ),
                  const SizedBox(height: 12),
                  const _DetailRow(
                    icon: Icons.power_settings_new_rounded,
                    label: 'You must be online when booking.',
                  ),
                  const SizedBox(height: 12),
                  const _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'You can book this session while it is in progress; ended sessions cannot be booked.',
                  ),
                  if (widget.isDemo) ...[
                    const SizedBox(height: 14),
                    const _InfoBanner(
                      icon: Icons.science_outlined,
                      text: 'Demo only: this action is simulated and is not a confirmed production reservation.',
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            _InfoBanner(icon: Icons.error_outline_rounded, text: error),
          ],
          const SizedBox(height: 16),
          if (!widget.availabilityStore.isOnline)
            FilledButton.icon(
              onPressed: _goOnline,
              icon: const Icon(Icons.power_settings_new_rounded),
              label: const Text('Go Online'),
            )
          else if (widget.isBooked())
            const FilledButton(onPressed: null, child: Text('Already Booked'))
          else if (isPast)
            const FilledButton(onPressed: null, child: Text('Session Ended'))
          else if (widget.isFull())
            const FilledButton(onPressed: null, child: Text('Session Full'))
          else
            FilledButton(
              onPressed: widget.canBook() && !_isSubmitting ? _book : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Book Session'),
            ),
        ],
      ),
    );
  }
}

class _CancelSessionDialog extends StatefulWidget {
  const _CancelSessionDialog({
    required this.session,
    required this.date,
    required this.cancel,
    required this.errorMessage,
  });

  final GigSession session;
  final DateTime date;
  final Future<void> Function() cancel;
  final String Function(Object error) errorMessage;

  @override
  State<_CancelSessionDialog> createState() => _CancelSessionDialogState();
}

class _CancelSessionDialogState extends State<_CancelSessionDialog> {
  bool _isCancelling = false;
  String? _error;

  Future<void> _confirm() async {
    if (_isCancelling) return;
    setState(() {
      _isCancelling = true;
      _error = null;
    });
    try {
      await widget.cancel();
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isCancelling = false;
        _error = widget.errorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.event_busy_rounded, color: AppTheme.error),
    title: const Text('Cancel this session?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.session.name} · ${_timeRange(context, widget.session)} · ${_formatDate(context, widget.date)}',
        ),
        const SizedBox(height: 8),
        const Text('This will release your booking for this session.'),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppTheme.error)),
        ],
        if (_isCancelling) ...[
          const SizedBox(height: 18),
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: _isCancelling
            ? null
            : () => Navigator.of(context).pop(false),
        child: const Text('Keep Session'),
      ),
      FilledButton(
        onPressed: _isCancelling ? null : _confirm,
        child: Text(_isCancelling ? 'Cancelling…' : 'Confirm Cancellation'),
      ),
    ],
  );
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFE23744).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: const Color(0xFFE23744)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.sectionTitle),
            const SizedBox(height: 3),
            Text(subtitle, style: AppTheme.secondaryTextStyle),
          ],
        ),
      ),
    ],
  );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.brandSoft,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.brand),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTheme.secondaryTextStyle)),
        ?action,
      ],
    ),
  );
}

class _GoOnlineBanner extends StatelessWidget {
  const _GoOnlineBanner({required this.onGoOnline});

  final VoidCallback onGoOnline;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F1),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF4D0D0)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final message = Row(
          children: [
            const Icon(
              Icons.power_settings_new_rounded,
              color: Color(0xFFE23744),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("You're offline", style: AppTheme.cardTitle),
                  SizedBox(height: 3),
                  Text(
                    'Go online to book a session.',
                    style: AppTheme.secondaryTextStyle,
                  ),
                ],
              ),
            ),
          ],
        );
        final button = FilledButton(
          onPressed: onGoOnline,
          child: const Text('Go Online'),
        );
        if (constraints.maxWidth < 310) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [message, const SizedBox(height: 12), button],
          );
        }
        return Row(
          children: [
            Expanded(child: message),
            const SizedBox(width: 8),
            button,
          ],
        );
      },
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFFE23744), size: 19),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: AppTheme.bodyText)),
    ],
  );
}

class _OutcomeContent extends StatelessWidget {
  const _OutcomeContent({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.75, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Opacity(opacity: value.clamp(0, 1), child: child),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.brand, size: 56),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTheme.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

IconData _sessionIcon(GigSession session) => switch (session.id) {
  'morning' || 'late-morning' => Icons.wb_sunny_outlined,
  'afternoon' => Icons.wb_sunny_rounded,
  'evening' => Icons.wb_twilight_rounded,
  _ => Icons.nightlight_round,
};

String _timeRange(BuildContext context, GigSession session) {
  final start = TimeOfDay(hour: session.startHour, minute: 0);
  final end = TimeOfDay(hour: session.endHour, minute: 0);
  return '${start.format(context)} – ${end.format(context)}';
}

String _formatDate(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatFullDate(date);
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
