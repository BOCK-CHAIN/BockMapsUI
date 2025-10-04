import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddPlaceModal extends StatefulWidget {
  final String userId; // optional user id to send if no auth token

  const AddPlaceModal({super.key, required this.userId});

  @override
  State<AddPlaceModal> createState() => _AddPlaceModalState();
}

class _AddPlaceModalState extends State<AddPlaceModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSubmitting = false;

  final List<String> tabs = [
    "General",
    "Contact",
    "Location",
    "Services",
  ];

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shortDescriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _postalAddressController = TextEditingController();
  final TextEditingController _exactAddressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  final TextEditingController _closingHoursController = TextEditingController();
  final TextEditingController _servicesController = TextEditingController();
  final TextEditingController _priceRangeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _shortDescriptionController.dispose();
    _categoryController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _postalAddressController.dispose();
    _exactAddressController.dispose();
    _landmarkController.dispose();
    _openingHoursController.dispose();
    _closingHoursController.dispose();
    _servicesController.dispose();
    _priceRangeController.dispose();
    super.dispose();
  }

  Widget buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF914294), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget buildGeneral() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      children: [
        buildTextField("Name", _nameController, hint: "Enter place name"),
        buildTextField("Short Description", _shortDescriptionController, maxLines: 3, hint: "Brief description of the place"),
        buildTextField("Category / Type", _categoryController, hint: "Restaurant, Shop, Service, etc."),
      ],
    );
  }

  Widget buildContact() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      children: [
        buildTextField("Email", _emailController, hint: "contact@example.com"),
        buildTextField("Phone Number", _phoneController, hint: "+1 (555) 123-4567"),
        buildTextField("Website / Social Media", _websiteController, hint: "https://example.com"),
        buildTextField("Postal Address", _postalAddressController, hint: "Street, City, State, ZIP"),
      ],
    );
  }

  Widget buildLocation() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      children: [
        buildTextField("Exact Address", _exactAddressController, hint: "Full street address"),
        buildTextField("Landmark / Directions", _landmarkController, hint: "Near the big oak tree"),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(
            child: Text(
              "Map Placeholder",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildServices() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      children: [
        buildTextField("Opening Hours", _openingHoursController, hint: "9:00 AM"),
        buildTextField("Closing Hours", _closingHoursController, hint: "6:00 PM"),
        buildTextField("Services / Features Offered", _servicesController, hint: "WiFi, Parking, Delivery"),
        buildTextField("Price Range", _priceRangeController, hint: "\$, \$\$, \$\$\$"),
      ],
    );
  }

  List<String> _validateFields() {
    List<String> emptyFields = [];

    if (_nameController.text.trim().isEmpty) emptyFields.add("Name");
    if (_shortDescriptionController.text.trim().isEmpty) emptyFields.add("Short Description");
    if (_categoryController.text.trim().isEmpty) emptyFields.add("Category / Type");
    if (_emailController.text.trim().isEmpty) emptyFields.add("Email");
    if (_phoneController.text.trim().isEmpty) emptyFields.add("Phone Number");
    if (_websiteController.text.trim().isEmpty) emptyFields.add("Website / Social Media");
    if (_postalAddressController.text.trim().isEmpty) emptyFields.add("Postal Address");
    if (_exactAddressController.text.trim().isEmpty) emptyFields.add("Exact Address");
    if (_landmarkController.text.trim().isEmpty) emptyFields.add("Landmark / Directions");
    if (_openingHoursController.text.trim().isEmpty) emptyFields.add("Opening Hours");
    if (_closingHoursController.text.trim().isEmpty) emptyFields.add("Closing Hours");
    if (_servicesController.text.trim().isEmpty) emptyFields.add("Services / Features Offered");
    if (_priceRangeController.text.trim().isEmpty) emptyFields.add("Price Range");

    return emptyFields;
  }

  Future<void> _submitPlace() async {
    if (_isSubmitting) return;

    List<String> emptyFields = _validateFields();
    if (emptyFields.isNotEmpty) {
      String message = "Please fill in: ${emptyFields.join(', ')}";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get token and userId from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      String? storedUserId = prefs.getString('user_id'); // <-- fetch saved user id

      // Prepare data for API
      Map<String, dynamic> placeData = {
        'user_id': storedUserId ?? widget.userId, // <-- prefer logged in user's id
        'name': _nameController.text.trim(),
        'short_description': _shortDescriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'website': _websiteController.text.trim(),
        'postal_address': _postalAddressController.text.trim(),
        'exact_address': _exactAddressController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'opening_hours': _openingHoursController.text.trim(),
        'closing_hours': _closingHoursController.text.trim(),
        'services': _servicesController.text.trim(),
        'price_range': _priceRangeController.text.trim(),
      };

      const String apiUrl = 'http://10.0.2.2:3000/contribute/contribute-place';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(placeData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Place submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        String errorMessage = 'Failed to submit place. Please try again.';
        try {
          final responseData = json.decode(response.body);
          if (responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Tab bar with better styling
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF914294),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              indicator: BoxDecoration(
                color: const Color(0xFF914294),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              splashFactory: NoSplash.splashFactory,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: tabs
                  .map((t) => Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(t),
                ),
              ))
                  .toList(),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildGeneral(),
                buildContact(),
                buildLocation(),
                buildServices(),
              ],
            ),
          ),

          // Enhanced submit button area
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPlace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF914294),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFF914294).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    "Submit Place",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
