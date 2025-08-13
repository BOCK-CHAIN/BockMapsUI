// File: lib/SignupOrLogin.dart

import 'package:flutter/material.dart';
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
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF914294),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 40, bottom: 20, left: 20, right: 20),
              child: Image.asset(
                'assets/images/BockChainLogo.png',
                width: 200,
                height: 200,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Center(
                child: Text(
                  'Welcome to BOCK Maps \n Explore the world right here!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            LoginBox(),
          ],
        ),
      ),
    );
  }
}

class LoginBox extends StatefulWidget {
  @override
  LoginBoxState createState() {
    return LoginBoxState();
  }
}

class LoginBoxState extends State<LoginBox> {
  String email = '';
  String password = '';
  bool isTapped = false;
  bool _obscureTextLogin = true;

  void _showRegisterModal() {
    String regEmail = '';
    String regPassword = '';
    String regRepeatPassword = '';
    bool _localObscureFirst = true;
    bool _localObscureSecond = true;

    showDialog(
      context: context,
      barrierDismissible: false, // prevents closing when tapping outside
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
                      // Close button (X)
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
                          // When password changes, clear repeat to force re-entry
                          regRepeatPassword = '';
                        }),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _localObscureFirst ? Icons.visibility_off : Icons.visibility,
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
                        enabled: canEditRepeat, // locked until first password entered
                        obscureText: _localObscureSecond,
                        onChanged: (val) => setState(() {
                          regRepeatPassword = val;
                        }),
                        decoration: InputDecoration(
                          labelText: 'Repeat Password',
                          border: OutlineInputBorder(),
                          isDense: true,
                          // Show error when mismatch, helper when match
                          errorText: showMismatch ? 'Passwords do not match' : null,
                          helperText: showMatch ? 'Passwords match' : null,
                          helperStyle: TextStyle(color: Colors.green[700]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _localObscureSecond ? Icons.visibility_off : Icons.visibility,
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
                            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isFormValid
                              ? () {
                            print("Email: \$regEmail");
                            print("Password: \$regPassword");
                            print("Repeat: \$regRepeatPassword");
                            Navigator.of(context).pop();
                          }
                              : null, // disabled until valid
                          child: Text(
                            'Register',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            Padding(
              padding: EdgeInsets.only(top: 8, left: 8, right: 8),
              child: Text(
                'Login',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Divider(
              color: Colors.black,
              thickness: 1,
              indent: 15,
              endIndent: 15,
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Padding(
                padding: EdgeInsets.only(left: 5, right: 5),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      email = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Padding(
                padding: EdgeInsets.only(left: 5, right: 5),
                child: TextField(
                  obscureText: _obscureTextLogin,
                  onChanged: (value) {
                    setState(() {
                      password = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureTextLogin ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureTextLogin = !_obscureTextLogin;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // route to HomePage index.dart
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeIndex()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 45, right: 45),
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not Registered?',
                    style: TextStyle(fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: _showRegisterModal,
                    onTapDown: (tapDownDetails) {
                      setState(() {
                        isTapped = true;
                      });
                    },
                    onTapUp: (tapUpDetails) {
                      setState(() {
                        isTapped = false;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: isTapped ? Colors.blue.withOpacity(0.5) : Colors.blue,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}