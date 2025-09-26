
import 'package:flutter/material.dart';
import 'package:moto_ride_os/models/permission_status.dart' as app_status;
import 'package:moto_ride_os/screens/dashboard_screen.dart';
import 'package:moto_ride_os/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Represents a rule for checking a specific permission.
class PermissionRule {
  /// A function that returns true if the permission is not granted.
  final bool Function(app_status.PermissionStatus) isViolated;

  /// The error UI to display if the permission is not granted.
  final Widget Function(VoidCallback, VoidCallback) errorUIBuilder;

  PermissionRule({required this.isViolated, required this.errorUIBuilder});
}

class PermissionsCheckScreen extends StatefulWidget {
  const PermissionsCheckScreen({super.key});

  @override
  State<PermissionsCheckScreen> createState() => _PermissionsCheckScreenState();
}

class _PermissionsCheckScreenState extends State<PermissionsCheckScreen> {
  final PermissionService _permissionService = PermissionService();
  app_status.PermissionStatus? _status;
  List<PermissionRule> _permissionRules = [];

  @override
  void initState() {
    super.initState();
    _initializeRules();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermissionsAndNavigate());
  }

  /// Initializes the list of permission rules.
  void _initializeRules() {
    _permissionRules = [
      PermissionRule(
        isViolated: (status) => !status.isLocationServiceEnabled,
        errorUIBuilder: (onPressed, onRetry) => _buildErrorUI(
          icon: Icons.location_disabled_rounded,
          message: "Hız ve navigasyon özellikleri için lütfen cihazınızın konum servislerini açın.",
          buttonText: "Konum Servislerini Aç",
          onPressed: onPressed,
          onRetry: onRetry,
        ),
      ),
      PermissionRule(
        isViolated: (status) => !status.isBluetoothEnabled,
        errorUIBuilder: (onPressed, onRetry) => _buildErrorUI(
          icon: Icons.bluetooth_disabled_rounded,
          message: "İnterkom ve diğer cihazlara bağlanabilmek için Bluetooth izni gereklidir.",
          buttonText: "İzin Ayarlarını Aç",
          onPressed: onPressed,
          onRetry: onRetry,
        ),
      ),
      PermissionRule(
        isViolated: (status) => !status.isMicrophoneGranted,
        errorUIBuilder: (onPressed, onRetry) => _buildErrorUI(
          icon: Icons.mic_off_rounded,
          message: "Sesli komutlar ve telefon görüşmeleri için mikrofon izni gereklidir.",
          buttonText: "İzin Ayarlarını Aç",
          onPressed: onPressed,
          onRetry: onRetry,
        ),
      ),
      PermissionRule(
        isViolated: (status) => !status.isAudioAccessGranted,
        errorUIBuilder: (onPressed, onRetry) => _buildErrorUI(
          icon: Icons.music_off_rounded,
          message: "Cihazınızdaki müziklere erişebilmek için depolama izni gereklidir.",
          buttonText: "İzin Ayarlarını Aç",
          onPressed: onPressed,
          onRetry: onRetry,
        ),
      ),
      PermissionRule(
        isViolated: (status) => !status.isInternetConnected,
        errorUIBuilder: (_, onRetry) => _buildErrorUI(
          icon: Icons.wifi_off_rounded,
          message: "Harita ve diğer çevrimiçi servisler için internet bağlantısı gereklidir.",
          buttonText: "Tekrar Dene",
          onPressed: onRetry, // For internet, main action is to retry.
          showRetryButton: false, // No need for a separate retry button.
        ),
      ),
    ];
  }

  /// Checks permissions and navigates to the dashboard if all are granted.
  Future<void> _checkPermissionsAndNavigate() async {
    if (!mounted) return;

    // Show loading indicator while checking.
    setState(() {
      _status = null;
    });

    final initialStatus = await _permissionService.checkPermissions();
    if (initialStatus.allPermissionsGranted) {
      _navigateToDashboard();
      return;
    }

    // If permissions are missing, request them.
    await _permissionService.requestPermissions();
    final finalStatus = await _permissionService.checkPermissions();

    if (mounted) {
      if (finalStatus.allPermissionsGranted) {
        _navigateToDashboard();
      } else {
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

  /// Builds the main body of the screen based on the current permission status.
  Widget _buildBody() {
    if (_status == null) {
      return _buildLoadingUI();
    }

    // Find the first permission rule that is violated.
    final violatedRule = _permissionRules.firstWhere(
      (rule) => rule.isViolated(_status!),
      orElse: () => PermissionRule(
        isViolated: (_) => true,
        errorUIBuilder: (_, __) => _buildLoadingUI(), // Fallback to loading
      ),
    );

    return violatedRule.errorUIBuilder(() async => await openAppSettings(), _checkPermissionsAndNavigate);
  }

  /// Builds the loading indicator UI.
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

  /// Builds the generic error UI for a missing permission.
  Widget _buildErrorUI({
    required IconData icon,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
    VoidCallback? onRetry,
    bool showRetryButton = true,
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
          if (showRetryButton && onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton(
              child: const Text("Tekrar Dene", style: TextStyle(color: Colors.white70)),
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
