import 'package:flutter/material.dart';
import 'package:moto_ride_os/services/permission_service.dart';
import 'package:moto_ride_os/models/permission_status.dart';

class PermissionsCheckScreen extends StatefulWidget {
  final Widget child;
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Text('İzinler kontrol edilirken bir hata oluştu: ${snapshot.error}'),
            ),
          );
        }

        final permissionStatus = snapshot.data!;

        // Temel izinler verilmişse ana ekranı göster.
        // "Diğer uygulamalar üzerinde gösterme" izni olmasa bile uygulama açılır.
        if (permissionStatus.allPermissionsGranted) {
          return Stack(
            children: [
              widget.child, // Ana içerik (DashboardScreen)
              // Eğer "Diğer uygulamalar üzerinde gösterme" izni verilmemişse uyarı göster.
              if (!permissionStatus.isSystemAlertWindowGranted)
                _buildSystemAlertWindowPermissionOverlay(),
            ],
          );
        }

        // Temel izinler eksikse, izin isteme ekranını göster.
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

  // "Diğer uygulamalar üzerinde gösterme" izni için uyarı katmanı
  Widget _buildSystemAlertWindowPermissionOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber, color: Colors.yellow, size: 80),
              const SizedBox(height: 24),
              Text(
                'Önemli İzin Gerekli',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Uygulamanın arama ekranı gibi önemli özellikleri diğer uygulamaların üzerinde gösterebilmesi için bu izni vermeniz gerekiyor.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                ),
                onPressed: _requestPermissionsAndRefresh,
                child: const Text('Ayarlara Git ve İzin Ver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // İzin listesini oluşturan widget
  Widget _buildPermissionList(BuildContext context, PermissionStatus status) {
    final permissions = {
      'Konum Servisleri': status.isLocationServiceEnabled,
      'Konum İzni': status.isLocationPermissionGranted,
      'İnternet Bağlantısı': status.isInternetConnected,
      'Mikrofon Erişimi': status.isMicrophoneGranted,
      'Müzik ve Ses Erişimi': status.isAudioAccessGranted,
      'Diğer Uygulamaların Üzerinde Göster': status.isSystemAlertWindowGranted,
    };

    return Column(
      children: permissions.entries.map((entry) {
        final isGranted = entry.value;
        return ListTile(
          leading: Icon(
            isGranted ? Icons.check_circle : Icons.cancel,
            color: isGranted ? Colors.green : Colors.red,
          ),
          title: Text(entry.key),
          subtitle: !isGranted && entry.key == 'Diğer Uygulamaların Üzerinde Göster'
              ? const Text(
                  "Arama ekranı için kritik önemde. Yönlendirileceğiniz listede 'Moto Ride OS' uygulamasını bulup izni etkinleştirmeniz gerekir.",
                  style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic),
                )
              : null,
        );
      }).toList(),
    );
  }
}
