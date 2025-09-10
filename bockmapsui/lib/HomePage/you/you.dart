import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class YouPage extends StatefulWidget {
  const YouPage({super.key});

  @override
  State<YouPage> createState() => _YouPageState();
}

class _YouPageState extends State<YouPage> {
  bool _expanded = false;
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
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('List created successfully!')),
        );
        _fetchUserLists();
        _listNameController.clear();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to create list.')));
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF914294),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
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
                    child: const Text("Create List",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
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
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Deletion successful!"),
              content: const Text("List was deleted!"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _fetchUserLists();
                    },
                    child: const Text("OK")
                )
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Deletion failed!"),
              content: const Text("Deletion was not successful!"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK")
                )
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Deletion failed!"),
            content: const Text("Deletion was not successful!"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK")
              )
            ],
          );
        },
      );
    }
  }

  Future<void> _updateList(String listId, String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final url = Uri.parse('$backendUrl/list/lists/$listId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': newName}),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('List updated successfully!')),
        );
        _fetchUserLists();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update list.')),
        );
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
                const Text(
                  "Edit List",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _listNameController,
                  decoration: InputDecoration(
                    labelText: "List Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF914294),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
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
                    child: const Text("Update List",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
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
        if (value == 'edit') {
          _showEditListModal(id, name);
        } else if (value == 'delete') {
          _deleteList(id);
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem(
            value: 'edit',
            child: Text("Edit List"),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text("Delete List"),
          ),
        ];
      },
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> list) {
    const mainColor = Color(0xFF914294);
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.list, color: mainColor),
          title: Text(
            list['name'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: _editList(list['id'].toString(), list['name']),
          onTap: () => print("Tapped: ${list['name']}"),
        ),
        const Divider(
          height: 1,
          thickness: 0.5,
          indent: 16,
          endIndent: 16,
          color: Colors.black12,
        ),
      ],
    );
  }

  Widget buildListItem(IconData icon, String label) {
    const mainColor = Color(0xFF914294);
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: mainColor),
          title: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          onTap: () => print("Tapped: $label"),
        ),
        const Divider(
            height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Colors.black12),
      ],
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
          // Default lists
          buildListItem(Icons.favorite, "Favorite Places"),
          buildListItem(Icons.bookmark, "Want to Visit"),
          buildListItem(Icons.label, "Labeled"),
          buildListItem(Icons.map, "Saved Places"),

          // Animated section for user lists
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _userLists.isEmpty
                ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "No custom lists, add some!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
            )
                : Column(
              children: _userLists.map(_buildUserListItem).toList(),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          if (_userLists.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? "∧ Less" : "∨ More",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
            ),
        ],
      ),
    );
  }
}
