// lib/models/transaction.dart

class CategoryInfo {
  final String id;
  final String name;
  const CategoryInfo({required this.id, required this.name});
}

CategoryInfo determineCategory({
  int? mcc,
  String apiType = '',
  String description = '',
}) {
  final mccMap = <int, CategoryInfo>{
    5411: const CategoryInfo(id: 'cat_food', name: 'Еда'),
    5422: const CategoryInfo(id: 'cat_food', name: 'Еда'),
    5441: const CategoryInfo(id: 'cat_food', name: 'Еда'),
    5451: const CategoryInfo(id: 'cat_food', name: 'Еда'),
    5499: const CategoryInfo(id: 'cat_food', name: 'Еда'),

    5811: const CategoryInfo(id: 'cat_entertainment', name: 'Развлечения'),
    5812: const CategoryInfo(id: 'cat_entertainment', name: 'Развлечения'),
    5813: const CategoryInfo(id: 'cat_entertainment', name: 'Развлечения'),
    5814: const CategoryInfo(id: 'cat_entertainment', name: 'Развлечения'),

    5541: const CategoryInfo(id: 'cat_transport', name: 'Транспорт'),
    4111: const CategoryInfo(id: 'cat_transport', name: 'Транспорт'),
    4121: const CategoryInfo(id: 'cat_transport', name: 'Транспорт'),
    4131: const CategoryInfo(id: 'cat_transport', name: 'Транспорт'),
    4511: const CategoryInfo(id: 'cat_transport', name: 'Транспорт'),

    5311: const CategoryInfo(id: 'cat_shopping', name: 'Покупки'),
    5732: const CategoryInfo(id: 'cat_shopping', name: 'Покупки'),
    5944: const CategoryInfo(id: 'cat_shopping', name: 'Покупки'),
    5999: const CategoryInfo(id: 'cat_shopping', name: 'Покупки'),

    7011: const CategoryInfo(id: 'cat_entertainment', name: 'Развлечения'),
    7832: const CategoryInfo(id: 'cat_entertainment', name: 'Развлечения'),
    4812: const CategoryInfo(id: 'cat_other', name: 'Прочее'),
    8099: const CategoryInfo(id: 'cat_other', name: 'Прочее'),
  };

  if (mcc != null && mccMap.containsKey(mcc)) {
    return mccMap[mcc]!;
  }

  final lower = description.toLowerCase();

  if (apiType.contains('INCOME')) {
    if (lower.contains('зарплат') || lower.contains('оклад') || lower.contains('аванс')) {
      return const CategoryInfo(id: 'cat_salary', name: 'Зарплата');
    }
    if (lower.contains('премия') || lower.contains('бонус')) {
      return const CategoryInfo(id: 'cat_salary', name: 'Премия');
    }
    if (lower.contains('фриланс') || lower.contains('проект') || lower.contains('работ')
        || lower.contains('usdt') || lower.contains('crypto') || lower.contains('eth') || lower.contains('btc')) {
      return const CategoryInfo(id: 'cat_freelance', name: 'Подработка');
    }
    if (lower.contains('дивиденд')) {
      return const CategoryInfo(id: 'cat_dividends', name: 'Дивиденды');
    }
    return const CategoryInfo(id: 'cat_salary', name: 'Зарплата');
  }

  if (lower.contains('продукт') || lower.contains('еда') && !lower.contains('кафе')) {
    return const CategoryInfo(id: 'cat_food', name: 'Еда');
  }
  if (lower.contains('кофе') || lower.contains('кафе') || lower.contains('ресторан')
      || lower.contains('ланч') || lower.contains('бар') || lower.contains('столов')) {
    return const CategoryInfo(id: 'cat_entertainment', name: 'Развлечения');
  }
  if (lower.contains('азс') || lower.contains('бензин') || lower.contains('лукойл')
      || lower.contains('роснефть') || lower.contains('газпром')) {
    return const CategoryInfo(id: 'cat_transport', name: 'Транспорт');
  }
  if (lower.contains('такси') || lower.contains('яндекс') || lower.contains('bolt') || lower.contains('транспорт')) {
    return const CategoryInfo(id: 'cat_transport', name: 'Транспорт');
  }
  if (lower.contains('кино') || lower.contains('театр') || lower.contains('концерт') || lower.contains('боул')) {
    return const CategoryInfo(id: 'cat_entertainment', name: 'Развлечения');
  }
  if (lower.contains('wildberries') || lower.contains('ozon') || lower.contains('али') || lower.contains('ламода')
      || lower.contains('м.видео') || lower.contains('leroy') || lower.contains('покупк')) {
    return const CategoryInfo(id: 'cat_shopping', name: 'Покупки');
  }

  return const CategoryInfo(id: 'cat_other', name: 'Прочее');
}

class Transaction {
  final String? id;
  final DateTime date;
  final double amount;
  final String type;
  final String category;
  final String source;
  final String fromAccountId;
  final String toAccountId;
  final String description;
  final int? mcc;

  Transaction({
    this.id,
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    this.mcc,
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
        'source': source,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'description': description,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final rawAmount = _parseAmount(json['amount']);
    double finalAmount = rawAmount;

    String appType = 'unknown';
    final apiType = (json['type'] as String?)?.toUpperCase() ?? '';
    if (apiType == 'TRANSACTION_TYPE_INCOME' || apiType == 'INCOME') {
      appType = 'income';
      finalAmount = rawAmount.abs();
    } else if (apiType == 'TRANSACTION_TYPE_EXPENSE' || apiType == 'EXPENSE') {
      appType = 'expense';
      finalAmount = -rawAmount.abs();
    } else if (apiType == 'TRANSACTION_TYPE_TRANSFER' || apiType == 'TRANSFER') {
      appType = 'transfer';
    } else {
      appType = rawAmount >= 0 ? 'income' : 'expense';
      finalAmount = appType == 'expense' ? -rawAmount.abs() : rawAmount.abs();
    }

    DateTime parsedDate = DateTime.now();
    final dateStr = json['date'] ?? json['created_at'];
    if (dateStr is String) {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) parsedDate = dt;
    }

    final mcc = (json['mcc'] as num?)?.toInt();
    final description = (json['description'] as String?) ?? '';

    final categoryInfo = determineCategory(
      mcc: mcc,
      apiType: apiType,
      description: description,
    );

    return Transaction(
      id: (json['id'] as String?) ?? '',
      date: parsedDate,
      amount: finalAmount,
      type: appType,
      category: categoryInfo.name,
      mcc: mcc,
      source: 'API',
      fromAccountId: (json['fromAccountId'] as String?) ??
          (json['account_id'] as String?) ??
          (json['accountId'] as String?) ??
          '',
      toAccountId: (json['toAccountId'] as String?) ?? (json['to_account_id'] as String?) ?? '',
      description: description,
    );
  }

  static double _parseAmount(dynamic amountField) {
    if (amountField == null) return 0.0;
    if (amountField is Map) {
      final s = amountField['amount'];
      if (s is String) return double.tryParse(s.replaceAll(' ', '')) ?? 0.0;
      if (s is num) return s.toDouble();
    }
    if (amountField is num) return amountField.toDouble();
    if (amountField is String) return double.tryParse(amountField.replaceAll(' ', '')) ?? 0.0;
    return 0.0;
  }
}