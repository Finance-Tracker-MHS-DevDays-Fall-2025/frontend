// lib/screens/income_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fintrack/screens/settings_screen.dart';
import 'package:fintrack/screens/investments_screen.dart';
import 'package:fintrack/services/real_api_service.dart';
import 'package:fintrack/models/transaction.dart';
import 'package:fintrack/models/forecast.dart'; // ← ДОБАВЛЕНО

class IncomeScreen extends StatefulWidget {
  final String? title;
  const IncomeScreen({super.key, this.title = 'Доходы'});
  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  late final RealApiService api;
  List<Transaction> incomes = [];
  List<ForecastPeriod> forecastPeriods = []; // ← ДОБАВЛЕНО
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    api = RealApiService(userId: 'vlad_kartunov');
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
      print('❌ IncomeScreen load error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('⚠️ Ошибка загрузки доходов и прогноза')));
    }
  }

  void _showAddTransaction() {
    final amountController = TextEditingController();
    final categoryController = TextEditingController(text: 'cat_salary');
    final fromAccountController = TextEditingController(text: 'acc_cash');
    final dateController = TextEditingController(
      text: DateTime.now().toLocal().toIso8601String().split('T')[0],
    );
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Добавить доход', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Сумма (₽)',
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'ID категории',
                  helperText: 'cat_salary, cat_freelance, cat_dividends...',
                  helperStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fromAccountController,
                decoration: InputDecoration(
                  labelText: 'ID счёта',
                  helperText: 'acc_cash, acc_tbank, acc_sber...',
                  helperStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Дата',
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C4B4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final amountStr = amountController.text.trim();
                        final catId = categoryController.text.trim();
                        final accId = fromAccountController.text.trim();
                        if (amountStr.isEmpty || catId.isEmpty || accId.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Заполните все обязательные поля')));
                          return;
                        }
                        final amount = double.tryParse(amountStr) ?? 0.0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Сумма должна быть > 0')));
                          return;
                        }
                        final date = DateTime.tryParse('${dateController.text}T12:00:00') ??
                            DateTime.now();
                        api.createTransaction(
                          amount: amount,
                          categoryId: catId,
                          fromAccountId: accId,
                          date: date,
                          description: descriptionController.text.trim(),
                        ).then((_) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('✅ Доход добавлен')));
                          Navigator.pop(context);
                          _loadData();
                        }).catchError((_) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('❌ Ошибка сохранения')));
                        });
                      },
                      child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
              Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestmentsScreen()));
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Последние доходы',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
            TextButton.icon(
              onPressed: _showAddTransaction,
              icon: const Icon(Icons.add, size: 16, color: Colors.green),
              label: const Text('Добавить', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
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
          final i = entry.key;
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
              if (incomeCats.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Источники:\n$incomeCats'),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
          );
        }).toList(),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _showAddTransaction,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Добавить источник'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.withOpacity(0.2),
            foregroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
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
            '+${t.amount.abs().toStringAsFixed(0)} ₽',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }
}