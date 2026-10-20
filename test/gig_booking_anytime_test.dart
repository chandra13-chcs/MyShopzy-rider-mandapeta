import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myshopzy_rider/core/state/availability_store.dart';
import 'package:myshopzy_rider/core/theme/app_theme.dart';
import 'package:myshopzy_rider/gigs/gig_repository.dart';
import 'package:myshopzy_rider/gigs/gigs_page.dart';

void main() {
  testWidgets('gig sessions can be booked offline after their scheduled time', (
    tester,
  ) async {
    final availabilityStore = AvailabilityStore(
      initialStatus: AvailabilityStatus.offline,
    );
    final repository = DemoGigRepository(
      availability: const {
        'morning': GigAvailability(availableSlots: 0, totalSlots: 4),
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GigsPage(
          availabilityStore: availabilityStore,
          repository: repository,
          clock: () => DateTime(2026, 10, 18, 23, 30),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open anytime'), findsWidgets);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('gig-book-0')))
          .onPressed,
      isNotNull,
    );
    expect(find.text('Go Online'), findsNothing);

    final morningButton = find.byKey(const ValueKey('gig-book-0'));
    await tester.ensureVisible(morningButton);
    await tester.tap(morningButton);
    await tester.pumpAndSettle();
    expect(
      find.text('You can book while offline; going online is not required.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Book Session'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(find.text('Gig Session Booked!'), findsOneWidget);

    await tester.tap(find.text('View My Gigs'));
    await tester.pumpAndSettle();
    expect(
      (await repository.getGigData(DateTime(2026, 10, 18))).bookings,
      hasLength(1),
    );
    expect(find.text('Morning'), findsOneWidget);
    expect(find.text("Today's bookings"), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Sessions open to book today'), findsOneWidget);
    await tester.tap(find.text('Book a session'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('gig-book-1')))
          .onPressed,
      isNotNull,
    );

    await tester.pumpWidget(const SizedBox());
    availabilityStore.dispose();
  });
}
