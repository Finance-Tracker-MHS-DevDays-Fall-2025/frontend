// lib/screens/investments_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fintrack/screens/wallet_screen.dart';
import 'package:fintrack/screens/settings_screen.dart';
import 'package:fintrack/services/real_api_service.dart'; // ← замена ApiService → RealApiService
import 'package:fintrack/models/dividend.dart';
import 'package:fintrack/models/balance.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  late final RealApiService api; // ← RealApiService
  double portfolioValue = 0;
  double profit = 0;
  double passiveIncome = 0;
  List<Dividend> dividends = [];
  BalanceSummary? balance;

  // Индекс активно выбранного актива (для подсветки и тултипа)
  int? _selectedAssetIndex;
  Offset? _tooltipPosition;

  @override
  void initState() {
    super.initState();
    api = RealApiService(userId: 'vlad_kartunov'); // ← фиксированный userId
    _loadData();
  }

  void _loadData() async {
    try {
      // Получаем баланс — investments = часть портфеля
      final bal = await api.getBalance();
      final divs = await api.getDividends();

      if (mounted) {
        setState(() {
          balance = bal;
          dividends = divs;

          // 💡 Пока нет /v1/portfolio, используем хардкод + investments из баланса
          // В будущем — заменить на реальный API-вызов
          portfolioValue = bal.investments + 95000; // ← mock: 5000 + 95000 = 100000
          profit = 12000;
          passiveIncome = divs.fold(0.0, (sum, d) => sum + d.amount);
        });
      }
    } catch (e) {
      print('❌ InvestmentsScreen _loadData error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Ошибка загрузки инвестиций')),
      );
    }
  }

  final List<Map<String, dynamic>> _assets = [
    {'name': 'Акции RU', 'value': 195810.0, 'profit': '+61707.74 ₽', 'share': '14.73%'},
    {'name': 'Акции US', 'value': 912204.0, 'profit': '+367972.70 ₽', 'share': '68.63%'},
    {'name': 'Облигации', 'value': 9751.0, 'profit': '+2534.27 ₽', 'share': '0.73%'},
    {'name': 'Криптовалюта', 'value': 169779.0, 'profit': '-26339.12 ₽', 'share': '12.77%'},
    {'name': 'Валюта', 'value': 41545.0, 'profit': '-', 'share': '3.13%'},
  ];

  final List<Color> _colors = [
    const Color(0xFF4A90E2), // Акции RU
    const Color(0xFF00C4B4), // Акции US
    const Color(0xFFA020F0), // Облигации
    const Color(0xFFFFD700), // Крипта
    const Color(0xFFE5E5E5), // Валюта
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Верхняя панель (меню) ===
            Container(
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
                  // Горизонтальное меню
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const WalletScreen()),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text('Кошелек', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Row(
                        children: [
                          Icon(Icons.trending_up_outlined, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Инвестиции', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.settings_outlined, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text('Настройки', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 24, color: Colors.white),
                    onPressed: () {},
                  ),
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF3C4759),
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            // === Основной контент ===
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Портфель',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    // Статистика
                    Row(
                      children: [
                        _buildStatCard(title: 'Стоимость', amount: portfolioValue, color: Colors.blue),
                        const SizedBox(width: 16),
                        _buildStatCard(title: 'Прибыль', amount: profit, color: Colors.green),
                        const SizedBox(width: 16),
                        _buildStatCard(title: 'Доходность', amount: 9.04, suffix: '%', color: Colors.orange),
                        const SizedBox(width: 16),
                        _buildStatCard(title: 'Пассивный доход', amount: passiveIncome, color: Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Круговая диаграмма + Активы
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: List.generate(
                                      _assets.length,
                                      (i) => PieChartSectionData(
                                        value: _assets[i]['value'] as double,
                                        color: _colors[i],
                                        radius: 80,
                                        showTitle: false,
                                      ),
                                    ),
                                    centerSpaceRadius: 60,
                                    sectionsSpace: 2,
                                  ),
                                ),
                              ),
                              if (_selectedAssetIndex != null && _tooltipPosition != null)
                                Positioned(
                                  left: _tooltipPosition!.dx - 80,
                                  top: _tooltipPosition!.dy - 30,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_assets[_selectedAssetIndex!]['name']}: '
                                      '${_assets[_selectedAssetIndex!]['value'].toStringAsFixed(0)} ₽ '
                                      '(${_assets[_selectedAssetIndex!]['share']})',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Активы',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                              const SizedBox(height: 8),
                              ...List.generate(
                                _assets.length,
                                (i) => _buildAssetRow(i),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Дивиденды
                    const Text('Полученные дивиденды',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                    const SizedBox(height: 8),
                    ...dividends.map((d) => _buildDividendTile(d)),
                  ],
                ),
              ),
            ),
            // === Кнопка «+» внизу справа ===
            Padding(
              padding: const EdgeInsets.only(right: 24, bottom: 24),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF00C4B4),
                onPressed: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Добавление актива — в разработке'))),
                child: const Icon(Icons.add, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required Color color,
    String suffix = '',
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(0)}$suffix',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetRow(int index) {
    final asset = _assets[index];
    final name = asset['name'] as String;
    final value = asset['value'] as double;
    final profit = asset['profit'] as String;
    final share = asset['share'] as String;
    final color = _colors[index];

    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _selectedAssetIndex = index;
          _tooltipPosition = event.localPosition + const Offset(100, 100);
        });
      },
      onExit: (_) {
        setState(() {
          _selectedAssetIndex = null;
          _tooltipPosition = null;
        });
      },
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Актив: $name')),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade700)),
            color: _selectedAssetIndex == index ? color.withOpacity(0.1) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                  Text(
                    '${value.toInt()} ₽',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                profit,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: profit.startsWith('+')
                      ? Colors.green
                      : profit == '-'
                          ? Colors.white
                          : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                share,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDividendTile(Dividend d) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade700)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_outlined, size: 20, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.name, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
              Text(
                '${d.date.day}.${d.date.month}.${d.date.year}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${d.amount.toStringAsFixed(2)} ₽',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}