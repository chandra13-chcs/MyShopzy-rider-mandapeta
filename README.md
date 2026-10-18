# MyShopzy Rider

A Flutter demo app for rider workflows. The app opens directly to the Rider
Home screen with sample delivery, earnings, profile, and settings content.

## Included screens

- Home dashboard and online availability toggle
- Five daily gig sessions and My Gigs booking history
- Delivery details and order list
- Delivery history and earnings
- Rider profile, preferences, and help/support

The widget-test/demo app can run with local sample data. The app entry point
uses the Rider API.

## Rider API development

The app sends `X-Rider-Id: 00000000-0000-4000-8000-000000000001` and uses
`http://10.0.2.2:3000` by default on Android emulators, or
`http://localhost:3000` on other platforms. Override the URL with
`--dart-define=RIDER_API_BASE_URL=http://<backend-host>:3000`.
The backend must be running with its migrations and seeded demo rider applied.
Going online requests foreground location permission and sends the current
coordinates to the Rider API. Available-order polling and acceptance are gated
on local online status and network connectivity; polling resumes when
connectivity returns. Android permits cleartext traffic only in debug builds;
use an HTTPS API URL for release builds and physical-device testing.

When connected to the rider API, going on duty requires a valid foreground
location fix and streams subsequent fixes to the backend. Available-order
polling is gated on duty, connectivity, and a successful location update.
Incoming offers stay open for 30 seconds; accepting starts the pickup workflow.
Pickup, out-for-delivery, and delivered transitions are confirmed by the API.
Navigation opens external map directions, while customer call/SMS actions are
enabled only after the order is accepted and a phone number is returned.
Completed deliveries update the backend settlement record and refresh the
daily earnings summary.

The gig sessions currently use an in-memory demo repository only when the app
is run without a Rider API client. Demo bookings are explicitly labelled,
include no simulated slot counts, and are not saved to a server or across app
restarts. When a Rider API client is configured, gig booking stays unavailable
until the backend provides session availability, booking, and cancellation
endpoints; delivery-order APIs are not used for gig sessions.

GPS fixes and order status updates that fail because of lost connectivity are
kept in an in-memory retry queue and flushed when connectivity returns. These
queued updates do not survive an app process restart. The delivery view uses
OpenStreetMap tiles by default and draws the rider-to-store-to-customer route;
configure a compatible production tile source with
`--dart-define=RIDER_MAP_TILE_URL=https://tiles.example/{z}/{x}/{y}.png`.
Follow the selected tile provider's usage and attribution requirements.

## Run

```sh
flutter pub get
flutter run
```
