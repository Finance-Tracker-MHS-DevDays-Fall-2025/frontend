// lib/widgets/top_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:fintrack/screens/wallet_screen.dart';
import 'package:fintrack/screens/investments_screen.dart';
import 'package:fintrack/screens/settings_screen.dart';

class TopNavigationBar extends StatelessWidget {
  final String currentRoute;

  const TopNavigationBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          const Text(
            'FinTrack',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 24),

          // Пункты меню
          _buildNavItem(context, 'Кошелек', '/wallet', Icons.account_balance_wallet_outlined),
          const SizedBox(width: 16),
          _buildNavItem(context, 'Инвестиции', '/investments', Icons.trending_up_outlined),
          const SizedBox(width: 16),
          _buildNavItem(context, 'Настройки', '/settings', Icons.settings_outlined),

          const Spacer(),

          // Уведомления и профиль
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 24, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF3C4759),
            child: Icon(Icons.person, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String label, String route, IconData icon) {
    final isActive = currentRoute == route;
    return GestureDetector(
      onTap: () {
        if (currentRoute != route) {
          switch (route) {
            case '/wallet':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
              break;
            case '/investments':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const InvestmentsScreen()),
              );
              break;
            case '/settings':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              break;
          }
        }
      },
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? Colors.white : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[400],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}