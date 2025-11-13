// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/screens/wallet_screen.dart';
import 'package:fintrack/screens/investments_screen.dart';
import 'package:fintrack/services/real_api_service.dart';

class SettingsScreen extends StatefulWidget {
  final RealApiService api;
  const SettingsScreen({super.key, required this.api});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final RealApiService api;

  @override
  void initState() {
    super.initState();
    api = widget.api; // ← Инициализация api
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  const Text('FinTrack', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => WalletScreen(api: api))),
                    child: Row(
                      children: const [
                        Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Кошелек', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => InvestmentsScreen(api: api))),
                    child: Row(
                      children: const [
                        Icon(Icons.trending_up_outlined, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Инвестиции', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Настройки — неактивна
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Настройки', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 24, color: Colors.white),
                      onPressed: () {}),
                  const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFF3C4759),
                      child: Icon(Icons.person, size: 16, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Интеграции', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 24),
                    _buildIntegrationCard(
                      icon: Icons.account_balance,
                      title: 'Т-Банк',
                      subtitle: 'Подключите счёт для автоматической загрузки операций',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildIntegrationCard(
                      icon: Icons.analytics,
                      title: 'Т-Инвестиции',
                      subtitle: 'Синхронизация портфеля и дивидендов',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
