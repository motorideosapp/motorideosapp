import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Helper function to load and resize asset images for map markers to prevent crashes.
Future<Uint8List> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

class NavigationWidget extends StatefulWidget {
  final bool isFullScreen;
  final Position? currentPosition;

  const NavigationWidget({
    super.key,
    this.isFullScreen = false,
    this.currentPosition,
  });

  @override
  State<NavigationWidget> createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends State<NavigationWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  String? _mapStyle;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _customIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomIcon();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMapStyleForTheme();
  }

  @override
  void didUpdateWidget(NavigationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPosition != null &&
        widget.currentPosition != oldWidget.currentPosition) {
      _animateToPosition(widget.currentPosition!);
      // When position updates, update the marker on the map.
      setState(() {
        _updateMarkerSet(widget.currentPosition!);
      });
    }
  }

  Future<void> _updateMapStyleForTheme() async {
    if (!mounted) return;
    final theme = Theme.of(context).brightness;
    final stylePath = theme == Brightness.dark
        ? 'assets/map_styles/dark_mode.json'
        : 'assets/map_styles/light_mode.json';
    try {
      final newStyle = await rootBundle.loadString(stylePath);

      if (_mapStyle != newStyle) {
        _mapStyle = newStyle;
        if (_controller.isCompleted) {
          final controller = await _controller.future;
          await controller.setMapStyle(_mapStyle);
        }
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error loading map style: $e');
    }
  }

  Future<void> _loadCustomIcon() async {
    if (_customIcon != null) return; // Avoid reloading
    try {
      final Uint8List iconBytes = await getBytesFromAsset('assets/images/ridepin1.png', 150);
      _customIcon = BitmapDescriptor.fromBytes(iconBytes);

      // Important: After the icon is loaded, we need to update the state
      // to make sure the marker is shown if the position is already available.
      if (mounted) {
        setState(() {
          if (widget.currentPosition != null) {
            _updateMarkerSet(widget.currentPosition!);
          }
        });
      }
    } catch (e) {
      print('Error loading custom icon: $e');
    }
  }

  // This function creates/updates the marker set.
  void _updateMarkerSet(Position position) {
    if (_customIcon == null) return; // Don't do anything if the icon isn't ready
    _markers.clear();
    _markers.add(Marker(
      markerId: const MarkerId('current_location'),
      position: LatLng(position.latitude, position.longitude),
      icon: _customIcon!,
      rotation: position.heading,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      zIndex: 2,
    ));
  }

  Future<void> _animateToPosition(Position position) async {
    if (!_controller.isCompleted) return;
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 19.0,
        tilt: 45.0,
        bearing: position.heading,
      ),
    ));
  }

  void _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
    if (_mapStyle != null) {
      await controller.setMapStyle(_mapStyle);
    }
    // When the map is created, ensure marker and position are set.
    if (widget.currentPosition != null) {
      setState(() {
        _updateMarkerSet(widget.currentPosition!);
        _animateToPosition(widget.currentPosition!);
      });
    }
  }

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
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.currentPosition!.latitude,
                    widget.currentPosition!.longitude),
                zoom: 19.0,
                tilt: 45.0,
              ),
              onMapCreated: _onMapCreated,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              markers: _markers, // This now correctly passes the marker set
              zoomControlsEnabled: widget.isFullScreen,
              scrollGesturesEnabled: widget.isFullScreen,
              tiltGesturesEnabled: widget.isFullScreen,
              rotateGesturesEnabled: widget.isFullScreen,
            ),
            if (!widget.isFullScreen)
              Positioned(
                bottom: 8,
                right: 8,
                child: FloatingActionButton.small(
                  heroTag: null,
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
