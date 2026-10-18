enum GigBookingStatus { booked, cancelled }

class GigSession {
  const GigSession({
    required this.id,
    required this.name,
    required this.startHour,
    required this.endHour,
  });

  final String id;
  final String name;
  final int startHour;
  final int endHour;
}

class GigAvailability {
  const GigAvailability({
    required this.availableSlots,
    required this.totalSlots,
  });

  final int availableSlots;
  final int totalSlots;
}

class GigDataSnapshot {
  const GigDataSnapshot({required this.bookings, required this.availability});

  final List<GigBooking> bookings;
  final Map<String, GigAvailability> availability;
}

class GigBooking {
  const GigBooking({
    required this.id,
    required this.sessionId,
    required this.date,
    required this.status,
  });

  final String id;
  final String sessionId;
  final DateTime date;
  final GigBookingStatus status;

  GigBooking copyWith({GigBookingStatus? status}) => GigBooking(
    id: id,
    sessionId: sessionId,
    date: date,
    status: status ?? this.status,
  );
}

abstract interface class GigRepository {
  bool get isDemo;

  Future<GigDataSnapshot> getGigData(DateTime date);

  Future<GigBooking> bookSession(GigSession session, DateTime date);

  Future<void> cancelBooking(GigBooking booking);
}

class GigRepositoryException implements Exception {
  const GigRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DemoGigRepository implements GigRepository {
  DemoGigRepository({this.availability = const {}});

  final List<GigBooking> _bookings = [];
  final Map<String, GigAvailability> availability;
  int _nextId = 0;

  @override
  bool get isDemo => true;

  @override
  Future<GigDataSnapshot> getGigData(DateTime date) async => GigDataSnapshot(
    bookings: _bookings
        .where((booking) => _sameDate(booking.date, date))
        .toList(growable: false),
    availability: availability,
  );

  @override
  Future<GigBooking> bookSession(GigSession session, DateTime date) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final alreadyBooked = _bookings.any(
      (booking) =>
          booking.sessionId == session.id &&
          _sameDate(booking.date, date) &&
          booking.status != GigBookingStatus.cancelled,
    );
    if (alreadyBooked) {
      throw const GigRepositoryException(
        'You already have a booking for this session.',
      );
    }
    final booking = GigBooking(
      id: 'demo-gig-${++_nextId}',
      sessionId: session.id,
      date: DateTime(date.year, date.month, date.day),
      status: GigBookingStatus.booked,
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<void> cancelBooking(GigBooking booking) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _bookings.indexWhere((item) => item.id == booking.id);
    if (index == -1 || _bookings[index].status != GigBookingStatus.booked) {
      throw const GigRepositoryException(
        'This session can no longer be cancelled.',
      );
    }
    _bookings[index] = _bookings[index].copyWith(
      status: GigBookingStatus.cancelled,
    );
  }
}

class UnavailableGigRepository implements GigRepository {
  const UnavailableGigRepository();

  static const _unavailable = GigRepositoryException(
    'Gig booking is not connected to the rider service yet.',
  );

  @override
  bool get isDemo => false;

  @override
  Future<GigDataSnapshot> getGigData(DateTime date) =>
      Future<GigDataSnapshot>.error(_unavailable);

  @override
  Future<GigBooking> bookSession(GigSession session, DateTime date) =>
      Future<GigBooking>.error(_unavailable);

  @override
  Future<void> cancelBooking(GigBooking booking) =>
      Future<void>.error(_unavailable);
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
