import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../index.dart';

class YouPage extends StatefulWidget {
  const YouPage({super.key});

  @override
  State<YouPage> createState() => _YouPageState();
}

class _YouPageState extends State<YouPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _userLists = [];
  final String backendUrl = 'http://10.0.2.2:3000';
  final TextEditingController _listNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserLists();
  }

  Future<void> _fetchUserLists() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final url = Uri.parse('$backendUrl/list/lists');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userLists = List<Map<String, dynamic>>.from(data['lists']);
        });
      } else {
        setState(() => _userLists = []);
      }
    } catch (e) {
      setState(() => _userLists = []);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createNewList(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final url = Uri.parse('$backendUrl/list/lists/create');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('List created successfully!')));
        _fetchUserLists();
        _listNameController.clear();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to create list.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showNewListModal() {
    _listNameController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Create New List",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _listNameController,
                  decoration: InputDecoration(
                    labelText: "List Name",
                    hintText: "Enter list name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF914294),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      final name = _listNameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a list name')),
                        );
                      } else {
                        _createNewList(name);
                      }
                    },
                    child: const Text("Create List", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteList(String listId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final url = Uri.parse('$backendUrl/list/lists/$listId');
      final response = await http.delete(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        _fetchUserLists();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete list')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete list')));
    }
  }

  Future<void> _updateList(String listId, String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final url = Uri.parse('$backendUrl/list/lists/$listId');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'name': newName}),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('List updated successfully!')));
        _fetchUserLists();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to update list.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showEditListModal(String id, String currentName) {
    _listNameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Edit List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _listNameController,
                  decoration: InputDecoration(
                    labelText: "List Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF914294),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      final newName = _listNameController.text.trim();
                      if (newName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a list name')),
                        );
                      } else {
                        _updateList(id, newName);
                      }
                    },
                    child: const Text("Update List", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _editList(String id, String name) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') _showEditListModal(id, name);
        if (value == 'delete') _deleteList(id);
      },
      itemBuilder: (BuildContext context) => const [
        PopupMenuItem(value: 'edit', child: Text("Edit List")),
        PopupMenuItem(value: 'delete', child: Text("Delete List")),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAddresses(String listId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final url = Uri.parse('$backendUrl/storedAddress/addresses/$listId');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['addresses']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    return [];
  }

  Future<void> _deleteAddress(String addressId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final url = Uri.parse('$backendUrl/storedAddress/addresses/$addressId');
      final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) _fetchUserLists();
      else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete address')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete address')));
    }
  }

  void _navigateToHomeWithAddress(Map<String, dynamic> address) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeIndex(selectedAddress: address),
      ),
          (route) => false,
    );
  }

  void _showAddressesModal(String listId, String listName) async {
    final addresses = await _fetchAddresses(listId);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 400,
              width: 350,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: addresses.isEmpty
                        ? const Center(child: Text("No addresses in this list"))
                        : ListView.builder(
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final addr = addresses[index];
                        return ListTile(
                          title: Text(addr['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          subtitle: Text('${addr['latitude']}, ${addr['longitude']}', style: const TextStyle(fontSize: 14)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteAddress(addr['id'].toString());
                              } else if (value == 'navigate') {
                                Navigator.of(context).pop(); // Close the modal first
                                _navigateToHomeWithAddress(addr);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'navigate', child: Text("View on Map")),
                              PopupMenuItem(value: 'delete', child: Text("Delete Address")),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).pop(); // Close the modal first
                            _navigateToHomeWithAddress(addr);
                          },
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close")),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> list) {
    const mainColor = Color(0xFF914294);
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.list, color: mainColor),
          title: Text(list['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          trailing: _editList(list['id'].toString(), list['name']),
          onTap: () => _showAddressesModal(list['id'].toString(), list['name']),
        ),
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Colors.black12),
      ],
    );
  }

  Widget _buildEmptyState() {
    const mainColor = Color(0xFF914294);
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.playlist_add, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No Lists Yet!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            "Create your first list to start organizing your favorite places",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            onPressed: _showNewListModal,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Create Your First List", style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFF914294);

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: _showNewListModal,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: mainColor, borderRadius: BorderRadius.circular(30)),
              child: const Center(
                child: Text("+ New List",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _userLists.isEmpty ? _buildEmptyState() : Column(children: _userLists.map(_buildUserListItem).toList()),
        ],
      ),
    );
  }
}