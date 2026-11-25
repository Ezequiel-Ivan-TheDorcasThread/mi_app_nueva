import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Costura',
      theme: ThemeData(
        primaryColor: const Color(0xFFD49B9B),
        scaffoldBackgroundColor: const Color(0xFFF7F5F0),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}