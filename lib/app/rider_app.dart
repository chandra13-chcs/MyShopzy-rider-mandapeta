import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'rider_shell.dart';

class RiderApp extends StatelessWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyShopzy Rider',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const RiderShell(),
    );
  }
}
