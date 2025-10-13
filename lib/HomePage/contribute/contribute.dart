import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_place_modal.dart';
import 'place_selection_modal.dart';

class ContributePage extends StatefulWidget {
  final String userId;

  const ContributePage({super.key, required this.userId});

  @override
  State<ContributePage> createState() => _ContributePageState();
}

class _ContributePageState extends State<ContributePage> {
  List<Map<String, dynamic>> _userPlaces = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserPlaces();
  }

  Future<void> _fetchUserPlaces() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _userPlaces = [];
          _error = 'No token found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      const String apiUrl = 'http://0.0.0.0:3000/contribute/user-contributions';
      final response = await http.get(
        Uri.parse('$apiUrl?page=1&limit=20'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('API Response: $responseData');

        if (responseData['data'] != null && responseData['data'] is List) {
          setState(() {
            _userPlaces = List<Map<String, dynamic>>.from(responseData['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _userPlaces = [];
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Unauthorized. Please login again.';
          _userPlaces = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch places. Status code: ${response.statusCode}';
          _userPlaces = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please check your connection.';
        _userPlaces = [];
        _isLoading = false;
      });
    }
  }

  Widget buildOption(IconData icon, String label, VoidCallback onTap) {
    const Color mainColor = Color(0xFF914294);
    const Color borderColor = Color(0xFF6A2E6F);
    const Color bgColor = Color(0x22914294);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Icon(icon, color: mainColor, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    const Color mainColor = Color(0xFF914294);
    const Color bgColor = Color(0x22914294);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: mainColor.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.place,
                color: mainColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place['name'] ?? 'Unnamed Place',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place['category'] ?? 'No category',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place['short_description'] ?? 'No description',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: mainColor.withOpacity(0.3)),
              ),
              child: Text(
                'Added',
                style: TextStyle(
                  color: mainColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    const Color mainColor = Color(0xFF914294);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: mainColor.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              Icons.sentiment_dissatisfied,
              color: mainColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Places Yet!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You haven't contributed any places yet.\nStart by adding your first place above!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesList() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 32),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF914294)),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchUserPlaces,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_userPlaces.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF914294).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_history,
                color: Color(0xFF914294),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Contributed Places',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                Text(
                  '${_userPlaces.length} place${_userPlaces.length != 1 ? 's' : ''} added',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...(_userPlaces.take(5).map((place) => _buildPlaceCard(place)).toList()),
        if (_userPlaces.length > 5)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF914294).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF914294).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF914294),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Showing 5 of ${_userPlaces.length} places',
                  style: const TextStyle(
                    color: Color(0xFF914294),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: const Color(0xFF914294),
        onRefresh: _fetchUserPlaces,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            buildOption(Icons.add_location_alt, "Add Place", () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                builder: (_) => AddPlaceModal(userId: widget.userId),
              );
              if (result == true) {
                _fetchUserPlaces();
              }
            }),
            buildOption(Icons.edit_location_alt, "Edit Place", () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                builder: (_) => PlaceSelectionModal(
                  userId: widget.userId,
                  mode: PlaceSelectionMode.edit,
                ),
              );
              if (result == true) {
                _fetchUserPlaces();
              }
            }),
            buildOption(Icons.delete, "Delete Place", () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                builder: (_) => PlaceSelectionModal(
                  userId: widget.userId,
                  mode: PlaceSelectionMode.delete,
                ),
              );
              if (result == true) {
                _fetchUserPlaces();
              }
            }),
            _buildPlacesList(),
          ],
        ),
      ),
    );
  }
}
