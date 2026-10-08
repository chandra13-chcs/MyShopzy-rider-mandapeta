import 'package:flutter/foundation.dart';

enum AvailabilityStatus { offline, available }

class AvailabilityStore extends ValueNotifier<AvailabilityStatus> {
  AvailabilityStore({
    AvailabilityStatus initialStatus = AvailabilityStatus.available,
  }) : super(initialStatus);

  bool get isAvailable => value == AvailabilityStatus.available;

  void setAvailable(bool isAvailable) {
    value = isAvailable
        ? AvailabilityStatus.available
        : AvailabilityStatus.offline;
  }

  void toggle() => setAvailable(!isAvailable);
}
