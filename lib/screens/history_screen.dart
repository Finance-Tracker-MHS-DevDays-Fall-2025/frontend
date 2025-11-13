// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/services/real_api_service.dart';
import 'package:fintrack/models/transaction.dart';

class HistoryScreen extends StatefulWidget {
  final RealApiService api;
  const HistoryScreen({super.key, required this.api});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final RealApiService api;
  List<Transaction> transactions = [];

  @override
  void initState() {
    super.initState();
    api = widget.api;
    _loadData();
  }

  void _loadData() async {
    try {
      final txs = await api.getTransactions();
      if (mounted) {
        setState(() => transactions = txs);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки операций')),
        );
      }
    }
  }

  void _showAddTransaction() async {
    try {
      final categories = await api.getCategories();
      String selectedCategoryId = categories.isNotEmpty ? categories.first.id : 'cat_other';
      String selectedType = 'income'; // по умолчанию
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
              width: 300,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Сумма',
                        labelStyle: const TextStyle(color: Colors.white),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: selectedCategoryId,
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(
                            cat.name,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedCategoryId = value);
                        }
                      },
                      dropdownColor: const Color(0xFF1A1A2E),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      underline: Container(),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    // 🔹 Выбор типа: доход/расход
                    const Text('Тип операции', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() => selectedType = 'income'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedType == 'income' ? Colors.green.withOpacity(0.3) : Colors.grey[800],
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
                              backgroundColor: selectedType == 'expense' ? Colors.red.withOpacity(0.3) : Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Расход', style: TextStyle(fontSize: 14, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fromAccountController,
                      decoration: InputDecoration(
                        labelText: 'ID счёта',
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
                              final accId = fromAccountController.text.trim();
                              if (amountStr.isEmpty || accId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Заполните сумму и счёт')),
                                );
                                return;
                              }
                              final amount = double.tryParse(amountStr);
                              if (amount == null || amount == 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Некорректная сумма')),
                                );
                                return;
                              }

                              final date = DateTime.tryParse('${dateController.text}T12:00:00') ?? DateTime.now();

                              // ✅ ОПРЕДЕЛЯЕМ ТИП ДЛЯ API
                              String apiType;
                              if (selectedType == 'income') {
                                apiType = 'TRANSACTION_TYPE_INCOME';
                              } else {
                                apiType = 'TRANSACTION_TYPE_EXPENSE';
                              }

                              // ✅ ПЕРЕДАЁМ ОБЯЗАТЕЛЬНЫЙ ПАРАМЕТР `type`
                              api.createTransaction(
                                amount: amount.abs(), // серверу — положительное число
                                categoryId: selectedCategoryId,
                                fromAccountId: accId,
                                date: date,
                                description: descriptionController.text.trim(),
                                type: apiType, // ← КЛЮЧЕВОЕ — устраняет ошибку
                              ).then((newTx) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('✅ Операция добавлена')),
                                  );
                                  Navigator.pop(context);
                                  _loadData(); // ✅ обновить ВСЮ историю
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить категории')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupTransactionsByDate(transactions);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Операции', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final entry = grouped.entries.toList()[index];
                      final date = entry.key;
                      final txs = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildDateHeader(date),
                          const SizedBox(height: 8),
                          ...txs.map((t) => _buildTransactionItem(t)).toList(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 24, bottom: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ElevatedButton.icon(
                    onPressed: _showAddTransaction,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Добавить операцию', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C4B4),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  Widget _buildDateHeader(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Text(
        _formatDate(date),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction t) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.amount > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              t.amount > 0 ? Icons.arrow_upward : Icons.arrow_downward,
              size: 20,
              color: t.amount > 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.category,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${t.date.day}.${t.date.month}.${t.date.year} ${t.date.hour}:${t.date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // ✅ ЕДИНАЯ ФОРМУЛА ДЛЯ ВСЕХ ЭКРАНОВ
          Text(
            '${t.amount.sign == 1 ? '+' : '−'}${t.amount.abs().toStringAsFixed(0)} ₽',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: t.amount >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final grouped = <DateTime, List<Transaction>>{};
    for (var tx in transactions) {
      final dateOnly = DateTime(tx.date.year, tx.date.month, tx.date.day);
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
}