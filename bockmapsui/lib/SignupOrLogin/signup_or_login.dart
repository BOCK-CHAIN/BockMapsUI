import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../HomePage/index.dart';

class SignupOrLogin extends StatelessWidget {
  const SignupOrLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        title: Text(
          'Bock Maps',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF914294),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            SizedBox(height: 40),
            Image.asset(
              'assets/images/BockChainLogo.png',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20),
            Text(
              'Welcome to BOCK Maps \n Explore the world right here!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 20),
            LoginBox(),
          ],
        ),
      ),
    );
  }
}

class LoginBox extends StatefulWidget {
  @override
  LoginBoxState createState() => LoginBoxState();
}

class LoginBoxState extends State<LoginBox> {
  String email = '';
  String password = '';
  bool isTapped = false;
  bool _obscureTextLogin = true;

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  final String backendUrl = 'http://0.0.0.0:3000';
  
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    if (email.isEmpty || password.isEmpty) return;

    final url = Uri.parse('$backendUrl/api/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeIndex()),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Login Failed'),
            content: Text(data['error'] ?? 'Unknown error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('OK'),
            )
          ],
        ),
      );
    }
  }


  void _showRegisterModal() {
    String regEmail = '';
    String regPassword = '';
    String regRepeatPassword = '';
    bool _localObscureFirst = true;
    bool _localObscureSecond = true;

    Future<void> registerUser() async {
      if (regEmail.isEmpty || regPassword.isEmpty) return;
      final url = Uri.parse('$backendUrl/api/auth/register');
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': regEmail, 'password': regPassword}),
        );

        final data = json.decode(response.body);

        if (response.statusCode == 201) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration successful! You can login now.')),
          );
          setState(() {
            email = '';
            password = '';
            _loginEmailController.clear();
            _loginPasswordController.clear();
          });
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Registration Failed'),
              content: Text(data['error'] ?? 'Unknown error'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('OK'),
                )
              ],
            ),
          );
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('OK'),
              )
            ],
          ),
        );
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  final bool canEditRepeat = regPassword.isNotEmpty;
                  final bool showMismatch = canEditRepeat &&
                      regRepeatPassword.isNotEmpty &&
                      regRepeatPassword != regPassword;
                  final bool showMatch = canEditRepeat &&
                      regRepeatPassword.isNotEmpty &&
                      regRepeatPassword == regPassword;
                  final bool isFormValid = regEmail.isNotEmpty && showMatch;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      Center(
                        child: Text(
                          'Register',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        onChanged: (val) => setState(() {
                          regEmail = val;
                        }),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        obscureText: _localObscureFirst,
                        onChanged: (val) => setState(() {
                          regPassword = val;
                          regRepeatPassword = '';
                        }),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _localObscureFirst
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _localObscureFirst = !_localObscureFirst;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        enabled: canEditRepeat,
                        obscureText: _localObscureSecond,
                        onChanged: (val) => setState(() {
                          regRepeatPassword = val;
                        }),
                        decoration: InputDecoration(
                          labelText: 'Repeat Password',
                          border: OutlineInputBorder(),
                          isDense: true,
                          errorText: showMismatch ? 'Passwords do not match' : null,
                          helperText: showMatch ? 'Passwords match' : null,
                          helperStyle: TextStyle(color: Colors.green[700]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _localObscureSecond
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: canEditRepeat
                                ? () {
                              setState(() {
                                _localObscureSecond = !_localObscureSecond;
                              });
                            }
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isFormValid ? registerUser : null,
                          child: Text(
                            'Register',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 345,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.purple[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 8),
            Text('Login',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500)),
            Divider(color: Colors.black, thickness: 1, indent: 15, endIndent: 15),
            Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                controller: _loginEmailController,
                onChanged: (value) => setState(() => email = value),
                decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                controller: _loginPasswordController,
                obscureText: _obscureTextLogin,
                onChanged: (value) => setState(() => password = value),
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureTextLogin
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureTextLogin = !_obscureTextLogin),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: loginUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              child: Text('Login',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Not Registered?', style: TextStyle(fontSize: 16)),
                GestureDetector(
                  onTap: _showRegisterModal,
                  onTapDown: (_) => setState(() => isTapped = true),
                  onTapUp: (_) => setState(() => isTapped = false),
                  child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'Register',
                      style: TextStyle(
                        color: isTapped
                            ? Colors.blue.withOpacity(0.5)
                            : Colors.blue,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
