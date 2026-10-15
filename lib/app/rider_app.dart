import 'package:flutter/material.dart';

import '../core/network/rider_api_client.dart';
import '../core/theme/app_theme.dart';
import 'rider_shell.dart';

class RiderApp extends StatelessWidget {
  const RiderApp({this.apiClient, super.key});

  final RiderApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyShopzy Rider',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: RiderShell(apiClient: apiClient),
    );
  }
}
