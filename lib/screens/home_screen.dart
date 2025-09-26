import 'package:flutter/material.dart';
import 'package:moto_ride_os/l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black, // Ana ekran da koyu arka plan
      appBar: AppBar(
        title: Text(
          localizations.appTitle, // Yerelleştirilmiş uygulama başlığı
          style: const TextStyle(color: Colors.white), // Yazı rengini beyaz yapalım
        ),
        backgroundColor: Colors.black, // AppBar arka planını da siyah yapalım
        iconTheme: const IconThemeData(color: Colors.white), // İkon rengini beyaz yapalım
      ),
      body: Center(
        child: Text(
          localizations.welcomeMessage, // getString yerine doğrudan özelliği kullanıyoruz
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}