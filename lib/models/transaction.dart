// lib/models/transaction.dart
class Transaction {
  final String? id;
  final DateTime date;
  final double amount;
  final String type; // 'income' | 'expense' | 'transfer'
  final String category;
  final String categoryId;
  final String source;
  final String fromAccountId;
  final String toAccountId;
  final String description;

  Transaction({
    this.id,
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    required this.categoryId,
    required this.source,
    required this.fromAccountId,
    required this.toAccountId,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'type': type,
        'category': category,
        'categoryId': categoryId,
        'source': source,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'description': description,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String?,
        date: DateTime.parse(json['date']),
        amount: (json['amount'] as num).toDouble(),
        type: json['type'] as String,
        category: json['category'] as String,
        categoryId: json['categoryId'] as String? ?? '',
        source: json['source'] as String,
        fromAccountId: json['fromAccountId'] as String? ?? 'default-cash',
        toAccountId: json['toAccountId'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}