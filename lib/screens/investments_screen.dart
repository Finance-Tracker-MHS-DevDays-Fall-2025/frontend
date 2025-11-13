// lib/screens/investments_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fintrack/screens/wallet_screen.dart';
import 'package:fintrack/screens/settings_screen.dart';
import 'package:fintrack/services/real_api_service.dart';
import 'package:fintrack/models/dividend.dart';

class InvestmentsScreen extends StatefulWidget {
  final RealApiService api;
  const InvestmentsScreen({super.key, required this.api});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen>
    with SingleTickerProviderStateMixin {
  late final RealApiService api;
  late final TabController _tabController;

  double portfolioValue = 0;
  double profit = 0;
  double passiveIncome = 0;
  List<Dividend> dividends = [];
  int? touchedIndex;

  final List<Map<String, dynamic>> _assets = [
    {'name': 'Акции RU', 'value': 195810.0, 'profit': '+61707.74 ₽', 'share': '14.73%'},
    {'name': 'Акции US', 'value': 912204.0, 'profit': '+367972.70 ₽', 'share': '68.63%'},
    {'name': 'Облигации', 'value': 9751.0, 'profit': '+2534.27 ₽', 'share': '0.73%'},
    {'name': 'Криптовалюта', 'value': 169779.0, 'profit': '-26339.12 ₽', 'share': '12.77%'},
    {'name': 'Валюта', 'value': 41545.0, 'profit': '-', 'share': '3.13%'},
  ];

  final List<Color> _colors = [
    const Color(0xFF4A90E2),
    const Color(0xFF00C4B4),
    const Color(0xFFA020F0),
    const Color(0xFFFFD700),
    const Color(0xFFE5E5E5),
  ];

  @override
  void initState() {
    super.initState();
    api = widget.api;
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() async {
    try {
      final bal = await api.getBalance();
      final divs = await api.getDividends();
      if (mounted) {
        setState(() {
          portfolioValue = (bal.investments ?? 0) + 95000;
          profit = 12000;
          passiveIncome = divs.fold(0.0, (sum, d) => sum + (d.amount ?? 0));
          dividends = divs;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Ошибка загрузки инвестиций')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopMenu(),
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF00C4B4),
              tabs: const [
                Tab(text: 'Портфель'),
                Tab(text: 'Дивиденды'),
                Tab(text: 'Доход'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPortfolioTab(),
                  _buildDividendsTab(),
                  _buildIncomeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMenu() {
    return Container(
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
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WalletScreen(api: api))),
            child: Row(
              children: const [
                Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text('Кошелек', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.trending_up_outlined, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text('Инвестиции', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.notifications_outlined, size: 24, color: Colors.white), onPressed: () {}),
          const CircleAvatar(radius: 14, backgroundColor: Color(0xFF3C4759), child: Icon(Icons.person, size: 16, color: Colors.white)),
        ],
      ),
    );
  }

  // ------------------ Вкладка 1: Портфель ------------------
  Widget _buildPortfolioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortfolioStats(),
          const SizedBox(height: 32),
          _buildAssetsSection(),
        ],
      ),
    );
  }

  Widget _buildPortfolioStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Портфель', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(title: 'Стоимость', amount: portfolioValue, color: Colors.white),
            const SizedBox(width: 16),
            _buildStatCard(title: 'Прибыль', amount: profit, color: Colors.white),
            const SizedBox(width: 16),
            _buildStatCard(title: 'Доходность', amount: 9.04, suffix: '%', color: Colors.white),
            const SizedBox(width: 16),
            _buildStatCard(title: 'Пассивный доход', amount: passiveIncome, color: Colors.white),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required double amount, required Color color, String suffix = ''}) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 14)),
            const SizedBox(height: 4),
            Text('${amount.toStringAsFixed(0)}$suffix', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: List.generate(_assets.length, (i) {
                  final isTouched = i == touchedIndex;
                  final double radius = isTouched ? 90 : 80;
                  return PieChartSectionData(
                    value: _assets[i]['value'] as double,
                    color: _colors[i],
                    radius: radius,
                    showTitle: false,
                    badgeWidget: isTouched ? _buildBadge(_assets[i]) : null,
                    badgePositionPercentageOffset: 1.2,
                  );
                }),
                centerSpaceRadius: 60,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    setState(() {
                      if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      } else {
                        touchedIndex = null;
                      }
                    });
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(flex: 3, child: Text('Название', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Вложено', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Доход', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Доля', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_assets.length, (i) => _buildAssetRow(i)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(Map<String, dynamic> asset) {
    final value = asset['value'] as double;
    final share = asset['share'] as String;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(asset['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
          Text('${value.toInt()} ₽', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(share, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAssetRow(int index) {
    final asset = _assets[index];
    final name = asset['name'] as String;
    final value = asset['value'] as double;
    final profit = asset['profit'] as String;
    final share = asset['share'] as String;

    return GestureDetector(
      onTap: () {
        setState(() {
          touchedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(name, style: const TextStyle(color: Colors.white))),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${value.toInt()} ₽', style: const TextStyle(color: Colors.white)),
                  Text('Вложено', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(profit, style: TextStyle(color: profit.startsWith('+') ? Colors.green : profit == '-' ? Colors.white : Colors.red))),
            Expanded(flex: 2, child: Text(share, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  // ------------------ Вкладка 2: Дивиденды ------------------
  Widget _buildDividendsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: dividends.length,
      itemBuilder: (context, index) {
        final d = dividends[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade700))),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.payments_outlined, size: 20, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                  Text('${d.date.day}.${d.date.month}.${d.date.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              Text('${d.amount.toStringAsFixed(2)} ₽', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(title: 'Общий доход', amount: 54000, color: Colors.white),
          const SizedBox(height: 16),
          _buildStatCard(title: 'Доход от активов', amount: 32000, color: Colors.white),
          const SizedBox(height: 16),
          _buildStatCard(title: 'Пассивный доход', amount: passiveIncome, color: Colors.white),
        ],
      ),
    );
  }
}
