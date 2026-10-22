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
  final Set<String> _busySessionIds = {};
  int _selectedTab = 0;
  bool _isLoading = true;
  late bool _wasOnline;
  late DateTime _observedDate;
  String? _loadError;
  Timer? _expiryRefreshTimer;
  DateTime get _now => (widget.clock?.call() ?? DateTime.now()).toLocal();
  DateTime get _today => DateTime(_now.year, _now.month, _now.day);
  bool get _isDemo => _repository.isDemo;

  @override
  void initState() {
    super.initState();
    _wasOnline = widget.availabilityStore.isOnline;
    _observedDate = _today;
    widget.availabilityStore.addListener(_handleAvailabilityChanged);
    _expiryRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final today = _today;
      if (!_sameDate(today, _observedDate)) {
        _observedDate = today;
        unawaited(_refreshBookings());
      } else {
        setState(() {});
      }
    });
    unawaited(_refreshBookings());
  }

  @override
  void dispose() {
    _expiryRefreshTimer?.cancel();
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
    final date = _today;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await _repository.getGigData(date);
      if (!mounted) return;
      setState(() {
        _bookings
          ..clear()
          ..addAll(
            data.bookings.where((booking) => _sameDate(booking.date, date)),
          );
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

  bool _isExpired(GigSession session) {
    final end = DateTime(
      _today.year,
      _today.month,
      _today.day,
      session.endHour,
    );
    return !_now.isBefore(end);
  }

  bool _canBook(GigSession session) {
    return _loadError == null &&
        !_isExpired(session) &&
        !_isBooked(session) &&
        !_busySessionIds.contains(session.id);
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
          isBooked: () => _isBooked(session),
          isExpired: () => _isExpired(session),
          canBook: () => _canBook(session),
          isDemo: _isDemo,
          onBook: () => _bookSession(session),
          loadError: () => _loadError,
        ),
      ),
    );
    if (booked == true && mounted) setState(() => _selectedTab = 1);
  }

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return Scaffold(
      appBar: AppBar(title: const Text('Gigs')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.appBackground, AppTheme.surface],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.divider),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.darkGreen.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
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
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AppTheme.brand
                          : Colors.transparent,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.white
                          : AppTheme.secondaryText,
                    ),
                    side: const WidgetStatePropertyAll(BorderSide.none),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  onSelectionChanged: (selection) =>
                      setState(() => _selectedTab = selection.first),
                ),
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
      ),
    );
  }

  Widget _buildSessions(BuildContext context) {
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
        const SizedBox(height: 16),
        const _GigBookingHero(),
        if (_isDemo) ...[
          const SizedBox(height: 12),
          const _InfoBanner(
            icon: Icons.science_outlined,
            text: 'Demo mode: bookings are simulated in memory and are not saved to MyShopzy. Slot counts are not connected.',
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
    final canBook = _canBook(session);
    final expired = _isExpired(session);
    final accent = expired
        ? const Color(0xFF87938B)
        : _loadError != null
        ? AppTheme.secondaryText
        : _sessionAccent(session);
    final status = isBooked
        ? 'Booked'
        : expired
        ? 'Expired'
        : _loadError != null
        ? 'Booking unavailable'
        : _now.isBefore(
            DateTime(_today.year, _today.month, _today.day, session.startHour),
          )
        ? 'Available'
        : 'In progress';
    final color = isBooked
        ? AppTheme.brand
        : expired
        ? const Color(0xFF87938B)
        : accent;

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
      child: _GigDepth(
        child: Card(
          color: Colors.white,
          elevation: 6,
          shadowColor: accent.withValues(alpha: 0.16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accent.withValues(alpha: 0.18)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openSession(session),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 290;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withValues(alpha: 0.18),
                                  accent.withValues(alpha: 0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(_sessionIcon(session), color: accent),
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
                          if (!compact)
                            _StatusPill(label: status, color: color),
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
                              style: AppTheme.secondaryTextStyle.copyWith(
                                color: AppTheme.primaryText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _StatusPill(
                              label: expired
                                  ? 'Session ended'
                                  : 'Closes ${_endTime(context, session)}',
                              color: expired
                                  ? const Color(0xFF87938B)
                                  : AppTheme.brand,
                            ),
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
                                style: AppTheme.secondaryTextStyle.copyWith(
                                  color: AppTheme.primaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _StatusPill(
                              label: expired
                                  ? 'Session ended'
                                  : 'Closes ${_endTime(context, session)}',
                              color: expired
                                  ? const Color(0xFF87938B)
                                  : AppTheme.brand,
                            ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      TweenAnimationBuilder<double>(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: _sessionProgress(session)),
                        builder: (context, progress, child) => ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            color: accent,
                            backgroundColor: accent.withValues(alpha: 0.12),
                            semanticsLabel: 'Shift time elapsed',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: ValueKey(
                            'gig-book-${_sessions.indexOf(session)}',
                          ),
                          onPressed: canBook
                              ? () => _openSession(session)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.brand,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: expired
                                ? const Color(0xFFE9ECF1)
                                : const Color(0xFFE2EAFB),
                            disabledForegroundColor: expired
                                ? const Color(0xFF87938B)
                                : AppTheme.brand,
                            elevation: 2,
                            shadowColor: AppTheme.brand.withValues(alpha: 0.25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(
                            isBooked
                                ? 'Booked'
                                : expired
                                ? 'Expired'
                                : _loadError != null
                                ? 'Unavailable'
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
      ),
    );
  }

  double _sessionProgress(GigSession session) {
    final start = DateTime(
      _today.year,
      _today.month,
      _today.day,
      session.startHour,
    );
    final end = DateTime(
      _today.year,
      _today.month,
      _today.day,
      session.endHour,
    );
    if (!_now.isAfter(start)) return 0;
    if (!_now.isBefore(end)) return 1;
    return _now.difference(start).inMilliseconds /
        end.difference(start).inMilliseconds;
  }

  Widget _buildMyGigs(BuildContext context) {
    final active = _bookings.where(
      (booking) => booking.status == GigBookingStatus.booked,
    );
    final cancelled = _bookings.where(
      (booking) => booking.status == GigBookingStatus.cancelled,
    );
    final upcoming = _sessions.where(
      (session) => !_isBooked(session) && !_isExpired(session),
    );
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
          ),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sessions open to book today', style: AppTheme.sectionTitle),
              const SizedBox(height: 10),
              if (upcoming.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No sessions are available to book right now.',
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
            _bookingCard(context, booking),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _bookingCard(BuildContext context, GigBooking booking) {
    final session = _sessionFor(booking.sessionId);
    if (session == null) return const SizedBox.shrink();
    final status = booking.status == GigBookingStatus.cancelled
        ? 'Cancelled'
        : 'Booked';
    final statusColor = status == 'Cancelled' ? AppTheme.error : AppTheme.brand;
    return _GigDepth(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(session.name, style: AppTheme.cardTitle),
                  ),
                  _StatusPill(label: status, color: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_timeRange(context, session)} · ${_formatDate(context, booking.date)}',
                style: AppTheme.secondaryTextStyle,
              ),
            ],
          ),
        ),
      ),
    );
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
    required this.isBooked,
    required this.isExpired,
    required this.canBook,
    required this.isDemo,
    required this.onBook,
    required this.loadError,
    super.key,
  });

  final GigSession session;
  final DateTime date;
  final bool Function() isBooked;
  final bool Function() isExpired;
  final bool Function() canBook;
  final bool isDemo;
  final Future<bool> Function() onBook;
  final String? Function() loadError;
  @override
  State<GigSessionDetailsPage> createState() => _GigSessionDetailsPageState();
}

class _GigSessionDetailsPageState extends State<GigSessionDetailsPage> {
  bool _isSubmitting = false;
  String? _error;
  Timer? _expiryRefreshTimer;

  @override
  void initState() {
    super.initState();
    _expiryRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _expiryRefreshTimer?.cancel();
    super.dispose();
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
          _error = 'This session could not be booked. Please try again.';
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
  Widget build(BuildContext context) {
    final error = _error ?? widget.loadError();
    final expired = widget.isExpired();
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
                  Icon(
                    Icons.delivery_dining_rounded,
                    color: expired
                        ? const Color(0xFF87938B)
                        : _sessionAccent(widget.session),
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
                  _DetailRow(
                    icon: expired
                        ? Icons.timer_off_rounded
                        : Icons.schedule_rounded,
                    label: expired
                        ? 'This gig has expired because its scheduled end time has passed.'
                        : 'Booking closes at ${_endTime(context, widget.session)}.',
                  ),
                  const SizedBox(height: 12),
                  const _DetailRow(
                    icon: Icons.power_settings_new_rounded,
                    label: 'You can book while offline; going online is not required.',
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
          if (widget.isBooked())
            const FilledButton(onPressed: null, child: Text('Already Booked'))
          else if (expired)
            FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                disabledBackgroundColor: AppTheme.lightBlueSurface,
                disabledForegroundColor: AppTheme.secondaryText,
              ),
              child: const Text('Session Expired'),
            )
          else
            FilledButton(
              onPressed: widget.canBook() && !_isSubmitting ? _book : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
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

class _GigDepth extends StatefulWidget {
  const _GigDepth({required this.child});

  final Widget child;

  @override
  State<_GigDepth> createState() => _GigDepthState();
}

class _GigDepthState extends State<_GigDepth> {
  double _tiltX = 0;
  double _tiltY = 0;
  bool _hovered = false;
  bool _pressed = false;

  void _onHover(PointerEvent event) {
    final size = context.size;
    if (size == null) return;
    setState(() {
      _hovered = true;
      _tiltX = ((event.localPosition.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
      _tiltY = ((event.localPosition.dy / size.height) * 2 - 1).clamp(
        -1.0,
        1.0,
      );
    });
  }

  void _reset() {
    setState(() {
      _hovered = false;
      _pressed = false;
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final motionDisabled = MediaQuery.disableAnimationsOf(context);
    final pressed = !motionDisabled && _pressed;
    final hovered = !motionDisabled && _hovered;
    final tiltX = hovered ? _tiltY * 0.018 : 0.0;
    final tiltY = hovered ? -_tiltX * 0.018 : 0.0;
    final scale = pressed
        ? 0.985
        : hovered
        ? 1.012
        : 1.0;
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(tiltX)
      ..rotateY(tiltY)
      ..translateByDouble(
        0,
        pressed
            ? 2
            : hovered
            ? -2
            : 0,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);

    if (motionDisabled) return widget.child;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: MouseRegion(
        onHover: _onHover,
        onExit: (_) => _reset(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transformAlignment: Alignment.center,
          transform: transform,
          child: widget.child,
        ),
      ),
    );
  }
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
          color: AppTheme.lightGreenSurface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppTheme.accentGreen.withValues(alpha: 0.65),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brand.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppTheme.brand),
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

class _GigBookingHero extends StatelessWidget {
  const _GigBookingHero();

  @override
  Widget build(BuildContext context) => _GigDepth(
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkGreen, AppTheme.brand],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withValues(alpha: 0.22),
            blurRadius: 26,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -35,
              top: -56,
              child: _HeroOrb(size: 150, opacity: 0.08),
            ),
            Positioned(
              right: 44,
              bottom: -72,
              child: _HeroOrb(size: 130, opacity: 0.07),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.brandYellow, AppTheme.accentCoral],
                      ),
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentCoral.withValues(alpha: 0.38),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppTheme.darkGreen,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose your next shift',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Reserve your shift before its scheduled end.',
                          style: TextStyle(
                            color: Color(0xE6FFFFFF),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: opacity * 1.5),
        width: 1.5,
      ),
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}

Color _sessionAccent(GigSession _) => AppTheme.brand;

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.lightGreenSurface,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.32)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
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
      Icon(icon, color: AppTheme.brand, size: 19),
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

String _endTime(BuildContext context, GigSession session) =>
    TimeOfDay(hour: session.endHour, minute: 0).format(context);

String _formatDate(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatFullDate(date);
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
