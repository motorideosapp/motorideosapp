import 'package:flutter/material.dart';
import 'package:moto_ride_os/screens/permissions_check_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MotoRideOS());
}

class MotoRideOS extends StatelessWidget {
  const MotoRideOS({super.key});

  @override
  Widget build(BuildContext context) {
    // Aydınlık Tema Tanımı
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF0F2F5), // Açık gri bir arka plan
      fontFamily: 'Exo2',
      primaryColor: Colors.blue,
      colorScheme: ColorScheme.fromSwatch(brightness: Brightness.light)
          .copyWith(secondary: Colors.blueAccent),
    );

    // Karanlık Tema Tanımı (Mevcut stiliniz korunarak)
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1c1c1e),
      fontFamily: 'Exo2',
      primaryColor: Colors.cyan,
      colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark)
          .copyWith(secondary: Colors.cyanAccent),
    );

    return MaterialApp(
      title: 'Moto Ride OS',
      debugShowCheckedModeBanner: false,
      theme: lightTheme, // Aydınlık tema olarak ayarlandı
      darkTheme: darkTheme, // Karanlık tema olarak ayarlandı
      themeMode:
          ThemeMode.system, // Sistemin tema ayarını otomatik olarak kullan
      home: const PermissionsCheckScreen(),
    );
  }
}
