import 'package:flutter/material.dart';
import 'package:moto_ride_os/screens/permissions_check_screen.dart';
import 'package:moto_ride_os/utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MotoRideOS());
}

class MotoRideOS extends StatelessWidget {
  const MotoRideOS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moto Ride OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const PermissionsCheckScreen(),
    );
  }
}
