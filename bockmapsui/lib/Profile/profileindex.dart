import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../SignupOrLogin/signup_or_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  final String backendUrl = 'http://10.0.2.2:3000';

  Future<void> _logout(BuildContext context) async {
    try {
      final url = Uri.parse('$backendUrl/api/auth/logout');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SignupOrLogin()),
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: const AccountBody(),
    );
  }
}

class AccountBody extends StatefulWidget {
  const AccountBody({super.key});

  @override
  State<AccountBody> createState() => _AccountBodyState();
}

class _AccountBodyState extends State<AccountBody> {
  Map<String, dynamic>? user;
  bool isLoading = true;
  final TextEditingController emailController = TextEditingController();

  final String backendUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final url = Uri.parse('$backendUrl/api/auth/profile');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Profile response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          setState(() {
            user = data['user'];
            emailController.text = "";
            isLoading = false;
          });
        } else {
          setState(() {
            user = null;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  bool isValidEmail(String email){
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  Future<void> _updateEmail() async {
    final email = emailController.text.trim();

    if(email.isEmpty || !isValidEmail(email)){
      showDialog(
          context: context,
          builder: (context){
            return AlertDialog(
              title: const Text("Error"),
              content: const Text("Email is not valid!"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK")
                )
              ],
            );
          }
      );
    }
    else{
      try{
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token') ?? '';

        final url = Uri.parse('$backendUrl/api/auth/changeEmail');
        final response = await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
            body: jsonEncode({ 'newEmail': email })
        );

        if(response.statusCode == 200){
          final data = jsonDecode(response.body);
          showDialog(
              context: context,
              builder: (context){
                return AlertDialog(
                  title: const Text("Successful"),
                  content: Text("Email updated to ${data['email']}"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK")
                    )
                  ],
                );
              }
          );
          setState(() {
            user!['email'] = data['email'];
          });
        }else{
          final data = jsonDecode(response.body);
          showDialog(
              context: context,
              builder: (context){
                return AlertDialog(
                  title: const Text("Error"),
                  content: Text(data['message'] ?? "Failed to update email!"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK")
                    )
                  ],
                );
              }
          );
        }
      }catch(e){
        showDialog(
            context: context,
            builder: (context){
              return const AlertDialog(
                title: const Text("Error"),
                content: Text("Something went wrong!"),
              );
            }
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final url = Uri.parse('$backendUrl/api/auth/deleteAccount');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Account Deleted"),
                  content: const Text("Your account has been permanently deleted."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupOrLogin()),
                              (route) => false,
                        );
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              });
        }
      } else {
        final data = jsonDecode(response.body);
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Error"),
                content: Text(data['message'] ?? "Failed to delete account!"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"))
                ],
              );
            });
      }
    } catch (e) {
      showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(
              title: Text("Error"),
              content: Text("Something went wrong!"),
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (user == null) {
      return const Center(child: Text("No user found"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Center(
            child: Image.asset(
              'assets/images/ProfilePicture.png',
              width: 140,
              height: 140,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Email",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(user!['email']),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "New Email",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 50,
                      child: TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: "Enter new email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
              width: double.infinity,
              height: 40,
              child: InkWell(
                onTap: () {
                  _updateEmail();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Color(0xFFFFF3E0),
                    border: Border.all(
                      width: 2,
                      color: Color(0xFF914294),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email, color: Color(0xFF914294)),
                      SizedBox(width: 6),
                      Text(
                        "Change Email",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      )
                    ],
                  ),
                ),
              )
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    print('Tapped!');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF914294),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.lock, size: 20, color: Color(0xFF914294)),
                        SizedBox(width: 8),
                        Text("Change Password", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    print('Tapped!');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF914294),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.location_on,
                            size: 20, color: Color(0xFF914294)),
                        SizedBox(width: 8),
                        Text("Location Access",
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    print('Tapped!');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF914294),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.notifications,
                            size: 20, color: Color(0xFF914294)),
                        SizedBox(width: 8),
                        Text("Notifications", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    print('Tapped!');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF914294),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.language,
                            size: 20, color: Color(0xFF914294)),
                        SizedBox(width: 8),
                        Text("Language", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Confirm Deletion"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Are you sure you want to delete your account?",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          "This action cannot be undone.",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteAccount();
                        },
                        child: const Text("Yes"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("No"),
                      ),
                    ],
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFED5E68),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delete, size: 20, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    "Delete Account",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
