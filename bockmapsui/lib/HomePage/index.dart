// homeindex.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './contribute/contribute.dart' as contribute;
import './explore/explore.dart' as explore;
import './you/you.dart' as you;
import '../Profile/profileindex.dart' as account;
import '../SignupOrLogin/signup_or_login.dart' as auth;
import './map_background/map_background.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import './directions/directions.dart';
import 'dart:async'; 

class HomeIndex extends StatefulWidget {
  // pass forceGuest: true to force "no token" mode (shows only Directions & Explore)
  final bool forceGuest;
  const HomeIndex({super.key, this.forceGuest = false});

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
  bool? _hasToken; // null => still loading

  @override
  void initState() {
    super.initState();

    // If widget.forceGuest is true, treat as no token immediately.
    if (widget.forceGuest) {
      _hasToken = false;
    } else {
      _checkToken();
    }

    _searchFocusNode.addListener(() {
      setState(() {
        isSearching = _searchFocusNode.hasFocus;
      });
    });
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    setState(() {
      _hasToken = token != null && token.isNotEmpty;
      // clamp index if needed
      if (_hasToken == false && _selectedIndex > 1) _selectedIndex = 0;
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const SizedBox.shrink(), // Map page is index 0
    // While loading (only when not forceGuest), show loading to avoid flicker
    if (_hasToken == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final double initialTop = 18.0;
    final double searchBarHeight = 48.0;
    final double slightlyLowerTop = 40.0;
    final double sidePaddingWhenTop = 12.0;
    final double sidePaddingWhenCentered = 48.0;

    final List<Widget> pages = _hasToken!
        ? [
      directions.DirectionsPage(),
      explore.ExplorePage(),
      you.YouPage(),
      contribute.ContributePage(),
    ]
        : [
      directions.DirectionsPage(),
      explore.ExplorePage(),
    ];

    // keep selectedIndex valid
    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    final bool showSearchBar = _selectedIndex == 0 || _selectedIndex == 1;
    final bool showMapBackground = _selectedIndex == 0 || _selectedIndex == 1;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (showMapBackground)

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              if (showMapBackground) const Positioned.fill(child: MapBackground()),
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
              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeInOutCubic,
                top: isSearching ? slightlyLowerTop : initialTop,
                left: isSearching ? sidePaddingWhenCentered : sidePaddingWhenTop,
                right: isSearching ? sidePaddingWhenCentered : sidePaddingWhenTop,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        // If has token -> account page; otherwise go to signup/login
                        if (_hasToken == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const account.AccountPage(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const auth.SignupOrLogin(),
                            ),
                          );
                        }
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
                    if (_hasToken! && (_selectedIndex == 2 || _selectedIndex == 3)) ...[
                      const SizedBox(width: 18),
                      Text(
                        _selectedIndex == 2 ? "You" : "Contribute",
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                    if (showSearchBar) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeInOutCubic,
                          height: searchBarHeight,
                          decoration: BoxDecoration(
                            boxShadow: isSearching
                                ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ]
                                : null,
                          ),
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
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: isSearching
                                  ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchFocusNode.unfocus();
                                },
                              )
                                  : null,
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
            // Prevent selecting unavailable tabs in guest mode
            if (!_hasToken! && index > 1) return;
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.purple.shade200,
          items: _hasToken!
              ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.directions),
              label: "Directions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: "Explore",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "You"),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box),
              label: "Contribute",
            ),
          ]
              : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.directions),
              label: "Directions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: "Explore",
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