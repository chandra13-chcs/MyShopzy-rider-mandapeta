# MyShopzy Rider

A Flutter demo app for rider workflows. The app opens directly to the Rider
Home screen with sample delivery, earnings, profile, and settings content.

## Included screens

- Home dashboard and online availability toggle
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

## Run

```sh
flutter pub get
flutter run
```
