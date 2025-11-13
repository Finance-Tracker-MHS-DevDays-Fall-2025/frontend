// lib/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:fintrack/screens/investments_screen.dart';
import 'package:fintrack/screens/settings_screen.dart';
import 'package:fintrack/screens/history_screen.dart';
import 'package:fintrack/screens/income_screen.dart';
import 'package:fintrack/screens/expense_screen.dart';
import 'package:fintrack/services/real_api_service.dart';
import 'package:fintrack/models/transaction.dart';

class WalletScreen extends StatefulWidget {
  final RealApiService api;
  const WalletScreen({super.key, required this.api});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final RealApiService api;
  double wallet = 0;
  double investments = 0;
  List<Transaction> transactions = [];
  int _selectedPeriod = 0; // переменная для кнопок периода

  @override
  void initState() {
    super.initState();
    api = widget.api;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Ошибка загрузки данных')),
        );
      }
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
              _buildTextField(amountController, 'Сумма (₽)', TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(categoryController, 'ID категории', TextInputType.text,
                  helperText: 'cat_food, cat_salary и др.'),
              const SizedBox(height: 12),
              _buildTextField(fromAccountController, 'ID счёта', TextInputType.text,
                  helperText: 'acc_cash, acc_tbank и др.'),
              const SizedBox(height: 12),
              _buildTextField(descriptionController, 'Описание', TextInputType.text),
              const SizedBox(height: 12),
              _buildTextField(dateController, 'Дата', TextInputType.datetime),
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
                        api.createTransaction(
                          amount: amount,
                          categoryId: categoryId,
                          fromAccountId: fromAccountId,
                          date: date,
                          description: descriptionController.text.trim(),
                        ).then((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ Операция добавлена')),
                            );
                            Navigator.pop(context);
                            _loadData();
                          }
                        }).catchError((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('❌ Ошибка при создании операции')),
                            );
                          }
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

  TextField _buildTextField(TextEditingController controller, String label, TextInputType type,
      {String? helperText}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 10, color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 24, color: Colors.white),
            const SizedBox(width: 4), // сдвинули левее
            const Text('FinTrack', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 24),
            _topMenuButton('Кошелек', Icons.account_balance_wallet_outlined, active: true),
            _topMenuButton('Инвестиции', Icons.trending_up_outlined, onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => InvestmentsScreen(api: api)),
              );
            }),
            _topMenuButton('Настройки', Icons.settings_outlined, onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen(api: api)),
              );
            }),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 24, color: Colors.white),
            onPressed: _showNotifications,
          ),
          const CircleAvatar(radius: 14, backgroundColor: Color(0xFF3C4759), child: Icon(Icons.person, size: 16, color: Colors.white)),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeftMenu(),
            _buildCenterPanel(),
            _buildRightPanel(),
          ],
        ),
      ),
    );
  }

  // ===================== Вспомогательные виджеты =====================
  Widget _topMenuButton(String label, IconData icon, {bool active = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: active ? Colors.white : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftMenu() {
    return SizedBox(
      width: 280,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen(api: api))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16213E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Center(child: Text('Операции')),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseScreen(api: api))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16213E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Center(child: Text('Расходы по категориям')),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncomeScreen(api: api))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16213E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Center(child: Text('Доходы по категориям')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPanel() {
    return Expanded(
      flex: 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _balanceBlock(),
            const SizedBox(height: 20),
            _monthlySummary(),
            const SizedBox(height: 20),
            _addTransactionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return SizedBox(
      width: 400,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Банки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildBankCard('Т-банк', '15 765 ₽'),
                _buildBankCard('Сбербанк', '15 765 ₽'),
                _buildBankCard('ВТБ банк', '15 765 ₽'),
                _buildBankCard('Наличные', '5 000 ₽'),
              ],
            ),
            const SizedBox(height: 28),
            Card(
              color: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Динамика баланса', style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('${(wallet + investments).toStringAsFixed(0)} ₽',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 6),
                        Text(
                          '${wallet >= 0 ? '+' : ''}${wallet.toStringAsFixed(0)} ₽',
                          style: TextStyle(color: wallet >= 0 ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 240,
                      child: _buildRealBalanceChart(transactions, wallet),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
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
          ],
        ),
      ),
    );
  }

  // ===================== Карточки и кнопки =====================
  Widget _buildPeriodButton(String label, int index) {
    return ElevatedButton(
      onPressed: () => setState(() => _selectedPeriod = index),
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedPeriod == index ? Colors.grey[700] : Colors.grey[800],
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _selectedPeriod == index ? Colors.white : Colors.grey[400],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _balanceBlock() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Баланс', style: TextStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            '${(wallet + investments).toStringAsFixed(0)} ₽',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _monthlySummary() {
    return Container(
      width: 380,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Итоги за месяц', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncomeScreen(api: api))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Доход'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseScreen(api: api))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.2),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Расход'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Операции', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
          const SizedBox(height: 12),
          ...transactions.take(5).map(_buildTransactionTile),
        ],
      ),
    );
  }

  Widget _addTransactionButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _showAddTransaction,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Добавить операцию', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C4B4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildBankCard(String name, String balance) {
    return SizedBox(
      width: 170,
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 14)),
              const SizedBox(height: 6),
              Text(balance, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction t) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(t.description ?? t.categoryId, style: const TextStyle(color: Colors.white)),
        subtitle: Text('${t.date.toLocal()}'.split(' ')[0], style: const TextStyle(color: Colors.grey)),
        trailing: Text(
          '${t.amount >= 0 ? '+' : ''}${t.amount.toStringAsFixed(0)} ₽',
          style: TextStyle(color: t.amount >= 0 ? Colors.green : Colors.red),
        ),
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
        gridData: FlGridData(show: true, drawVerticalLine: true, verticalInterval: 5),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            gradient: const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF00C4B4)]),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [const Color(0xFF4A90E2).withOpacity(0.2), const Color(0xFF00C4B4).withOpacity(0.05)],
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
