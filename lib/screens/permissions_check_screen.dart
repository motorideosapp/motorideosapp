import 'package:flutter/material.dart';
import 'package:moto_ride_os/services/permission_service.dart';
import 'package:moto_ride_os/models/permission_status.dart';

class PermissionsCheckScreen extends StatefulWidget {
  final Widget child;
  // HATA DÜZELTME: Bu widget artık dinamik bir alt widget (DashboardScreen) alabildiği için
  // constructor'ı sabit (const) olamaz.
  PermissionsCheckScreen({super.key, required this.child});

  @override
  State<PermissionsCheckScreen> createState() => _PermissionsCheckScreenState();
}

class _PermissionsCheckScreenState extends State<PermissionsCheckScreen> {
  final PermissionService _permissionService = PermissionService();
  Future<PermissionStatus>? _permissionStatusFuture;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  void _refreshPermissions() {
    setState(() {
      _permissionStatusFuture = _permissionService.checkPermissions();
    });
  }

  Future<void> _requestPermissionsAndRefresh() async {
    await _permissionService.requestPermissions();
    _refreshPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionStatus>(
      future: _permissionStatusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // İzinler kontrol edilirken kısa bir bekleme ekranı gösterilir.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          // Hata durumunda gösterilecek ekran.
          return Scaffold(
            body: Center(
              child: Text('İzinler kontrol edilirken bir hata oluştu: ${snapshot.error}'),
            ),
          );
        }

        final permissionStatus = snapshot.data!;

        // ANAHTAR DEĞİŞİKLİK: Eğer tüm izinler verilmişse, bekleme. Direkt ana ekrana geç.
        if (permissionStatus.allPermissionsGranted) {
          return widget.child; // widget.child burada DashboardScreen oluyor.
        }

        // İzinler eksikse, kullanıcıya bilgi ver ve izin isteme butonu göster.
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Uygulamanın düzgün çalışması için bazı izinlere ihtiyaç duyuyor.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      _buildPermissionList(context, permissionStatus),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        onPressed: _requestPermissionsAndRefresh,
                        child: const Text('İzinleri Ver ve Kontrol Et'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionList(BuildContext context, PermissionStatus status) {
    final permissions = {
      'Konum Servisleri': status.isLocationServiceEnabled,
      'Konum İzni': status.isLocationPermissionGranted,
      'İnternet Bağlantısı': status.isInternetConnected,
      'Bluetooth': status.isBluetoothEnabled,
      'Mikrofon Erişimi': status.isMicrophoneGranted,
      'Müzik ve Ses Erişimi': status.isAudioAccessGranted,
    };

    return Column(
      children: permissions.entries.map((entry) {
        return ListTile(
          leading: Icon(
            entry.value ? Icons.check_circle : Icons.cancel,
            color: entry.value ? Colors.green : Colors.red,
          ),
          title: Text(entry.key),
        );
      }).toList(),
    );
  }
}
