import 'package:flutter/material.dart';
import './SignupOrLogin/signup_or_login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // This ensures all bindings are ready before we load env
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BOCK Maps',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SignupOrLogin(),
    );
  }
}
