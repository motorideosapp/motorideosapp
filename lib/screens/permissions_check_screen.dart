import 'package:flutter/material.dart';
import 'package:moto_ride_os/screens/dashboard_screen.dart';
import 'package:moto_ride_os/services/permission_service.dart';
import 'package:moto_ride_os/models/permission_status.dart' as app_status;
import 'package:permission_handler/permission_handler.dart';


class PermissionsCheckScreen extends StatefulWidget {
  const PermissionsCheckScreen({super.key});

  @override
  State<PermissionsCheckScreen> createState() => _PermissionsCheckScreenState();
}

class _PermissionsCheckScreenState extends State<PermissionsCheckScreen> {
  final PermissionService _permissionService = PermissionService();
  app_status.PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    // Ekrana ilk çizimden hemen sonra izinleri kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });
  }

  Future<void> _checkAndNavigate() async {
    // Servis aracılığıyla mevcut izin durumlarını kontrol et
    final initialStatus = await _permissionService.checkPermissions();

    // Eğer tüm izinler zaten verilmişse, doğrudan ana ekrana geç
    if (initialStatus.allPermissionsGranted) {
      _navigateToDashboard();
      return;
    }

    // İzinler eksikse, kullanıcıdan izinleri iste
    await _permissionService.requestPermissions();

    // İstek sonrası en güncel durumu tekrar kontrol et
    final finalStatus = await _permissionService.checkPermissions();

    // Eğer artık tüm izinler tamamsa ana ekrana geç
    if (finalStatus.allPermissionsGranted) {
      _navigateToDashboard();
    } else {
      // Değilse, eksik izinleri göstermek için state'i güncelle
      if (mounted) {
        setState(() {
          _status = finalStatus;
        });
      }
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Eğer _status henüz belirlenmediyse (ilk kontrol anı)
    if (_status == null) {
      return _buildLoadingUI();
    }

    // Eksik olan ilk izne göre ilgili hata ekranını göster
    if (!_status!.isLocationServiceEnabled) {
      return _buildErrorUI(
        icon: Icons.location_disabled_rounded,
        message: "Hız ve navigasyon özellikleri için lütfen cihazınızın konum servislerini açın.",
        buttonText: "Konum Servislerini Aç",
        onPressed: () => openAppSettings(),
      );
    }
    if (!_status!.isBluetoothEnabled) {
      return _buildErrorUI(
        icon: Icons.bluetooth_disabled_rounded,
        message: "İnterkom ve diğer cihazlara bağlanabilmek için Bluetooth izni gereklidir.",
        buttonText: "İzin Ayarlarını Aç",
        onPressed: () => openAppSettings(),
      );
    }
    if (!_status!.isMicrophoneGranted) {
      return _buildErrorUI(
        icon: Icons.mic_off_rounded,
        message: "Sesli komutlar ve telefon görüşmeleri için mikrofon izni gereklidir.",
        buttonText: "İzin Ayarlarını Aç",
        onPressed: () => openAppSettings(),
      );
    }
    // YENİ EKLENEN KONTROL
    if (!_status!.isAudioAccessGranted) {
      return _buildErrorUI(
        icon: Icons.music_off_rounded,
        message: "Cihazınızdaki müziklere erişebilmek için depolama izni gereklidir.",
        buttonText: "İzin Ayarlarını Aç",
        onPressed: () => openAppSettings(),
      );
    }
    if (!_status!.isInternetConnected) {
       return _buildErrorUI(
        icon: Icons.wifi_off_rounded,
        message: "Harita ve diğer çevrimiçi servisler için internet bağlantısı gereklidir.",
        buttonText: "Tekrar Dene", // İnternet için ayar butonu yerine tekrar deneme daha mantıklı
        onPressed: _checkAndNavigate,
      );
    }
    
    // Herhangi bir durum eşleşmezse, varsayılan olarak yükleme ekranı göster
    return _buildLoadingUI();
  }

  Widget _buildLoadingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.white),
        const SizedBox(height: 20),
        Text(
          'İzinler kontrol ediliyor...',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildErrorUI({
    required IconData icon,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Colors.redAccent),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.cyanAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: onPressed,
          ),
          const SizedBox(height: 16),
          TextButton(
            child: const Text("Tekrar Dene", style: TextStyle(color: Colors.white70)),
            onPressed: _checkAndNavigate,
          ),
        ],
      ),
    );
  }
}
