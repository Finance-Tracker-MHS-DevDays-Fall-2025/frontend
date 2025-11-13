// lib/widgets/top_app_bar.dart
import 'package:flutter/material.dart';
import 'package:fintrack/screens/wallet_screen.dart';
import 'package:fintrack/screens/investments_screen.dart';
import 'package:fintrack/screens/settings_screen.dart';
import 'package:fintrack/services/real_api_service.dart';

enum TopPage { wallet, investments, settings }

class TopAppBar extends StatefulWidget implements PreferredSizeWidget {
  final RealApiService api;
  final TopPage currentPage;
  final VoidCallback? onNotificationsPressed;

  const TopAppBar({
    super.key,
    required this.api,
    required this.currentPage,
    this.onNotificationsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  State<TopAppBar> createState() => _TopAppBarState();
}

class _TopAppBarState extends State<TopAppBar> {
  final ValueNotifier<bool> _hoverNotifier = ValueNotifier(false);

  @override
  void dispose() {
    _hoverNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF16213E),
      elevation: 0,
      title: Row(
        children: [
          GestureDetector(
            onTap: widget.currentPage != TopPage.wallet
                ? () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => WalletScreen(api: widget.api)),
                    )
                : null,
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 24, color: Colors.white),
                SizedBox(width: 4),
                Text('FinTrack',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 24),
          _topMenuButton(
            context: context,
            label: 'Кошелек',
            icon: Icons.account_balance_wallet_outlined,
            isActive: widget.currentPage == TopPage.wallet,
            onTap: widget.currentPage != TopPage.wallet
                ? () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => WalletScreen(api: widget.api)),
                    )
                : null,
          ),
          _topMenuButton(
            context: context,
            label: 'Инвестиции',
            icon: Icons.trending_up_outlined,
            isActive: widget.currentPage == TopPage.investments,
            onTap: widget.currentPage != TopPage.investments
                ? () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => InvestmentsScreen(api: widget.api)),
                    )
                : null,
          ),
          _topMenuButton(
            context: context,
            label: 'Настройки',
            icon: Icons.settings_outlined,
            isActive: widget.currentPage == TopPage.settings,
            onTap: widget.currentPage != TopPage.settings
                ? () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => SettingsScreen(api: widget.api)),
                    )
                : null,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 24, color: Colors.white),
          onPressed: widget.onNotificationsPressed,
        ),
        const CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFF3C4759),
          child: Icon(Icons.person, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _topMenuButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getButtonBackgroundColor(isActive: isActive, isHovered: isHovered),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: _getButtonColor(isActive: isActive, isHovered: isHovered),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: _getButtonColor(isActive: isActive, isHovered: isHovered),
                      fontSize: 16,
                      fontWeight: isHovered || isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getButtonBackgroundColor({required bool isActive, required bool isHovered}) {
    if (isActive) return Colors.white.withOpacity(0.15);
    if (isHovered) return Colors.white.withOpacity(0.08);
    return Colors.transparent;
  }

  Color _getButtonColor({required bool isActive, required bool isHovered}) {
    if (isActive || isHovered) return Colors.white;
    return Colors.grey;
  }
}