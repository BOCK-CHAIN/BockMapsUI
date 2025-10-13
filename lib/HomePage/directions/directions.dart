import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class DirectionsPage extends StatefulWidget {
  final Map<String, dynamic>? initialDestination;
  final Function(List<LatLng>, Map<String, dynamic>)? onRouteFound;
  final VoidCallback? onClose;

  const DirectionsPage({
    Key? key,
    this.initialDestination,
    this.onRouteFound,
    this.onClose,
  }) : super(key: key);

  @override
  State<DirectionsPage> createState() => _DirectionsPageState();
}

class _DirectionsPageState extends State<DirectionsPage> {
  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();
  final String osrmurl= dotenv.env['OSRM_URL'] ?? '';
  final String nominatimurl= dotenv.env['NOMINATIM_URL'] ?? '';
  LatLng? _startLoc;
  LatLng? _destLoc;
  bool _busy = false;

  List<Map<String, dynamic>> _startSuggestions = [];
  List<Map<String, dynamic>> _destSuggestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      _destCtrl.text = widget.initialDestination!['name'] ?? 'Selected place';
      _destLoc = LatLng(
        (widget.initialDestination!['lat'] as num).toDouble(),
        (widget.initialDestination!['lon'] as num).toDouble(),
      );
    }
  }

  /// ---- PICK CURRENT LOCATION ----
  Future<void> _pickCurrentLocationAsStart() async {
    try {
      final svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _setFallbackLocation();
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _setFallbackLocation();
        return;
      }

      setState(() => _busy = true);
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _startLoc = LatLng(pos.latitude, pos.longitude);

      // ---- Reverse Geocode using your Nominatim server ----
      final placeName = await _reverseGeocode(_startLoc!);

      setState(() {
        _startCtrl.text = placeName ?? "Your location";
      });
    } catch (_) {
      _setFallbackLocation();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _reverseGeocode(LatLng loc) async {
    try {
      final url = Uri.parse(
        '$nominatimurl/reverse?lat=${loc.latitude}&lon=${loc.longitude}&format=json',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['display_name'];
      }
    } catch (_) {}
    return null;
  }

  void _setFallbackLocation() {
    setState(() {
      _startLoc = const LatLng(12.9716, 77.5946);
      _startCtrl.text = 'Bengaluru (default)';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not fetch your location. Using Bengaluru as a fallback.',
        ),
      ),
    );
  }

  /// ---- FETCH SEARCH SUGGESTIONS ----
  Future<void> _fetchSuggestions({
    required String query,
    required bool isStart,
  }) async {
    if (query.trim().isEmpty) {
      setState(() {
        if (isStart) {
          _startSuggestions = [];
        } else {
          _destSuggestions = [];
        }
      });
      return;
    }

    setState(() => _busy = true);
    List<Map<String, dynamic>> results = [];
    try {
      final url = Uri.parse(
        '$nominatimurl/search?q=$query&format=json&limit=8',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        results = data
            .map(
              (e) => {
                'name': e['display_name'],
                'lat': double.tryParse(e['lat'].toString()) ?? 0.0,
                'lon': double.tryParse(e['lon'].toString()) ?? 0.0,
              },
            )
            .cast<Map<String, dynamic>>()
            .toList();
      }
    } catch (_) {
      // ignore network errors for now
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    setState(() {
      if (isStart) {
        _startSuggestions = results;
      } else {
        _destSuggestions = results;
      }
    });
  }

  void _selectSuggestion(bool isStart, Map<String, dynamic> place) {
    final loc = LatLng(place['lat'], place['lon']);
    setState(() {
      if (isStart) {
        _startLoc = loc;
        _startCtrl.text = place['name'];
        _startSuggestions = [];
      } else {
        _destLoc = loc;
        _destCtrl.text = place['name'];
        _destSuggestions = [];
      }
    });
  }

  /// ---- FETCH ROUTE FROM OSRM ----
  Future<void> _fetchRoute() async {
    if (_startLoc == null || _destLoc == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      final osrmUrl = Uri.parse(
        '$osrmurl/route/v1/driving/'
        '${_startLoc!.longitude},${_startLoc!.latitude};'
        '${_destLoc!.longitude},${_destLoc!.latitude}'
        '?overview=full',
      );
      final response = await http.get(osrmUrl);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final encodedPolyline = json['routes'][0]['geometry'];

        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(
          encodedPolyline,
        );
        final routePoints = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        if (mounted) {
          if (mounted) {
            widget.onRouteFound?.call(routePoints, json['routes'][0]);
            widget.onClose?.call();
          }
        }
      }
    } catch (e) {
      // ...
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _findRoutePressed() {
    if (_startLoc == null || _destLoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick both Start and Destination')),
      );
      return;
    }
    _fetchRoute();
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    );

    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),

            // Start Input
            Row(
              children: [
                Icon(Icons.trip_origin, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _startCtrl,
                        decoration: InputDecoration(
                          labelText: 'Your location',
                          hintText: 'Search for a starting point',
                          border: inputBorder,
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) =>
                            _fetchSuggestions(query: value, isStart: true),
                        onTap: () {
                          // When user taps start field but hasn't typed yet, show "Use my location"
                          if (_startCtrl.text.isEmpty) {
                            setState(() {
                              _startSuggestions = [
                                {
                                  "name": "Use current location",
                                  "lat": null,
                                  "lon": null,
                                },
                              ];
                            });
                          }
                        },
                      ),

                      if (_startSuggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _startSuggestions.length,
                            itemBuilder: (context, index) {
                              final place = _startSuggestions[index];

                              // Special handling for "Use current location"
                              if (place['lat'] == null &&
                                  place['lon'] == null) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                  ),
                                  title: Text(place['name']),
                                  onTap: _pickCurrentLocationAsStart,
                                );
                              }

                              // Normal search suggestion
                              return ListTile(
                                leading: const Icon(Icons.place),
                                title: Text(place['name']),
                                onTap: () => _selectSuggestion(true, place),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 16),

            // Destination Input
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _destCtrl,
                        decoration: InputDecoration(
                          labelText: 'Destination',
                          hintText: 'Search for a destination',
                          border: inputBorder,
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) =>
                            _fetchSuggestions(query: value, isStart: false),
                      ),
                      if (_destSuggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _destSuggestions.length,
                            itemBuilder: (context, index) {
                              final place = _destSuggestions[index];
                              return ListTile(
                                leading: const Icon(Icons.place),
                                title: Text(place['name']),
                                onTap: () => _selectSuggestion(false, place),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _findRoutePressed,
              icon: const Icon(Icons.directions),
              label: const Text('Find Route'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
