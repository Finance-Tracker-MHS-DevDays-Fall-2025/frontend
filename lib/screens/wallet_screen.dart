// lib/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:fintrack/screens/investments_screen.dart';
import 'package:fintrack/screens/settings_screen.dart';
import 'package:fintrack/screens/history_screen.dart';
import 'package:fintrack/screens/income_screen.dart';
import 'package:fintrack/screens/expense_screen.dart';
import 'package:fintrack/services/real_api_service.dart'; // ← заменено
import 'package:fintrack/models/transaction.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // ← ЗАМЕНА ApiService → RealApiService
  late final RealApiService api;
  double wallet = 0;
  double investments = 0;
  List<Transaction> transactions = [];

  @override
  void initState() {
    super.initState();
    // Используем фиксированный userId пока нет авторизации
    api = RealApiService(userId: 'vlad_kartunov');
    _loadData();
  }

  void _loadData() async {
    try {
      final balance = await api.getBalance();
      final txs = await api.getTransactions();
      if (mounted) {
        setState(() {
          wallet = balance.wallet;
          investments = balance.investments;
          transactions = txs;
        });
      }
    } catch (e) {
      print('❌ Failed to load data in WalletScreen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Ошибка загрузки данных')),
      );
    }
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Уведомления', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          height: 300,
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.email, color: Colors.green),
                title: const Text('Вы получили дивиденды', style: TextStyle(color: Colors.white)),
                subtitle: const Text('SBER, 25.5 ₽', style: TextStyle(color: Colors.grey)),
                trailing: const Text('Сегодня', style: TextStyle(color: Colors.grey)),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.attach_money, color: Colors.red),
                title: const Text('Расход превысил лимит', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Еда, -2000 ₽', style: TextStyle(color: Colors.grey)),
                trailing: const Text('Вчера', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddTransaction() {
    final amountController = TextEditingController();
    final categoryController = TextEditingController(text: 'cat_food');
    final fromAccountController = TextEditingController(text: 'acc_cash');
    final dateController = TextEditingController(
      text: DateTime.now().toLocal().toIso8601String().split('T')[0],
    );
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Добавить операцию', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 320,
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
                  labelText: 'ID категории (cat_food, cat_salary и т.д.)',
                  helperText: 'См. список в коде RealApiService',
                  helperStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fromAccountController,
                decoration: InputDecoration(
                  labelText: 'ID счёта (acc_cash, acc_tbank и т.д.)',
                  helperText: 'Например: acc_cash, acc_tbank',
                  helperStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание (опционально)',
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final amountStr = amountController.text.trim();
                        final categoryId = categoryController.text.trim();
                        final fromAccountId = fromAccountController.text.trim();
                        if (amountStr.isEmpty || categoryId.isEmpty || fromAccountId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Заполните сумму, категорию и счёт')),
                          );
                          return;
                        }

                        final amount = double.tryParse(amountStr) ?? 0.0;
                        if (amount == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Сумма не может быть 0')),
                          );
                          return;
                        }

                        final date = DateTime.tryParse('${dateController.text}T12:00:00') ??
                            DateTime.now();

                        // 🚀 Отправляем в API
                        api.createTransaction(
                          amount: amount,
                          categoryId: categoryId,
                          fromAccountId: fromAccountId,
                          date: date,
                          description: descriptionController.text.trim(),
                        ).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Операция добавлена')),
                          );
                          Navigator.pop(context);
                          _loadData();
                        }).catchError((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('❌ Ошибка при создании операции')),
                          );
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
        title: const Text('FinTrack', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 20, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Кошелек', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestmentsScreen())),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up_outlined, size: 20, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Инвестиции', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 20, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Настройки', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24, color: Colors.white),
                onPressed: _showNotifications,
              ),
              const CircleAvatar(radius: 14, backgroundColor: Color(0xFF3C4759), child: Icon(Icons.person, size: 16, color: Colors.white)),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Левая колонка
            SizedBox(
              width: 200,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16213E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Операции'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16213E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Расходы по категориям'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16213E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Доходы по категориям'),
                    ),
                  ],
                ),
              ),
            ),
            // Центр
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Баланс', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          '${(wallet + investments).toStringAsFixed(0)} ₽',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Банки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBankCard('T-банк', '15 765 ₽'),
                        const SizedBox(width: 16),
                        _buildBankCard('Сбербанк', '15 765 ₽'),
                        const SizedBox(width: 16),
                        _buildBankCard('ВТБ банк', '15 765 ₽'),
                        const SizedBox(width: 16),
                        _buildBankCard('Наличные', '5 000 ₽'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          const Text('Подключите свои счета', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Подключение T-Банка — в разработке'))),
                                  child: const Text('Подключить T-Банк', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Подключение T-Инвестиции — в разработке'))),
                                  child: const Text('Подключить T-Инвестиции', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeScreen())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.2),
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Доход'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseScreen())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.2),
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Расход'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Последние операции', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                        ElevatedButton.icon(
                          onPressed: _showAddTransaction,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Добавить операцию', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C4B4),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...transactions.take(5).map(_buildTransactionTile),
                  ],
                ),
              ),
            ),
            // Правая колонка — график
            SizedBox(
              width: 380,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Динамика баланса', style: TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('${(wallet + investments).toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(width: 8),
                            Text(
                              '${wallet >= 0 ? '+' : ''}${wallet.toStringAsFixed(0)} ₽',
                              style: TextStyle(color: wallet >= 0 ? Colors.green : Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: _buildRealBalanceChart(transactions, wallet),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _buildPeriodButton('Этот месяц', 0),
                            _buildPeriodButton('3 м', 1),
                            _buildPeriodButton('1 г', 2),
                            _buildPeriodButton('Ещё', 3),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _selectedPeriod = 0;

  Widget _buildPeriodButton(String label, int index) => ElevatedButton(
        onPressed: () => setState(() => _selectedPeriod = index),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedPeriod == index ? Colors.grey[700] : Colors.grey[800],
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _selectedPeriod == index ? Colors.white : Colors.grey[400],
            fontSize: 12,
          ),
        ),
      );

  Widget _buildBankCard(String name, String balance) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
            Text(balance, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction t) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade700))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.amount > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(t.amount > 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 18, color: t.amount > 0 ? Colors.green : Colors.red),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.category, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
              Text('${t.date.day}.${t.date.month}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          Text(
            '${t.amount > 0 ? '+' : ''}${t.amount.abs().toStringAsFixed(0)} ₽',
            style: TextStyle(fontWeight: FontWeight.bold, color: t.amount > 0 ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildRealBalanceChart(List<Transaction> txs, double baseBalance) {
    final sorted = List.of(txs)..sort((a, b) => a.date.compareTo(b.date));
    final points = <FlSpot>[];
    double balance = baseBalance;
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day - 30);
    points.add(FlSpot(0, balance));

    for (int i = 1; i <= 30; i++) {
      final day = startDay.add(Duration(days: i));
      for (var t in sorted) {
        if (t.date.year == day.year && t.date.month == day.month && t.date.day == day.day) {
          balance += t.amount;
        }
      }
      points.add(FlSpot(i.toDouble(), balance));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: 5,
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF00C4B4)],
              stops: [0.0, 1.0],
            ),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A90E2).withOpacity(0.2),
                  const Color(0xFF00C4B4).withOpacity(0.05),
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 == 0 || value == 0 || value == 30) {
                  return Text('${value.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minX: 0,
        maxX: 30,
        minY: points.map((p) => p.y).reduce(math.min) - 500,
        maxY: points.map((p) => p.y).reduce(math.max) + 500,
      ),
    );
  }
}