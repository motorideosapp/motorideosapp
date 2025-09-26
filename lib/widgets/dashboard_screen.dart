import 'dart:async';
import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:moto_ride_os/widgets/music_player_widget.dart';
import 'package:moto_ride_os/widgets/navigation_widget.dart';
import 'package:moto_ride_os/widgets/notifications_widget.dart';
import 'package:moto_ride_os/widgets/speedometer_widget.dart';
import 'package:moto_ride_os/widgets/weather_widget.dart';
import 'package:moto_ride_os/services/weather_service.dart';
import 'package:telephony/telephony.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- STATE DEĞİŞKENLERİ ---
  bool _showRecentCalls = false;
  Iterable<CallLogEntry> _callLogEntries = [];

  bool _showRecentMessages = false;
  List<SmsMessage> _messages = [];
  final Telephony telephony = Telephony.instance;

  bool _isMapFullScreen = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  double _currentSpeed = 0.0;
  Map<String, dynamic> _weatherData = {};
  bool _isWeatherLoading = true;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  void _initializeDashboard() {
    _setOrientation();
    _startListeningToSpeed();
    _fetchWeatherData();
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
  }

  void _fetchWeatherData() async {
    setState(() => _isWeatherLoading = true);
    final data = await _weatherService.getWeatherData();
    if (mounted) {
      setState(() {
        _weatherData = data;
        _isWeatherLoading = false;
      });
    }
  }

  Future<void> _startListeningToSpeed() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() => _currentSpeed = position.speed * 3.6);
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

  void _toggleMapFullScreen() {
    setState(() => _isMapFullScreen = !_isMapFullScreen);
  }

  void _toggleRecentCalls() async {
    if (_showRecentMessages) await _toggleRecentMessages(forceClose: true);

    if (!_showRecentCalls) {
      final hasPermission = await telephony.requestPhoneAndSmsPermissions ?? false;
      if (!hasPermission || !mounted) return;

      final Iterable<CallLogEntry> entries = await CallLog.get();
      if (!mounted) return;

      setState(() {
        _callLogEntries = entries;
        _showRecentCalls = true;
      });
    } else {
      setState(() => _showRecentCalls = false);
    }
  }

  Future<void> _toggleRecentMessages({bool forceClose = false}) async {
    if (_showRecentCalls) _toggleRecentCalls();

    if (!_showRecentMessages && !forceClose) {
      final hasPermission = await telephony.requestSmsPermissions ?? false;
      if (!hasPermission || !mounted) return;

      final List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
      if (!mounted) return;

      setState(() {
        _messages = messages;
        _showRecentMessages = true;
      });
    } else {
      setState(() => _showRecentMessages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [Color(0xFF2a2a2e), Color(0xFF1c1c1e)],
            stops: [0.0, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isMapFullScreen
                      ? _buildFullScreenMap(key: const ValueKey('map'))
                      : _buildDashboardLayout(key: const ValueKey('dashboard')),
                ),
                _buildRecentCallsPanel(constraints),
                _buildRecentMessagesPanel(constraints),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardLayout({Key? key}) {
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        return _DashboardLayout(
          constraints: constraints,
          currentSpeed: _currentSpeed,
          isWeatherLoading: _isWeatherLoading,
          weatherData: _weatherData,
          onMapTap: _toggleMapFullScreen,
          onPhoneTap: _toggleRecentCalls,
          onMessageTap: () => _toggleRecentMessages(),
        );
      },
    );
  }

  Widget _buildFullScreenMap({Key? key}) {
    return SafeArea(
      key: key,
      child: Stack(
        children: [
          const Positioned.fill(
            child: NavigationWidget(isFullScreen: true),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _toggleMapFullScreen,
              backgroundColor: Colors.black.withOpacity(0.6),
              foregroundColor: Colors.white,
              child: const Icon(Icons.close_fullscreen_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCallsPanel(BoxConstraints constraints) {
    const double panelHeight = 300;
    const double panelWidth = 260;
    const double padding = 16.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _showRecentCalls ? (constraints.maxHeight - panelHeight) / 2 : constraints.maxHeight,
      right: padding,
      width: panelWidth,
      height: panelHeight,
      child: Container(
        decoration: BoxDecoration( /* ... (içerik aynı) ... */ ),
        child: Column( /* ... (içerik aynı) ... */ ),
      ),
    );
  }

  Widget _buildRecentMessagesPanel(BoxConstraints constraints) {
    const double panelHeight = 300;
    const double panelWidth = 260;
    const double padding = 16.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _showRecentMessages ? (constraints.maxHeight - panelHeight) / 2 : constraints.maxHeight,
      right: padding,
      width: panelWidth,
      height: panelHeight,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF212124).withOpacity(0.98),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
          boxShadow: [ BoxShadow(color: Colors.cyanAccent.withOpacity(0.15), blurRadius: 20.0) ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Son Mesajlar', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => _toggleRecentMessages(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(child: Text('Mesaj bulunamadı.', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                itemCount: _messages.length > 5 ? 5 : _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages.elementAt(index);
                  return ListTile(
                    title: Text(message.address ?? 'Bilinmeyen', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(message.body ?? '', style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      print("Mesaj okunacak: ${message.body}");
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCallTypeIcon(CallType? callType) { /* ... (içerik aynı) ... */ }
}

class _DashboardLayout extends StatelessWidget {
  final VoidCallback onMessageTap;

  const _DashboardLayout({
    // ... diğer parametreler ...
    required this.onMessageTap,
    super.key,
    required BoxConstraints constraints,
    required double currentSpeed,
    required bool isWeatherLoading,
    required Map<String, dynamic> weatherData,
    required VoidCallback onMapTap,
    required VoidCallback onPhoneTap,
  });

  // ... diğer değişkenler ...

  @override
  Widget build(BuildContext context) {
    // ... layout mantığı aynı ...
    return SafeArea(
      child: Stack(
        children: [
          // ... diğer Positioned widget'ları ...
          Positioned(
              top: 16.0,
              right: 16.0,
              child: SizedBox(
                  width: 230,
                  height: 90,
                  child: NotificationsWidget(
                    onPhoneTap: (){}, // onPhoneTap,
                    onMessageTap: onMessageTap,
                  ))),
          // ... diğer Positioned widget'ları ...
        ],
      ),
    );
  }
}