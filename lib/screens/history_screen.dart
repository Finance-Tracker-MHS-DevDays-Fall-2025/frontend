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
      if (mounted) setState(() => transactions = txs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка загрузки операций')));
      }
    }
  }

  void _showAddTransaction() async {
    final categories = await api.getCategories();
    String selectedCategoryId = categories.first.id;

    final amountController = TextEditingController();
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
          width: 300,
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
      selectedCategoryId = value;
    }
  },
  dropdownColor: const Color(0xFF1A1A2E),
  style: const TextStyle(color: Colors.black, fontSize: 16),
  underline: Container(),
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
                        final amount = double.tryParse(amountStr) ?? 0.0;
                        if (amount == 0) return;
                        final date = DateTime.tryParse('${dateController.text}T12:00:00') ?? DateTime.now();
                        api.createTransaction(
                          amount: amount,
                          categoryId: selectedCategoryId,
                          fromAccountId: accId,
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
                        }).catchError((e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('❌ $e')), // ← будет видна настоящая ошибка
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

  @override
  Widget build(BuildContext context) {
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
                  const Text('FinTrack', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  const Text('Операции', style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.notifications_outlined, size: 24, color: Colors.white), onPressed: () {}),
                  const CircleAvatar(radius: 14, backgroundColor: Color(0xFF3C4759), child: Icon(Icons.person, size: 16, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final t = transactions[index];
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
                            color: t.amount > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(t.amount > 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 20, color: t.amount > 0 ? Colors.green : Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.category, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                            Text('${t.date.day}.${t.date.month}.${t.date.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 24, bottom: 24),
              child: Align(
                alignment: Alignment.centerRight,
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
          ],
        ),
      ),
    );
  }
}