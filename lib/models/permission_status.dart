/// Uygulamanın çalışması için gereken tüm izinlerin ve servislerin anlık durumunu tutan model.
class PermissionStatus {
  final bool isLocationServiceEnabled; // GPS açık mı?
  final bool isLocationPermissionGranted; // Konum izni verildi mi?
  final bool isInternetConnected;     // İnternet var mı?
  final bool isBluetoothEnabled;      // Bluetooth açık mı?
  final bool isMicrophoneGranted;     // Mikrofon izni var mı?
  final bool isAudioAccessGranted;    // Müzik/Depolama izni var mı?
  final bool isSystemAlertWindowGranted; // Diğer uygulamaların üzerinde gösterme izni

  const PermissionStatus({
    required this.isLocationServiceEnabled,
    required this.isLocationPermissionGranted,
    required this.isInternetConnected,
    required this.isBluetoothEnabled,
    required this.isMicrophoneGranted,
    required this.isAudioAccessGranted,
    required this.isSystemAlertWindowGranted,
  });

  // Tüm kritik izinlerin ve servislerin tam olup olmadığını kontrol eden yardımcı getter.
  bool get allPermissionsGranted =>
      isLocationServiceEnabled &&
          isLocationPermissionGranted &&
          isInternetConnected &&
          // isBluetoothEnabled && // Bluetooth zorunluluğu kaldırıldı
          isMicrophoneGranted &&
          isAudioAccessGranted;
}
