import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../SignupOrLogin/signup_or_login.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  final String backendUrl = 'http://10.0.2.2:3000'; // Android emulator URL

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
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 55), // longer buttons
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // less round
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => print("Change Email button clicked"),
                  child: const Text("Change Email"),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => print("Change Password button clicked"),
                  child: const Text("Change Password"),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => print("Manage Addresses button clicked"),
                  child: const Text("Manage Addresses"),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => print("Location Access button clicked"),
                  child: const Text("Location Access"),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => print("Profile Settings button clicked"),
                  child: const Text("Profile Settings"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
