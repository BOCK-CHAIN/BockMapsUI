import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_place_modal.dart';

enum PlaceSelectionMode { edit, delete }

class PlaceSelectionModal extends StatefulWidget {
  final String userId;
  final PlaceSelectionMode mode;

  const PlaceSelectionModal({
    super.key,
    required this.userId,
    required this.mode,
  });

  @override
  State<PlaceSelectionModal> createState() => _PlaceSelectionModalState();
}

class _PlaceSelectionModalState extends State<PlaceSelectionModal> {
  List<Map<String, dynamic>> _places = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

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
          _error = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      const String apiUrl = 'http://10.0.2.2:3000/contribute/user-contributions';

      final response = await http.get(
        Uri.parse('$apiUrl?page=$_currentPage&limit=10'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (mounted) {
          setState(() {
            _places = List<Map<String, dynamic>>.from(responseData['data']);
            _totalPages = responseData['pagination']['total_pages'] ?? 1;
            _hasMore = responseData['pagination']['has_next'] ?? false;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to fetch places';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Network error. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePlace(String placeId, String placeName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:3000/contribute/place/$placeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$placeName deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          _fetchUserPlaces(); // Refresh the list
        }
      } else {
        String errorMessage = 'Failed to delete place';
        try {
          final responseData = json.decode(response.body);
          if (responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(String placeId, String placeName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Place',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF914294),
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$placeName"? This action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePlace(placeId, placeName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _handlePlaceSelection(Map<String, dynamic> place) {
    if (widget.mode == PlaceSelectionMode.edit) {
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        builder: (_) => EditPlaceModal(
          userId: widget.userId,
          placeData: place,
        ),
      );
    } else if (widget.mode == PlaceSelectionMode.delete) {
      _showDeleteConfirmation(
        place['place_id'],
        place['name'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.mode == PlaceSelectionMode.edit ? 'Select Place to Edit' : 'Select Place to Delete';
    IconData headerIcon = widget.mode == PlaceSelectionMode.edit ? Icons.edit_location_alt : Icons.delete;
    Color actionColor = widget.mode == PlaceSelectionMode.edit ? const Color(0xFF914294) : Colors.red;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Modal handle
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(headerIcon, color: actionColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF914294)),
              ),
            )
                : _error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchUserPlaces,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF914294),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : _places.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No places found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You haven\'t contributed any places yet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _places.length,
              itemBuilder: (context, index) {
                final place = _places[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: actionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.place,
                        color: actionColor,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      place['name'] ?? 'Unnamed Place',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          place['category'] ?? 'No category',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
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
                    trailing: Icon(
                      widget.mode == PlaceSelectionMode.edit
                          ? Icons.edit
                          : Icons.delete,
                      color: actionColor,
                    ),
                    onTap: () => _handlePlaceSelection(place),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}