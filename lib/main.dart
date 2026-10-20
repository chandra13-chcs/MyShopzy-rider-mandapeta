import 'package:flutter/material.dart';

import 'app/rider_app.dart';
import 'core/network/rider_api_client.dart';

const _showDemoOrder = bool.fromEnvironment(
  'RIDER_DEMO_MODE',
  defaultValue: true,
);

void main() {
  runApp(
    RiderApp(
      apiClient: _showDemoOrder ? null : RiderApiClient.instance,
      showDemoOrder: _showDemoOrder,
    ),
  );
}
