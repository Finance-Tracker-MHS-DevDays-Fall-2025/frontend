// lib/screens/income_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fintrack/screens/settings_screen.dart';
import 'package:fintrack/screens/investments_screen.dart';
import 'package:fintrack/services/real_api_service.dart';
import 'package:fintrack/models/transaction.dart';
import 'package:fintrack/models/forecast.dart';

class IncomeScreen extends StatefulWidget {
  final RealApiService api;
  final String? title;
  const IncomeScreen({super.key, required this.api, this.title = 'Доходы'});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  late final RealApiService api;
  List<Transaction> incomes = [];
  List<ForecastPeriod> forecastPeriods = [];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    api = widget.api;
    _loadData();
  }

  void _loadData() async {
    try {
      final txs = await api.getTransactions();
      final forecasts = await api.getForecast(period: 'TIME_PERIOD_MONTH', periodsAhead: 3);
      if (mounted) {
        setState(() {
          incomes = txs.where((t) => t.type == 'income').toList();
          forecastPeriods = forecasts;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('⚠️ Ошибка загрузки доходов')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: Text(widget.title ?? 'Доходы', style: const TextStyle(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up_outlined, size: 24, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => InvestmentsScreen(api: api)));
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(api: api)));
            },
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF3C4759),
            child: Icon(Icons.person, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Row(
                children: [
                  Text(
                    widget.title ?? 'Доходы',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  _buildTabButton('Главная', 0),
                  const SizedBox(width: 8),
                  _buildTabButton('Прогноз', 1),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _tabIndex == 0 ? _buildMainTab() : _buildForecastTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _tabIndex == index ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: () => setState(() => _tabIndex = index),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(
          text,
          style: TextStyle(
            color: _tabIndex == index ? Colors.white : Colors.grey[400],
            fontWeight: _tabIndex == index ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMainTab() {
    final Map<String, double> categoryMap = {};
    for (var t in incomes) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0.0) + t.amount.abs();
    }
    final categories = categoryMap.keys.toList();
    final pieSections = categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final color = Colors.primaries[index % Colors.primaries.length].shade400;
      return PieChartSectionData(
        value: categoryMap[category]!,
        color: color,
        radius: 70,
        showTitle: false,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('По категориям',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: pieSections,
              centerSpaceRadius: 60,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: categories.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            final color = Colors.primaries[index % Colors.primaries.length].shade400;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: color),
                const SizedBox(width: 6),
                Text(name, style: const TextStyle(color: Colors.white)),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Последние доходы',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
        const SizedBox(height: 12),
        ...incomes.take(5).map(_buildTransactionTile),
      ],
    );
  }

  Widget _buildForecastTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Прогноз доходов',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
        const SizedBox(height: 12),
        ...forecastPeriods.asMap().entries.map((entry) {
          final f = entry.value;
          return _buildForecastCard(
            title: f.formatPeriodName(),
            subtitle: 'Ожидаемо: +${f.expectedIncome.toStringAsFixed(0)} ₽',
            color: Colors.green,
            onTap: () {
              final incomeCats = f.categoryBreakdown
                  .where((c) => c.totalAmount > 0)
                  .map((c) => '${_getCategoryName(c.categoryId)}: ${c.totalAmount.toStringAsFixed(0)} ₽')
                  .join('\n');
              if (incomeCats.isNotEmpty && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Источники:\n$incomeCats')),
                );
              }
            },
          );
        }).toList(),
      ],
    );
  }

  String _getCategoryName(String id) {
    final map = {
      'cat_salary': 'Зарплата',
      'cat_food': 'Еда',
      'cat_transport': 'Транспорт',
      'cat_freelance': 'Подработка',
      'cat_rent': 'Аренда',
      'cat_dividends': 'Дивиденды',
      'cat_crypto': 'Криптовалюта',
      'cat_shopping': 'Покупки',
      'cat_entertainment': 'Развлечения',
    };
    return map[id] ?? 'Другое';
  }

  Widget _buildForecastCard({
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey[900],
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.work, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction t) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade700))),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_upward, size: 20, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.category, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
              Text(
                '${t.date.day}.${t.date.month}.${t.date.year}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${t.amount.sign == 1 ? '+' : '−'}${t.amount.abs().toStringAsFixed(0)} ₽',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }
}