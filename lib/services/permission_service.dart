
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moto_ride_os/models/permission_status.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

// Uygulama için gerekli tüm izinleri ve servis durumlarını yöneten servis.
class PermissionService {
  // Tüm izin ve servis durumlarını tek seferde kontrol eder.
  Future<PermissionStatus> checkPermissions() async {
    // Konum servislerinin açık olup olmadığını kontrol et.
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    
    // İnternet bağlantısını kontrol et.
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult.contains(ConnectivityResult.mobile) || 
                        connectivityResult.contains(ConnectivityResult.wifi);
    
    // Mikrofon izninin durumunu kontrol et.
    final microphoneStatus = await handler.Permission.microphone.status;
    
    // YENİ: Depolama/Müzik iznini kontrol et.
    // Android 13 (API 33) ve üstü için Permission.audio, altı için Permission.storage kullanılır.
    // permission_handler bunu otomatik yönetir, biz sadece istemeliyiz.
    final audioStatus = await handler.Permission.audio.status;

    return PermissionStatus(
      isLocationServiceEnabled: isLocationEnabled,
      isInternetConnected: hasInternet,
      isBluetoothEnabled: true, // TODO: Gerçek Bluetooth kontrolü eklenecek.
      isMicrophoneGranted: microphoneStatus.isGranted,
      isAudioAccessGranted: audioStatus.isGranted, // Yeni kontrolün sonucunu ata.
    );
  }

  // Eksik olan tüm kritik izinleri kullanıcıdan ister.
  Future<void> requestPermissions() async {
    // İzinleri bir liste halinde toplayıp tek seferde isteyelim.
    await [
      handler.Permission.locationWhenInUse, 
      handler.Permission.microphone,
      handler.Permission.audio, // YENİ: Müzik erişimi için izin iste.
      // Not: on_audio_query kaldırıldığı için MANAGE_EXTERNAL_STORAGE artık gerekmiyor.
    ].request();
  }
}
