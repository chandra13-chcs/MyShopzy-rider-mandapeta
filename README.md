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
polling is gated on duty, connectivity, and a successful location update. The
app only presents orders whose pickup coordinates are within 2 km of the
rider's latest GPS fix; orders without usable pickup coordinates are skipped.
In demo mode, the app requests device location before creating its sample
offer. The demo pickup and drop-off both use the same current GPS coordinates,
so the full pickup-to-delivery flow can be tried where the rider is standing
instead of routing to a distant sample address. The offer and delivery screens
label this as a local demo, show the order journey, and automatically detect
pickup/drop-off arrival at that point. Demo items, customer, kitchen, and payout
are sample data; the demo is not a real restaurant order and is not sent to the
Rider API. Allow location access in the browser/device; if permission is denied,
the app cannot create an accurate current-location demo offer.
Incoming offers take over the full screen while the app is in the foreground,
with a route map, expected earnings, pickup/drop-off details, and a single
directional swipe control. The rider cannot access other app options or dismiss
the offer with Back during its 30-second response window. A repeated alert
sound and strong haptic vibration stop when the rider accepts or rejects the
offer, or when the timer expires. Swipe right to accept or left to reject;
the **Open Google Maps to Pickup** button opens the pickup route while the
offer is visible. Accepting starts the pickup workflow. The app returns to its
normal options after the rider responds or the offer expires. Alert volume is set to the
highest level available to the app; the device's media volume still applies.
In Brave and other browsers, tap **Enable sound** on the first
offer so browser autoplay protection allows incoming-order audio. Browser
vibration requires a supported mobile browser/device; desktop browsers do not
provide physical vibration. The Profile > Settings **Sound** and **Vibration**
switches control incoming-order alerts for the current app session. Turning
Sound back on enables audio for subsequent offers; web browsers may still
require tapping **Enable sound** on the offer because autoplay is controlled
by the browser. App volume is set to maximum where supported, but the app
cannot override device mute or system volume.
Rejected offers are shown in a separate **Rejected orders** section in
delivery history for the current app session. Rejection history is local-only;
the Rider API currently has no endpoint for saving rejected orders permanently.
The offer API must include valid `pickupLatitude` and `pickupLongitude` values
for nearby-order filtering and automatic store-arrival detection. It should
also include an `items` array of `{ "name": "...", "quantity": 1 }` entries
for the complete pickup list.
The app detects arrival within 100 m and then presents a **View pickup order**
button. This opens the order ID, item list, quantities, pickup and customer
addresses, and payout. The rider confirms pickup with **I picked up the order**,
which sends the `picked_up` and `out_for_delivery` status updates and
immediately changes the route map destination to the customer. Pickup,
out-for-delivery, and delivered transitions are confirmed by the API.
The active delivery screen provides a **Open pickup + delivery route in Google
Maps** action. It opens directions from the rider's current location, via the
store pickup, to the customer; coordinates are preferred, with addresses used
when coordinates are unavailable. A **Google Maps** shortcut on the live route
map opens navigation to the current stop (pickup before pickup confirmation,
customer afterward). **Open Google Maps to Pickup** and **Open Google Maps to
Customer** actions also open navigation for the corresponding trip leg.
Customer call/SMS actions are enabled only after the order is accepted and a
phone number is returned.
Incoming-order alerts are not
delivered while the app is closed or in the background; the app polls for
offers while it is active.
Completed deliveries update the backend settlement record and refresh the
daily earnings summary.

Gig sessions are open to book at any time today, regardless of rider online
status or the session's scheduled hours. Bookings use a clearly labelled
in-memory demo repository, even when the Rider API client is configured; they
are not saved to the server or across app restarts. Persistent gig reservations
require backend session availability, booking, and cancellation endpoints;
delivery-order APIs are not used for gig sessions.

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

The app starts in demo mode and displays one sample incoming order with the
30-second alert and directional swipe flow. To connect to the Rider API instead,
run with `--dart-define=RIDER_DEMO_MODE=false`. Gig bookings and the sample
order in demo mode are in-memory examples and are not saved to the backend.
