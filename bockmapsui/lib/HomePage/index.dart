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
  final bool forceGuest;
  final Map<String, dynamic>? selectedAddress;
  const HomeIndex({super.key, this.forceGuest = false, this.selectedAddress});

  @override
  State<HomeIndex> createState() => _HomeIndexState();
}

class _HomeIndexState extends State<HomeIndex> {
  Timer? _debounce;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPlace;
  LatLng? _selectedLocation;
  bool isSearching = false;
  List<LatLng> _routePoints = [];
  bool _showDirectionsPanel = false;
  bool? _hasToken;

  @override
  void initState() {
    super.initState();

    if (widget.forceGuest) {
      _hasToken = false;
    } else {
      _checkToken();
    }

    // Handle selected address from You page
    if (widget.selectedAddress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setSelectedAddress(widget.selectedAddress!);
      });
    }

    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  void _setSelectedAddress(Map<String, dynamic> address) {
    setState(() {
      final lat = address['latitude'] is String
          ? double.parse(address['latitude'])
          : address['latitude'].toDouble();
      final lon = address['longitude'] is String
          ? double.parse(address['longitude'])
          : address['longitude'].toDouble();

      _selectedPlace = {
        'name': address['name'],
        'lat': lat,
        'lon': lon,
        'type': 'Saved Address',
      };
      _selectedLocation = LatLng(lat, lon);
      _searchController.text = address['name'];
      _selectedIndex = 0; // Switch to Directions tab
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }
    setState(() => isSearching = true);

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
    } catch (e) {
      print('Search error: $e');
    } finally {
      setState(() => isSearching = false);
    }
  }

  void _selectPlace(Map<String, dynamic> place) {
    setState(() {
      _selectedPlace = place;
      _selectedLocation = LatLng(place['lat'], place['lon']);
      _searchResults.clear();
      _searchController.text = place['name'];
      _searchFocusNode.unfocus();
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

  final String backendUrl = 'http://10.0.2.2:3000';

  Future<void> _showListsModal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    if (token == '') return;

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/list/lists'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List lists = data['lists'];

        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                  minWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Available Lists:",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: lists.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final list = lists[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            title: Text(
                              list['name'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              Navigator.pop(context);
                              final addressNameController = TextEditingController();
                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Enter Address Name'),
                                  content: TextField(
                                    controller: addressNameController,
                                    decoration: const InputDecoration(
                                      hintText: 'Address name',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        final addressName = addressNameController.text.trim();
                                        if (_selectedLocation == null || addressName.isEmpty) return;

                                        final addAddressResponse = await http.post(
                                          Uri.parse('$backendUrl/storedAddress/addresses'),
                                          headers: {
                                            'Authorization': 'Bearer $token',
                                            'Content-Type': 'application/json',
                                          },
                                          body: json.encode({
                                            'list_id': list['id'],
                                            'name': addressName,
                                            'latitude': _selectedLocation!.latitude,
                                            'longitude': _selectedLocation!.longitude,
                                          }),
                                        );

                                        Navigator.pop(context);

                                        if (addAddressResponse.statusCode == 200) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Address saved successfully')),
                                          );
                                        } else if (addAddressResponse.statusCode == 400) {
                                            final data = json.decode(addAddressResponse.body);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(data['message'])),
                                            );
                                        } else{
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Failed to save address')),
                                          );
                                        }
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      print('Failed to fetch lists: $e');
    }
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    setState(() {
      _hasToken = token != null && token.isNotEmpty;
      if (_hasToken == false && _selectedIndex > 1) _selectedIndex = 0;
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasToken == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = _hasToken!
        ? [
      DirectionsPage(),
      explore.ExplorePage(),
      you.YouPage(),
      contribute.ContributePage(),
    ]
        : [
      DirectionsPage(),
      explore.ExplorePage(),
    ];

    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    final bool showSearchBar = _selectedIndex == 0 || _selectedIndex == 1;
    final bool showMapBackground = _selectedIndex == 0 || _selectedIndex == 1;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (showMapBackground) ...[
              GestureDetector(
                onTap: () {
                  _searchFocusNode.unfocus();
                  setState(() {
                    _searchResults.clear();
                  });
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: MapBackground(
                        targetLocation: _selectedLocation,
                        routePoints: _routePoints,
                      ),
                    ),
                    if (!_showDirectionsPanel)
                      Positioned(
                        top: 15,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
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
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                              ),
                            ],
                            if (showSearchBar) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 420),
                                      curve: Curves.easeInOutCubic,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        boxShadow: _searchFocusNode.hasFocus
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
                                        focusNode: _searchFocusNode,
                                        onChanged: _onSearchChanged,
                                        decoration: InputDecoration(
                                          hintText: 'Search destinations...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(30),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          suffixIcon: isSearching
                                              ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          )
                                              : IconButton(
                                            icon: const Icon(Icons.search),
                                            onPressed: () => _searchPlaces(_searchController.text),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_searchResults.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: _searchResults.map((place) {
                                            return ListTile(
                                              title: Text(
                                                place['name'],
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: place['type'] != '' ? Text(place['type']) : null,
                                              onTap: () => _selectPlace(place),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _selectedPlace != null ? _openDirections : null,
                                icon: const Icon(Icons.directions),
                                label: const Text("Go"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (_selectedPlace != null && _selectedIndex == 0 && !_showDirectionsPanel)
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Lat: ${_selectedPlace!['lat'].toStringAsFixed(4)}, Lon: ${_selectedPlace!['lon'].toStringAsFixed(4)}",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _openDirections,
                                      icon: const Icon(Icons.directions),
                                      label: const Text("Get Directions"),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _showListsModal,
                                      icon: const Icon(Icons.bookmark_add),
                                      label: const Text("Save Address"),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_showDirectionsPanel)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: DirectionsPage(
                          initialDestination: _selectedPlace,
                          onClose: _hideDirectionsPanel,
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
            ] else ...[
              pages[_selectedIndex],
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (!_hasToken! && index > 1) return;
          setState(() {
            _selectedIndex = index;
            if (index != 0 && index != 1) {
              _searchResults.clear();
              _searchController.clear();
              _searchFocusNode.unfocus();
            }
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "You",
          ),
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
    );
  }
}