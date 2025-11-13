// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/services/real_api_service.dart';
import 'package:fintrack/widgets/top_app_bar.dart';

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
    api = widget.api;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: TopAppBar(
        api: api,
        currentPage: TopPage.settings,
        onNotificationsPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🔔 Уведомления — Coming Soon')),
          );
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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