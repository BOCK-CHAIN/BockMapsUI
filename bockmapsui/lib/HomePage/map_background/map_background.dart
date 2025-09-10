import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapBackground extends StatefulWidget {
  final LatLng? targetLocation; // Place selected by user
  final List<LatLng> routePoints; // Route points from OSRM
  const MapBackground({
    super.key,
    this.targetLocation,
    this.routePoints = const [],
  });

  @override
  State<MapBackground> createState() => _MapBackgroundState();
}

class _MapBackgroundState extends State<MapBackground> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void didUpdateWidget(covariant MapBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetLocation != null &&
        widget.targetLocation != oldWidget.targetLocation) {
      _mapController.move(widget.targetLocation!, 15.0);
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_currentLocation!, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    const LatLng fallbackCenter = LatLng(15.3173, 75.7139);

    LatLng? routeStart =
        widget.routePoints.isNotEmpty ? widget.routePoints.first : null;
    LatLng? routeEnd =
        widget.routePoints.isNotEmpty ? widget.routePoints.last : null;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: fallbackCenter,
            initialZoom: 7.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'http://34.100.203.205:8080/styles/basic-preview/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.my_map_app',
            ),
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 20,
                    height: 20,
                    child: _buildMarker(Colors.blue), // Your original style
                  ),
                ],
              ),
            if (widget.targetLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.targetLocation!,
                    width: 20,
                    height: 20,
                    child: _buildMarker(Colors.red), // Your original style
                  ),
                ],
              ),
            if (routeStart != null || routeEnd != null)
              MarkerLayer(
                markers: [
                  if (routeStart != null)
                    Marker(
                      point: routeStart,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  if (routeEnd != null &&
                      (widget.targetLocation == null ||
                          (widget.targetLocation!.latitude != routeEnd.latitude &&
                              widget.targetLocation!.longitude != routeEnd.longitude)))
                    Marker(
                      point: routeEnd,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            PolylineLayer(
              polylines: [
                if (widget.routePoints.isNotEmpty)
                  Polyline(
                    points: widget.routePoints,
                    strokeWidth: 6.0,
                    color: Colors.blue,
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _determinePosition,
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildMarker(Color color) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: color,
      ),
      width: 10,
      height: 10,
    );
  }
}
