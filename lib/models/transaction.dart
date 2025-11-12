// lib/models/transaction.dart
class Transaction {
  final DateTime date;
  final double amount;
  final String type;      // 'income' | 'expense'
  final String category;
  final String source;    // ← ДОБАВЛЕНО: T-банк, Сбербанк, Наличные и т.д.
  Transaction({
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    required this.source,
  });
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'amount': amount,
        'type': type,
        'category': category,
        'source': source,
      };
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        date: DateTime.parse(json['date']),
        amount: (json['amount'] as num).toDouble(),
        type: json['type'],
        category: json['category'],
        source: json['source'],
      );
}