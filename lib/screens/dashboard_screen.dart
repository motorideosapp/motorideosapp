
import 'dart:async';
import 'dart:collection';
import 'package:call_log/call_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moto_ride_os/main.dart';
import 'package:moto_ride_os/widgets/music/music_library_panel.dart';
import 'package:moto_ride_os/widgets/music_player_widget.dart';
import 'package:moto_ride_os/widgets/navigation_widget.dart';
import 'package:moto_ride_os/widgets/notifications_widget.dart';
import 'package:moto_ride_os/widgets/speedometer_widget.dart';
import 'package:moto_ride_os/widgets/theme_switcher.dart';
import 'package:moto_ride_os/widgets/weather_widget.dart';
import 'package:moto_ride_os/services/weather_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showRecentCalls = false;
  bool _showMusicLibrary = false;
  bool _showDialpad = false;
  bool _isMapFullScreen = false;

  Iterable<CallLogEntry> _callLogEntries = [];
  String _dialedNumber = "";

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  double _currentSpeed = 0.0;
  final Queue<double> _speedReadings = Queue<double>();
  static const int _speedBufferSize = 5;

  Map<String, dynamic> _weatherData = {};
  bool _isWeatherLoading = true;
  late WeatherService _weatherService;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
    WakelockPlus.enable();
  }

  Future<void> _loadApiKey() async {
    final String configString = await rootBundle.loadString('assets/config.json');
    final Map<String, dynamic> config = json.decode(configString);
    setState(() {
      _apiKey = config['apiKey'];
    });
  }

  void _initializeDashboard() async {
    await _loadApiKey();
    _weatherService = WeatherService(_apiKey!);
    _setOrientation();
    _startLocationServices();
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

  Future<void> _startLocationServices() async {
    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        forceLocationManager: true,
        intervalDuration: const Duration(milliseconds: 500),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              "Moto Ride OS is using your location for speed tracking",
          notificationTitle: "Location Active",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }

    try {
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        if (mounted) {
          final speedInKmh = position.speed * 3.6;

          if (_speedReadings.length == _speedBufferSize) {
            _speedReadings.removeFirst();
          }
          _speedReadings.add(speedInKmh);

          final smoothedSpeed =
              _speedReadings.reduce((a, b) => a + b) / _speedReadings.length;

          setState(() {
            _currentPosition = position;
            _currentSpeed = smoothedSpeed;
          });
        }
      });

      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      if (mounted) {
        setState(() {
          _currentPosition = initialPosition;
        });
      }
    } catch (e) {
      print("Konum Servisi hatası (DashboardScreen): $e");
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

  void _closeAllPanels() {
    setState(() {
      if (_showRecentCalls) _showRecentCalls = false;
      if (_showDialpad) _showDialpad = false;
      if (_showMusicLibrary) _showMusicLibrary = false;
    });
  }

  void _toggleMapFullScreen() {
    setState(() => _isMapFullScreen = !_isMapFullScreen);
  }

  void _toggleMusicLibrary() {
    final bool wasOpen = _showMusicLibrary;
    _closeAllPanels();
    if (!wasOpen) {
      setState(() => _showMusicLibrary = true);
    }
  }

  void _toggleRecentCalls() async {
    final bool wasOpen = _showRecentCalls;
    _closeAllPanels();
    if (wasOpen) return;

    final Iterable<CallLogEntry> allEntries = await CallLog.get();
    if (!mounted) return;
    final uniqueEntries = <String, CallLogEntry>{};
    for (var entry in allEntries) {
      final key = entry.name ?? entry.formattedNumber;
      if (key != null && key.isNotEmpty && !uniqueEntries.containsKey(key)) {
        uniqueEntries[key] = entry;
      }
    }
    setState(() {
      _callLogEntries = uniqueEntries.values;
      _showRecentCalls = true;
    });
  }

  void _toggleDialpad() {
    final bool wasOpen = _showDialpad;
    _closeAllPanels();
    if (!wasOpen) {
      setState(() {
        _showDialpad = true;
        _dialedNumber = "";
      });
    }
  }

  void _onDialpadButtonPressed(String value) {
    if (value == "backspace") {
      if (_dialedNumber.isNotEmpty) {
        setState(() =>
            _dialedNumber = _dialedNumber.substring(0, _dialedNumber.length - 1));
      }
    } else if (_dialedNumber.length < 15) {
      setState(() => _dialedNumber += value);
    }
  }

  void _callDialedNumber() async {
    if (_dialedNumber.isNotEmpty) {
      final Uri url = Uri(scheme: 'tel', path: _dialedNumber);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        print('Arama başlatılamadı: $_dialedNumber');
      }
      _toggleDialpad();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_apiKey == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isMapFullScreen
                      ? _buildFullScreenMap(key: const ValueKey('map'))
                      : _buildDashboardLayout(
                          key: const ValueKey('dashboard')),
                ),
                _buildRecentCallsPanel(constraints),
                _buildDialpadPanel(constraints),
                _buildMusicLibraryPanel(constraints),
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
          currentPosition: _currentPosition,
          isWeatherLoading: _isWeatherLoading,
          weatherData: _weatherData,
          onMapTap: _toggleMapFullScreen,
          onPhoneTap: _toggleRecentCalls,
          onDialpadTap: _toggleDialpad,
          onMusicTap: _toggleMusicLibrary,
        );
      },
    );
  }

  Widget _buildMusicLibraryPanel(BoxConstraints constraints) {
    const double padding = 16.0;
    final double panelWidth = constraints.maxWidth * 0.28;
    final double panelHeight = constraints.maxHeight - (padding * 2);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: padding,
      right: _showMusicLibrary ? padding : -(panelWidth + padding * 2),
      width: panelWidth,
      height: panelHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              blurRadius: 25.0,
            )
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Müzik Arşivi',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: Theme.of(context).iconTheme.color),
                    onPressed: _toggleMusicLibrary,
                  ),
                ],
              ),
            ),
            const Expanded(
              child: MusicLibraryPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenMap({Key? key}) {
    return SafeArea(
      key: key,
      child: Stack(
        children: [
          Positioned.fill(
            child: NavigationWidget(
              isFullScreen: true,
              currentPosition: _currentPosition,
            ),
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
    const double padding = 16.0;
    final double panelWidth = constraints.maxWidth * 0.28;
    final double panelHeight = constraints.maxHeight - (padding * 2);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _showRecentCalls ? padding : constraints.maxHeight,
      right: padding,
      width: panelWidth,
      height: panelHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              blurRadius: 25.0,
            )
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Son Aramalar',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: Theme.of(context).iconTheme.color),
                    onPressed: _toggleRecentCalls,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _callLogEntries.isEmpty
                  ? Center(
                      child: Text('Arama kaydı bulunamadı.',
                          style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                      itemCount: _callLogEntries.length > 5
                          ? 5
                          : _callLogEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _callLogEntries.elementAt(index);
                        return ListTile(
                          leading: Icon(_getCallTypeIcon(entry.callType),
                              color: Theme.of(context).iconTheme.color),
                          title: Text(
                            entry.name ?? entry.formattedNumber ?? 'Bilinmeyen',
                            style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () async {
                            if (entry.number != null) {
                              final Uri url =
                                  Uri(scheme: 'tel', path: entry.number);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                              _toggleRecentCalls();
                            }
                          },
                        );
                      },
                    ),
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      icon: Icon(Icons.contacts_rounded,
                          color: Theme.of(context).iconTheme.color, size: 32),
                      onPressed: () async {
                        final Uri url =
                            Uri(scheme: 'content', path: 'contacts/people');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          print('Kişiler uygulaması açılamadı.');
                        }
                      }),
                  IconButton(
                    icon: Icon(Icons.dialpad_rounded,
                        color: Theme.of(context).iconTheme.color, size: 32),
                    onPressed: _toggleDialpad,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDialpadPanel(BoxConstraints constraints) {
    const double padding = 16.0;
    final double panelWidth = constraints.maxWidth * 0.28;
    final double panelHeight = constraints.maxHeight - (padding * 2);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _showDialpad ? padding : constraints.maxHeight,
      right: padding,
      width: panelWidth,
      height: panelHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              blurRadius: 25.0,
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              child: Text(
                  _dialedNumber.isEmpty ? "Numara Girin" : _dialedNumber,
                  style: TextStyle(
                      color: _dialedNumber.isEmpty
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  ...[
                    '1',
                    '2',
                    '3',
                    '4',
                    '5',
                    '6',
                    '7',
                    '8',
                    '9',
                    '*',
                    '0',
                    '#'
                  ]
                      .map((e) =>
                          _buildDialButton(e, () => _onDialpadButtonPressed(e)))
                      .toList(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      icon: const Icon(Icons.cancel_rounded,
                          color: Colors.redAccent, size: 32),
                      onPressed: _toggleDialpad),
                  FloatingActionButton(
                    onPressed: _callDialedNumber,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.call, color: Colors.white),
                  ),
                  IconButton(
                      icon: Icon(Icons.backspace_rounded,
                          color: Theme.of(context).iconTheme.color, size: 32),
                      onPressed: () => _onDialpadButtonPressed("backspace"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Center(
        child: Text(text,
            style: TextStyle(
                fontSize: 28,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w400)),
      ),
    );
  }

  IconData _getCallTypeIcon(CallType? callType) {
    switch (callType) {
      case CallType.incoming:
        return Icons.call_received_rounded;
      case CallType.outgoing:
        return Icons.call_made_rounded;
      case CallType.missed:
        return Icons.call_missed_rounded;
      default:
        return Icons.phone_rounded;
    }
  }
}

class _DashboardLayout extends StatelessWidget {
  final BoxConstraints constraints;
  final double currentSpeed;
  final Position? currentPosition;
  final bool isWeatherLoading;
  final Map<String, dynamic> weatherData;
  final VoidCallback onMapTap;
  final VoidCallback onPhoneTap;
  final VoidCallback onDialpadTap;
  final VoidCallback onMusicTap;

  const _DashboardLayout({
    super.key,
    required this.constraints,
    required this.currentSpeed,
    required this.currentPosition,
    required this.isWeatherLoading,
    required this.weatherData,
    required this.onMapTap,
    required this.onPhoneTap,
    required this.onDialpadTap,
    required this.onMusicTap,
  });

  @override
  Widget build(BuildContext context) {
    const double padding = 16.0;
    final double speedometerSize = constraints.maxHeight * 0.7;

    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -1.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: speedometerSize,
                  height: speedometerSize,
                  child: SpeedometerWidget(speed: currentSpeed),
                ),
                Positioned(
                  bottom: -5,
                  child: WeatherWidget(
                    isLoading: isWeatherLoading,
                    temperature: weatherData['temperature'] ?? '--',
                    condition: weatherData['condition'] ?? 'Loading...',
                    weatherIcon: weatherData['weatherIcon'] ?? Icons.cloud_off,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: padding,
            bottom: padding,
            left: padding,
            child: GestureDetector(
              onTap: onMapTap,
              child: SizedBox(
                width: constraints.maxWidth * 0.28,
                child: AbsorbPointer(
                  absorbing: true,
                  child: NavigationWidget(
                    isFullScreen: false,
                    currentPosition: currentPosition,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: padding,
            right: padding,
            child: SizedBox(
              width: constraints.maxWidth * 0.28,
              height: 90,
              child: NotificationsWidget(
                onPhoneTap: onPhoneTap,
                onMessageTap: () {
                  print("Mesaj butonu tıklandı");
                },
                onDialpadTap: onDialpadTap,
              ),
            ),
          ),
          Positioned(
            top: padding,
            right: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const ThemeSwitcher(),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onMusicTap,
                  child: const MusicPlayerWidget(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
