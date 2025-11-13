// lib/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:fintrack/screens/investments_screen.dart';
import 'package:fintrack/screens/settings_screen.dart';
import 'package:fintrack/screens/history_screen.dart';
import 'package:fintrack/services/real_api_service.dart';
import 'package:fintrack/models/transaction.dart';
import 'package:fintrack/widgets/top_app_bar.dart';
import 'package:fintrack/screens/income_screen.dart';
import 'package:fintrack/screens/expense_screen.dart';

/// Форматирует сумму: 123456 → '123 456 ₽'
/// withSign: true → '+123 456 ₽' / '−12 345 ₽'
String formatRubles(double amount, {bool withSign = false}) {
  if (amount == 0) {
    return withSign ? '0 ₽' : '0 ₽';
  }

  final isNegative = amount < 0;
  final abs = amount.abs().toInt();

  final digits = abs.toString().split('').reversed.toList();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && i % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  final formatted = buffer.toString().split('').reversed.join('');

  String result = formatted;
  if (withSign) {
    result = '${isNegative ? '−' : '+'}$result';
  } else if (isNegative) {
    result = '−$result';
  }

  return '$result ₽';
}

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

  // 🔹 Ручные балансы по банкам (можно редактировать)
  final Map<String, double> _bankBalances = {
    'Т-банк': 15765.0,
    'Сбербанк': 24310.0,
    'ВТБ банк': 8945.0,
    'Наличные': 5000.0,
  };

  int _selectedPeriod = 0;

  final Map<String, String> _accountIdMap = {
    'acc_cash': 'a1111111-1111-1111-1111-111111111111',
    'acc_tbank': 'a1111111-1111-1111-1111-111111111111',
    'acc_sber': 'a1111111-1111-1111-1111-111111111112',
    'acc_vtb': 'a1111111-1111-1111-1111-111111111111',
  };

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

  void _showAddTransaction() async {
    final categories = await api.getCategories();
    String selectedCategoryId = categories.isNotEmpty ? categories.first.id : 'cat_other';
    String selectedType = 'income';
    final amountController = TextEditingController();
    final fromAccountController = TextEditingController(text: 'acc_cash');
    final dateController = TextEditingController(
      text: DateTime.now().toLocal().toIso8601String().split('T')[0],
    );
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Добавить операцию', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
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
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Категория',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: categories.map((cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (v) => setState(() => selectedCategoryId = v!),
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fromAccountController,
                    decoration: InputDecoration(
                      labelText: 'ID счёта',
                      helperText: 'acc_cash, acc_tbank и др.',
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
                  const Text('Тип операции', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => selectedType = 'income'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedType == 'income'
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey[800],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Доход', style: TextStyle(fontSize: 14, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => selectedType = 'expense'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedType == 'expense'
                                ? Colors.red.withOpacity(0.3)
                                : Colors.grey[800],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Расход', style: TextStyle(fontSize: 14, color: Colors.white)),
                        ),
                      ),
                    ],
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
                            final fromAccountIdRaw = fromAccountController.text.trim();

                            if (amountStr.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Введите сумму')),
                              );
                              return;
                            }
                            if (selectedCategoryId.isEmpty || selectedCategoryId == 'cat_other') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Выберите категорию')),
                              );
                              return;
                            }
                            if (fromAccountIdRaw.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Укажите ID счёта')),
                              );
                              return;
                            }

                            final amount = double.tryParse(amountStr);
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Сумма должна быть > 0')),
                              );
                              return;
                            }

                            final fromAccountId = _accountIdMap[fromAccountIdRaw] ?? fromAccountIdRaw;
                            final date = DateTime.tryParse('${dateController.text}T12:00:00') ??
                                DateTime.now();

                            String apiType = selectedType == 'income'
                                ? 'TRANSACTION_TYPE_INCOME'
                                : 'TRANSACTION_TYPE_EXPENSE';

                            api.createTransaction(
                              amount: amount,
                              categoryId: selectedCategoryId,
                              fromAccountId: fromAccountId,
                              date: date,
                              description: descriptionController.text.trim(),
                              type: apiType,
                            ).then((serverTx) {
                              if (mounted) {
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✅ Операция добавлена')),
                                );
                                Navigator.pop(context);
                              }
                            }).catchError((e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('❌ $e')),
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: TopAppBar(
        api: api,
        currentPage: TopPage.wallet,
        onNotificationsPressed: _showNotifications,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 1200,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Баланс', style: TextStyle(fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(
                        formatRubles(wallet + investments),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 1180,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 800,
                        child: _buildCenterPanel(),
                      ),
                      _buildRightPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HistoryScreen(api: api)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16213E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Center(child: Text('Операции')),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ExpenseScreen(api: api)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16213E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Center(child: Text('Расходы по категориям')),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => IncomeScreen(api: api)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16213E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Center(child: Text('Доходы по категориям')),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _monthlySummary(),
                    const SizedBox(height: 20),
                    _addTransactionButton(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 380,
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Банки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _bankBalances.entries.map((e) {
              return _buildBankCard(e.key, e.value);
            }).toList(),
          ),
          const SizedBox(height: 20),
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
                      Text(
                        formatRubles(wallet + investments),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatRubles(wallet, withSign: true),
                        style: TextStyle(
                          color: wallet >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
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
    );
  }

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

  Widget _monthlySummary() {
    return Container(
      width: double.infinity,
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
          ..._groupTransactionsByDateLast3Days(transactions).entries.map((entry) {
            final date = entry.key;
            final txs = entry.value;
            final dateString = _formatDate(date);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  dateString,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ...txs.map(_buildTransactionTile).toList(),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _addTransactionButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _showAddTransaction,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Добавить операцию', style: TextStyle(fontSize: 16, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16213E),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildBankCard(String name, double balance) {
    return GestureDetector(
      onTap: () => _showEditBankBalanceDialog(name, balance),
      child: SizedBox(
        width: 170,
        child: Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatRubles(balance),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                const Text('✎', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditBankBalanceDialog(String bankName, double currentBalance) {
    final controller = TextEditingController(text: currentBalance.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Редактировать баланс: $bankName', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Баланс (₽)',
            labelStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(ctx).pop,
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null) {
                setState(() {
                  _bankBalances[bankName] = val;
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Сохранить', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C4B4)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction t) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          t.description.isNotEmpty ? t.description : t.category,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '${t.date.day}.${t.date.month}.${t.date.year}',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Text(
          formatRubles(t.amount, withSign: true),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: t.amount >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Map<DateTime, List<Transaction>> _groupTransactionsByDateLast3Days(List<Transaction> transactions) {
    final grouped = <DateTime, List<Transaction>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threeDaysAgo = today.subtract(const Duration(days: 2));
    for (var tx in transactions) {
      final dateOnly = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (dateOnly.isBefore(threeDaysAgo)) continue;
      grouped.putIfAbsent(dateOnly, () => []).add(tx);
    }
    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    if (date == today) return 'Сегодня';
    if (date == yesterday) return 'Вчера';
    if (date == twoDaysAgo) return 'Позавчера';
    const months = ['', 'января', 'февраля', 'марта', 'апреля', 'мая',
      'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${date.day} ${months[date.month]}';
  }

Widget _buildRealBalanceChart(List<Transaction> txs, double baseBalance) {
  final sorted = List.of(txs)..sort((a, b) => a.date.compareTo(b.date));
  final points = <FlSpot>[];
  final now = DateTime.now();
  final startDay = DateTime(now.year, now.month, 1); // начало месяца
  final today = DateTime(now.year, now.month, now.day);
  final daysUpToToday = today.day;

  double balance = baseBalance;

  // Баланс до начала месяца
  for (var t in sorted) {
    if (t.date.isBefore(startDay)) balance -= t.amount;
  }

  // Точки по дням до сегодняшнего дня
  for (int i = 1; i <= daysUpToToday; i++) {
    final day = DateTime(now.year, now.month, i);
    final dayTxs = sorted.where((t) =>
        t.date.year == day.year &&
        t.date.month == day.month &&
        t.date.day == day.day);
    for (var t in dayTxs) balance += t.amount;
    points.add(FlSpot(i.toDouble(), balance));
  }

  // minY и maxY для графика с небольшим отступом
  final allY = points.map((p) => p.y).toList();
  final minY = allY.isEmpty ? 0.0 : allY.reduce(math.min) * 0.98;
  final maxY = allY.isEmpty ? baseBalance + 1000 : allY.reduce(math.max) * 1.02;

  return LineChart(
    LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false), // убрали рамку
      lineBarsData: [
        LineChartBarData(
          spots: points,
          isCurved: true,
          barWidth: 2,
          color: const Color(0xFF00C4B4),
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4A90E2).withOpacity(0.2),
                const Color(0xFF00C4B4).withOpacity(0.05),
              ],
            ),
          ),
        ),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value >= 1 && value <= daysUpToToday) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false, // убрали цифры слева
          ),
        ),
      ),
      minX: 1,
      maxX: daysUpToToday.toDouble(),
      minY: minY,
      maxY: maxY,
    ),
  );
}
}