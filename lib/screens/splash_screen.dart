import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moto_ride_os/screens/permissions_check_screen.dart';
import 'package:moto_ride_os/screens/dashboard_screen.dart'; // Import geri eklendi

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
          () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          // Orijinal akış geri yüklendi
          builder: (context) => PermissionsCheckScreen(
            child: DashboardScreen(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Moto Ride OS',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/logo.png',
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.error_outline,
                  size: 100,
                  color: Colors.red,
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Ücretsiz Sürüm',
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
