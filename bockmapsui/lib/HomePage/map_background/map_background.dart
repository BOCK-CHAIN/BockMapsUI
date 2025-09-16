import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapBackground extends StatefulWidget {
  final LatLng?
  targetLocation; // place selected by user (keeps existing behaviour)
  final List<LatLng> routePoints; // route polyline points from OSRM (optional)
  final Map<String, dynamic>? routeDetails;

  const MapBackground({
    super.key,
    this.targetLocation,
    this.routePoints = const [],
    this.routeDetails,
  });

  @override
  State<MapBackground> createState() => _MapBackgroundState();
}

class _MapBackgroundState extends State<MapBackground> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();

  // zoom clamp values (adjust if you need deeper zoom)
  static const double _minZoom = 3.0;
  static const double _maxZoom = 18.0;
  static const double _tileSize = 256.0;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    // if initial routePoints exist, schedule fit after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.routePoints.isNotEmpty) {
        _fitRouteBounds(); // will compute using MediaQuery (available after frame)
      } else if (widget.targetLocation != null && _currentLocation == null) {
        // optionally center on target once frame is ready (keeps current behaviour)
        _mapController.move(widget.targetLocation!, 15.0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MapBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the targetLocation changed, keep the old behavior (center on it)
    if (widget.targetLocation != null &&
        widget.targetLocation != oldWidget.targetLocation &&
        (widget.routePoints.isEmpty)) {
      // Only move to target if there's no route overriding the view
      _mapController.move(widget.targetLocation!, 15.0);
    }

    // If routePoints changed (new route) fit to it
    if (widget.routePoints != oldWidget.routePoints &&
        widget.routePoints.isNotEmpty) {
      // run after build so MediaQuery & map size are available
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRouteBounds());
    }
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      // If there is no active route, center on current loc
      if (widget.routePoints.isEmpty && widget.targetLocation == null) {
        _mapController.move(_currentLocation!, 15.0);
      }
    } catch (_) {
      // ignore location errors for now
    }
  }

  /// Fit map to show full route (widget.routePoints).
  /// Uses viewport dimensions to calculate a zoom that fits the bounding box.
  void _fitRouteBounds() {
    final pts = widget.routePoints;
    if (pts.isEmpty) return;

    // compute bbox
    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // handle dateline crossing (rudimentary)
    double lonSpan = maxLng - minLng;
    if (lonSpan.abs() > 180) {
      // route crosses antimeridian: normalize longitudes into [-180, 180] then recompute
      final normalized = pts.map((p) {
        var lon = p.longitude;
        if (lon > 180) lon -= 360;
        return LatLng(p.latitude, lon);
      }).toList();
      minLng = normalized.map((p) => p.longitude).reduce(math.min);
      maxLng = normalized.map((p) => p.longitude).reduce(math.max);
      lonSpan = maxLng - minLng;
    }

    final centerLat = (minLat + maxLat) / 2.0;
    final centerLng = (minLng + maxLng) / 2.0;
    final center = LatLng(centerLat, centerLng);

    // viewport size
    final size = MediaQuery.of(context).size;
    final padding = 40.0; // px padding on both sides
    final viewWidth = (size.width - padding * 2).clamp(50.0, size.width);
    final viewHeight = (size.height - padding * 2).clamp(50.0, size.height);

    // lon span in degrees
    double lonDiff = (maxLng - minLng).abs();
    if (lonDiff == 0) lonDiff = 0.00001; // avoid divide by zero

    // latitude uses mercator projection
    double _latToMercator(double lat) {
      final rad = lat * math.pi / 180.0;
      return math.log(math.tan(math.pi / 4.0 + rad / 2.0));
    }

    final mercatorMin = _latToMercator(minLat);
    final mercatorMax = _latToMercator(maxLat);
    double latFraction = (mercatorMax - mercatorMin).abs() / (2.0 * math.pi);
    if (latFraction == 0) latFraction = 0.00001; // avoid divide by zero

    // compute zoom for both axes
    double zoomForLon =
        math.log(viewWidth * 360.0 / (_tileSize * lonDiff)) / math.log(2);
    double zoomForLat =
        math.log(viewHeight / (_tileSize * latFraction)) / math.log(2);

    double targetZoom = math.min(zoomForLat, zoomForLon);

    // clamp zoom
    if (targetZoom.isInfinite || targetZoom.isNaN) {
      targetZoom = (_maxZoom + _minZoom) / 2;
    }
    targetZoom = targetZoom.clamp(_minZoom, _maxZoom);

    // move the map
    _mapController.move(center, targetZoom);
  }

  @override
  Widget build(BuildContext context) {
    const LatLng fallbackCenter = LatLng(15.3173, 75.7139);

    // derive route endpoints (for distinct markers if requested)
    final LatLng? routeStart = widget.routePoints.isNotEmpty
        ? widget.routePoints.first
        : null;
    final LatLng? routeEnd = widget.routePoints.isNotEmpty
        ? widget.routePoints.last
        : null;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            // initial center - will be overridden by move() when available
            initialCenter: fallbackCenter,
            initialZoom: 7.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'http://34.100.203.205:8080/styles/basic-preview/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.my_map_app',
            ),

            // current device location (blue)
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 28,
                    height: 28,
                    child: _buildMarker(Colors.blue),
                  ),
                ],
              ),

            // original targetLocation marker (red) — unchanged from your old behaviour
            if (widget.targetLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.targetLocation!,
                    width: 28,
                    height: 28,
                    child: _buildMarker(Colors.red),
                  ),
                ],
              ),

            // route start/end markers (distinct icons) — only when routePoints present
            if (routeStart != null || routeEnd != null)
              MarkerLayer(
                markers: [
                  if (routeStart != null)
                    Marker(
                      point: routeStart,
                      width: 34,
                      height: 34,
                      child: _buildStartIcon(),
                    ),
                  if (routeEnd != null &&
                      (widget.targetLocation == null ||
                          (widget.targetLocation!.latitude !=
                                  routeEnd.latitude ||
                              widget.targetLocation!.longitude !=
                                  routeEnd.longitude)))
                    Marker(
                      point: routeEnd,
                      width: 34,
                      height: 34,
                      child: _buildEndIcon(),
                    ),
                ],
              ),

            // route polyline (blue, thicker)
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
        if (widget.routeDetails != null)
  Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Main distance & duration row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(widget.routeDetails!['distance'] / 1000).toStringAsFixed(1)} km",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
              ],
            ),
            const SizedBox(height: 12),

            const Divider(),

            // --- Transport options like Google Maps ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.blue, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      "${(widget.routeDetails!['distance'] / 1000 / 40 * 60).toStringAsFixed(0)} min",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.motorcycle, color: Colors.green, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      "${(widget.routeDetails!['distance'] / 1000 / 30 * 60).toStringAsFixed(0)} min",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.directions_walk, color: Colors.orange, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      "${(widget.routeDetails!['distance'] / 1000 / 5 * 60).toStringAsFixed(0)} min",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),

      ],
    );
  }

  Widget _buildMarker(Color color) {
    // original small circular marker used for current and target locations
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: color,
      ),
      width: 14,
      height: 14,
    );
  }

  Widget _buildStartIcon() {
    // bigger distinct start icon (green pin-like)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: const Icon(Icons.circle, color: Colors.green, size: 20),
    );
  }

  Widget _buildEndIcon() {
    // distinct destination icon (flag)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: const Icon(Icons.flag, color: Colors.red, size: 20),
    );
  }
}
