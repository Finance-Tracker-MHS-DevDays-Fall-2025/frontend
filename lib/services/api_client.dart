// lib/main.dart
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'config/api_client.dart';

void main() {
  // Временный userId — будет заменён в LoginScreen
  initApiClient('user-123'); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}