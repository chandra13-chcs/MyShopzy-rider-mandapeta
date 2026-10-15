import 'package:flutter/material.dart';

import 'app/rider_app.dart';
import 'core/network/rider_api_client.dart';

void main() {
  runApp(RiderApp(apiClient: RiderApiClient.instance));
}
