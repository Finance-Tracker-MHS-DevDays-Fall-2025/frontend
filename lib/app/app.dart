// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:fintrack/screens/wallet_screen.dart';
import 'package:fintrack/services/real_api_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final api = RealApiService(userId: '11111111-1111-1111-1111-111111111111');
    return WalletScreen(api: api);
  }
}