import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class DirectionsPage extends StatefulWidget {
  final Map<String, dynamic>? initialDestination;
  final Function(List<LatLng>)? onRouteFound;
  final VoidCallback? onClose; // New callback to close the page

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
      setState(() {
        _startLoc = LatLng(pos.latitude, pos.longitude);
        _startCtrl.text = 'Your location';
      });
    } catch (_) {
      _setFallbackLocation();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
        'http://34.47.223.147:8088/search?q=$query&format=json&limit=8',
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

  List<LatLng> decodePolyline(String encodedString) {
    var lat = 0;
    var lng = 0;
    var index = 0;
    var points = <LatLng>[];

    while (index < encodedString.length) {
      var b;
      var shift = 0;
      var result = 0;
      do {
        b = encodedString.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      var dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encodedString.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      var dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> _fetchRoute() async {
    if (_startLoc == null || _destLoc == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      final osrmUrl = Uri.parse(
        'http://34.47.223.147:5000/route/v1/driving/'
        '${_startLoc!.longitude},${_startLoc!.latitude};'
        '${_destLoc!.longitude},${_destLoc!.latitude}'
        '?overview=full',
      );
      final response = await http.get(osrmUrl);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final encodedPolyline = json['routes'][0]['geometry'];
        print(encodedPolyline);
        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(
          encodedPolyline,
        );
        final routePoints = decodedPoints.map((point) {
          return LatLng(point.latitude, point.longitude);
        }).toList();

        if (mounted) {
          widget.onRouteFound?.call(routePoints);
          widget.onClose?.call(); // Call the onClose callback
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
      borderSide: BorderSide.none, // Make border transparent
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
            // Drag handle and close button
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

            // START and DESTINATION inputs
            // START and DESTINATION inputs
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    // Start point input
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
                                onChanged: (value) => _fetchSuggestions(
                                  query: value,
                                  isStart: true,
                                ),
                              ),
                              if (_startSuggestions.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 150,
                                  ),
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _startSuggestions.length,
                                    itemBuilder: (context, index) {
                                      final place = _startSuggestions[index];
                                      return ListTile(
                                        leading: const Icon(Icons.place),
                                        title: Text(place['name']),
                                        onTap: () =>
                                            _selectSuggestion(true, place),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_vert),
                          onPressed: () {
                            // Swap logic
                            final tmpText = _startCtrl.text;
                            final tmpLoc = _startLoc;
                            setState(() {
                              _startCtrl.text = _destCtrl.text;
                              _startLoc = _destLoc;
                              _destCtrl.text = tmpText;
                              _destLoc = tmpLoc;
                            });
                          },
                        ),
                      ],
                    ),

                    const Divider(height: 16),

                    // Destination point input
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
                                onChanged: (value) => _fetchSuggestions(
                                  query: value,
                                  isStart: false,
                                ),
                              ),
                              if (_destSuggestions.isNotEmpty)
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 150,
                                  ),
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
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
                                        onTap: () =>
                                            _selectSuggestion(false, place),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
