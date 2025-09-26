import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationWidget extends StatefulWidget {
  final bool isFullScreen;
  final Position? currentPosition; // Dışarıdan gelen konum verisi

  const NavigationWidget({
    super.key,
    this.isFullScreen = false,
    this.currentPosition, // Constructor'a eklendi
  });

  @override
  State<NavigationWidget> createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends State<NavigationWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  String? _mapStyle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMapStyle();
  }

  // Widget güncellendiğinde (yeni konum geldiğinde) tetiklenir
  @override
  void didUpdateWidget(NavigationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Eğer yeni bir konum geldiyse ve eskisinden farklıysa haritayı güncelle
    if (widget.currentPosition != null &&
        widget.currentPosition != oldWidget.currentPosition) {
      _animateToPosition(widget.currentPosition!);
    }
  }

  Future<void> _loadMapStyle() async {
    final theme = Theme.of(context).brightness;
    final stylePath = theme == Brightness.dark
        ? 'assets/map_styles/dark_mode.json'
        : 'assets/map_styles/light_mode.json';
    try {
      _mapStyle = await rootBundle.loadString(stylePath);
    } catch (e) {
      // Handle error
      print('Error loading map style: $e');
    }

    if (_controller.isCompleted) {
      final controller = await _controller.future;
      await controller.setMapStyle(_mapStyle);
    }
  }

  // Haritayı verilen konuma animasyonla götüren metod
  Future<void> _animateToPosition(Position position) async {
    if (!_controller.isCompleted) return;
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16.5, // Daha yakın bir zoom seviyesi
        tilt: 30.0, // Biraz eğim
      ),
    ));
  }

  // "Benim Konumum" butonu için metod
  void _recenterMap() {
    if (widget.currentPosition != null) {
      _animateToPosition(widget.currentPosition!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.35)
            : Colors.white.withOpacity(0.8),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(
            color: isDarkMode
                ? Colors.cyanAccent.withOpacity(0.3)
                : Colors.blue.withOpacity(0.5),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.cyanAccent.withOpacity(0.1)
                : Colors.blue.withOpacity(0.2),
            blurRadius: 10.0,
            spreadRadius: 2.0,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.isFullScreen ? 0.0 : 18.0),
        // Konum bilgisi gelene kadar yükleniyor animasyonu göster
        child: widget.currentPosition == null
            ? Center(
                child: CircularProgressIndicator(
                  color: isDarkMode ? Colors.cyanAccent : Colors.blue,
                  strokeWidth: 2.0,
                ),
              )
            : Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    // İlk pozisyonu gelen konum verisinden al
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.currentPosition!.latitude,
                          widget.currentPosition!.longitude),
                      zoom: 16.5,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                      // Harita oluşturulduğunda stil dosyasını uygula
                      if (_mapStyle != null) {
                        controller.setMapStyle(_mapStyle);
                      }
                    },
                    myLocationEnabled: true, // Mavi noktayı gösterir
                    myLocationButtonEnabled: false, // Varsayılan butonu gizle
                    zoomControlsEnabled: widget.isFullScreen,
                    scrollGesturesEnabled: widget.isFullScreen,
                    tiltGesturesEnabled: widget.isFullScreen,
                    rotateGesturesEnabled: widget.isFullScreen,
                  ),
                  // Sadece tam ekran değilken yeniden ortalama butonunu göster
                  if (!widget.isFullScreen)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: FloatingActionButton.small(
                        heroTag: null, // Hero animasyon çakışmasını önler
                        onPressed: _recenterMap,
                        backgroundColor: isDarkMode
                            ? Colors.black.withOpacity(0.6)
                            : Colors.white.withOpacity(0.8),
                        foregroundColor:
                            isDarkMode ? Colors.white : Colors.black,
                        child: const Icon(Icons.my_location, size: 20),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
