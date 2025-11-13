// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:fintrack/screens/login_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}