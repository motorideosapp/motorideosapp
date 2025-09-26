
import 'package:flutter/material.dart';
import 'package:moto_ride_os/screens/permissions_check_screen.dart';
import 'package:moto_ride_os/utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MotoRideOS());
}

class MotoRideOS extends StatefulWidget {
  const MotoRideOS({super.key});

  @override
  State<MotoRideOS> createState() => _MotoRideOSState();

  static _MotoRideOSState of(BuildContext context) =>
      context.findAncestorStateOfType<_MotoRideOSState>()!;
}

class _MotoRideOSState extends State<MotoRideOS> {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get currentTheme => _themeMode;

  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moto Ride OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: const PermissionsCheckScreen(),
    );
  }
}
