// homeindex.dart
import 'package:flutter/material.dart';
import './contribute/contribute.dart' as contribute;
import './explore/explore.dart' as explore;
import './you/you.dart' as you;
import '../Profile/profileindex.dart' as account;
import './map_background/map_background.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import './directions/directions.dart';
import 'dart:async'; 
class HomeIndex extends StatefulWidget {
  const HomeIndex({super.key});

  @override
  State<HomeIndex> createState() => _HomeIndexState();
}

class _HomeIndexState extends State<HomeIndex> {
  Timer? _debounce; 
  // Map and Search State
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPlace;
  LatLng? _selectedLocation;
  bool _isSearching = false;
  List<LatLng> _routePoints = [];

  // Directions Panel State
  bool _showDirectionsPanel = false;

  void _onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    _searchPlaces(query);
  });
}
  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'http://34.47.223.147:8088/search?q=$query&format=json&limit=5',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _searchResults = data
              .map((e) => {
                    'name': e['display_name'],
                    'lat': double.tryParse(e['lat'].toString()) ?? 0.0,
                    'lon': double.tryParse(e['lon'].toString()) ?? 0.0,
                    'type': e['type'] ?? '',
                  })
              .toList();
        });
      }
    } catch (_) {
      // Silent fail on network error
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectPlace(Map<String, dynamic> place) {
    setState(() {
      _selectedPlace = place;
      _selectedLocation = LatLng(place['lat'], place['lon']);
      _searchResults.clear();
      _searchController.text = place['name'];
    });
  }

  void _openDirections() {
    setState(() {
      _showDirectionsPanel = true;
    });
  }

  void _hideDirectionsPanel() {
    setState(() {
      _showDirectionsPanel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const SizedBox.shrink(), // Map page is index 0
      explore.ExplorePage(),
      you.YouPage(),
      contribute.ContributePage(),
    ];

    final bool showMapBackground = _selectedIndex == 0 || _selectedIndex == 1;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (showMapBackground)
              Positioned.fill(
                child: MapBackground(targetLocation: _selectedLocation, routePoints: _routePoints,),
              ),

            // Top Search Bar
            if (!_showDirectionsPanel)
              Positioned(
                top: 15,
                left: 72,
                right: 12,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search destinations...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: () =>
                                          _searchPlaces(_searchController.text),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          onPressed: _openDirections,
                          icon: const Icon(Icons.directions),
                          label: const Text("Go"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        color: Colors.white,
                        child: Column(
                          children: _searchResults
                              .map((place) => ListTile(
                                    title: Text(place['name']),
                                    subtitle: place['type'] != ''
                                        ? Text(place['type'])
                                        : null,
                                    onTap: () => _selectPlace(place),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),

            if (_selectedPlace != null && _selectedIndex == 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPlace!['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Lat: ${_selectedPlace!['lat']}, Lon: ${_selectedPlace!['lon']}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _openDirections,
                        icon: const Icon(Icons.directions),
                        label: const Text("Directions"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Positioned(
              top: 18,
              left: 12,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const account.AccountPage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person),
                ),
              ),
            ),
            
            // The bottom-anchored directions panel
            if (_showDirectionsPanel)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DirectionsPage(
                  initialDestination: _selectedPlace,
                  onClose: _hideDirectionsPanel, // New callback to close the panel
                  onRouteFound: (points) {
                    setState(() {
                      _routePoints = points;
                      _hideDirectionsPanel();
                    });
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.purple.shade200,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions),
            label: "Directions",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "You"),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: "Contribute",
          ),
        ],
      ),
    );
  }
}