import 'dart:io'; // Platform kontrolü için

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart'; // SDK versiyonu için
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moto_ride_os/models/permission_status.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

// UYARI: Bu kod `device_info_plus` paketini gerektirir.
// Lütfen `pubspec.yaml` dosyanızda olduğundan emin olun:
// dependencies:
//   device_info_plus: ^9.1.2 (veya güncel sürüm)

// Uygulama için gerekli tüm izinleri ve servis durumlarını yöneten servis.
class PermissionService {
  // Android SDK versiyonunu bir kereye mahsus saklamak için.
  static int? _sdkInt;

  // Android SDK versiyonunu asenkron olarak getiren ve saklayan yardımcı fonksiyon.
  Future<int> get _androidSdkVersion async {
    if (_sdkInt != null) return _sdkInt!;
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      _sdkInt = deviceInfo.version.sdkInt;
      return _sdkInt!;
    }
    return 0;
  }

  // Tüm izin ve servis durumlarını tek seferde kontrol eder.
  Future<PermissionStatus> checkPermissions() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);
    final isBluetoothOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;

    final locationStatus = await handler.Permission.locationWhenInUse.status;
    final microphoneStatus = await handler.Permission.microphone.status;
    final audioStatus = await handler.Permission.audio.status;

    bool areBluetoothPermissionsGranted = false;
    if (Platform.isAndroid) {
      if (await _androidSdkVersion >= 31) { // Android 12 (S) ve üzeri
        final scanStatus = await handler.Permission.bluetoothScan.status;
        final connectStatus = await handler.Permission.bluetoothConnect.status;
        areBluetoothPermissionsGranted = scanStatus.isGranted && connectStatus.isGranted;
      } else { // Android 11 (R) ve altı
        final bluetoothStatus = await handler.Permission.bluetooth.status;
        areBluetoothPermissionsGranted = bluetoothStatus.isGranted;
      }
    } else {
      // iOS vb. için varsayılan kontrol
      final bluetoothStatus = await handler.Permission.bluetooth.status;
      areBluetoothPermissionsGranted = bluetoothStatus.isGranted;
    }

    return PermissionStatus(
      isLocationServiceEnabled: isLocationEnabled,
      isLocationPermissionGranted: locationStatus.isGranted,
      isInternetConnected: hasInternet,
      isBluetoothEnabled: isBluetoothOn && areBluetoothPermissionsGranted,
      isMicrophoneGranted: microphoneStatus.isGranted,
      isAudioAccessGranted: audioStatus.isGranted,
    );
  }

  // Eksik olan tüm kritik izinleri kullanıcıdan ister.
  Future<void> requestPermissions() async {
    List<handler.Permission> permissionsToRequest = [
      handler.Permission.locationWhenInUse,
      handler.Permission.microphone,
      handler.Permission.audio,
    ];

    if (Platform.isAndroid) {
      if (await _androidSdkVersion >= 31) { // Android 12 (S) ve üzeri
        permissionsToRequest.addAll([
          handler.Permission.bluetoothScan,
          handler.Permission.bluetoothConnect,
        ]);
      } else { // Android 11 (R) ve altı
        permissionsToRequest.add(handler.Permission.bluetooth);
      }
    } else {
      // iOS vb. için
      permissionsToRequest.add(handler.Permission.bluetooth);
    }

    await permissionsToRequest.request();
  }
}
