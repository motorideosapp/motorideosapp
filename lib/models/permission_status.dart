/// Uygulamanın çalışması için gereken tüm izinlerin ve servislerin anlık durumunu tutan model.
class PermissionStatus {
  final bool isLocationServiceEnabled; // GPS açık mı?
  final bool isLocationPermissionGranted; // Konum izni verildi mi?
  final bool isInternetConnected;     // İnternet var mı?
  final bool isBluetoothEnabled;      // Bluetooth açık mı?
  final bool isMicrophoneGranted;     // Mikrofon izni var mı?
  final bool isAudioAccessGranted;    // Müzik/Depolama izni var mı?

  const PermissionStatus({
    required this.isLocationServiceEnabled,
    required this.isLocationPermissionGranted,
    required this.isInternetConnected,
    required this.isBluetoothEnabled,
    required this.isMicrophoneGranted,
    required this.isAudioAccessGranted,
  });

  // Tüm kritik izinlerin ve servislerin tam olup olmadığını kontrol eden yardımcı getter.
  // GELİŞTİRME NOTU: Emülatörde Bluetooth testi yapılamadığı için isBluetoothEnabled
  // kontrolü geçici olarak devre dışı bırakıldı. Gerçek cihazda test etmeden önce AKTİF ET!
  bool get allPermissionsGranted =>
      isLocationServiceEnabled &&
          isLocationPermissionGranted &&
          isInternetConnected &&
          isBluetoothEnabled && // <-- ARTIK AKTİF!
          isMicrophoneGranted &&
          isAudioAccessGranted;
}
