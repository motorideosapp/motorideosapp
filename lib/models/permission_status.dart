
class PermissionStatus {
  final bool isLocationServiceEnabled;
  final bool isInternetConnected;
  final bool isBluetoothEnabled;
  final bool isMicrophoneGranted;
  final bool isAudioAccessGranted; // Yeni eklenen alan

  PermissionStatus({
    required this.isLocationServiceEnabled,
    required this.isInternetConnected,
    required this.isBluetoothEnabled,
    required this.isMicrophoneGranted,
    required this.isAudioAccessGranted, // Yeni eklenen alan
  });

  // Tüm kritik izinlerin verilip verilmediğini kontrol eden yardımcı bir getter.
  bool get allPermissionsGranted =>
      isLocationServiceEnabled &&
      isInternetConnected &&
      isBluetoothEnabled &&
      isMicrophoneGranted &&
      isAudioAccessGranted; // Yeni eklenen alan
}
