import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moto_ride_os/l10n/app_localizations.dart';
import 'package:moto_ride_os/models/permission_status.dart' as app_status; // Takma ad eklendi
import 'package:moto_ride_os/screens/dashboard_screen.dart';
import 'package:moto_ride_os/screens/permissions_check_screen.dart';
import 'package:moto_ride_os/services/permission_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final permissionService = PermissionService();

    // Önce izinleri iste
    await permissionService.requestPermissions();

    // Ardından durumu kontrol et
    final status = await permissionService.checkPermissions();

    // Splash ekranının en az 2 saniye görünmesini sağla
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return; // Widget ağaçtan kaldırıldıysa devam etme

    // Sonuca göre yönlendirme yap
    if (status.allPermissionsGranted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PermissionsCheckScreen(status: status)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.cyan),
            const SizedBox(height: 30),
            const Text(
              'Moto Ride OS',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.freeVersion,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
