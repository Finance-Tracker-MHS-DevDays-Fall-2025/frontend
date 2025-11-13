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
    this.source = 'API',
    this.fromAccountId = '',
    this.toAccountId = '',
    this.description = '',
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

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // 🔹 1. Парсим сумму
    final rawAmount = _parseAmount(json['amount']);
    double finalAmount = rawAmount;

    // 🔹 2. Определяем тип операции
    String appType = 'unknown';
    final apiType = json['type'] as String?;
    if (apiType == 'TRANSACTION_TYPE_INCOME') {
      appType = 'income';
      finalAmount = rawAmount.abs();
    } else if (apiType == 'TRANSACTION_TYPE_EXPENSE') {
      appType = 'expense';
      finalAmount = -rawAmount.abs();
    } else if (apiType == 'TRANSACTION_TYPE_TRANSFER') {
      appType = 'transfer';
      // transfer — сумма всегда положительная (движение между счетами)
    } else {
      // fallback
      appType = rawAmount >= 0 ? 'income' : 'expense';
      finalAmount = appType == 'expense' ? -rawAmount.abs() : rawAmount.abs();
    }

    // 🔹 3. Парсим дату
    DateTime parsedDate = DateTime.now();
    final dateStr = json['date'] ?? json['created_at'];
    if (dateStr is String) {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) parsedDate = dt;
    }

    // 🔹 4. 🔥 КРИТИЧЕСКИ ВАЖНО: извлекаем categoryId из "category": "63"
    String categoryId = '';
    final catField = json['category'];

    // Пытаемся получить categoryId из:
    // 1. categoryId
    categoryId = (json['categoryId'] as String?) ?? '';
    // 2. category_id
    if (categoryId.isEmpty) {
      categoryId = (json['category_id'] as String?) ?? '';
    }
    // 3. category как строки (например "63", "cat_salary")
    if (categoryId.isEmpty && catField is String) {
      categoryId = catField;
    }
    // 4. category как объекта { "id": "cat_salary" }
    if (categoryId.isEmpty && catField is Map<String, dynamic>) {
      categoryId = catField['id'] as String? ?? '';
    }

    final category = _getCategoryName(categoryId);

    // 🔹 5. Возвращаем объект
    return Transaction(
      id: (json['id'] as String?) ?? '',
      date: parsedDate,
      amount: finalAmount,
      type: appType,
      category: category,
      categoryId: categoryId,
      source: 'API',
      fromAccountId: (json['fromAccountId'] as String?) ??
          (json['account_id'] as String?) ??
          (json['accountId'] as String?) ??
          '',
      toAccountId: (json['toAccountId'] as String?) ?? (json['to_account_id'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
    );
  }

  static double _parseAmount(dynamic amountField) {
    if (amountField == null) return 0.0;

    // { "amount": "123", "currency": "RUB" }
    if (amountField is Map) {
      final s = amountField['amount'];
      if (s is String) return double.tryParse(s) ?? 0.0;
      if (s is num) return s.toDouble();
    }

    // Прямое число: 123, 123.0
    if (amountField is num) return amountField.toDouble();

    // Строка: "123"
    if (amountField is String) return double.tryParse(amountField) ?? 0.0;

    return 0.0;
  }

  static String _getCategoryName(String id) {
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
}