// lib/services/real_api_service.dart
import 'package:dio/dio.dart';
import 'package:fintrack/models/transaction.dart';
import 'package:fintrack/models/balance.dart';
import 'package:fintrack/models/dividend.dart';
import 'package:fintrack/models/forecast.dart';

class Category {
  final String id;
  final String name;
  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Без названия',
    );
  }
}

class RealApiService {
  final Dio _dio;
  final String userId;

  RealApiService({
    String baseUrl = 'http://158.160.202.247:8080', // ✅ Публичный сервер
    required this.userId,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  // 🔹 Централизованный список категорий (временно — хардкод)
  static final List<Category> knownCategories = [
    Category(id: 'cat_salary', name: 'Зарплата'),
    Category(id: 'cat_freelance', name: 'Подработка'),
    Category(id: 'cat_dividends', name: 'Дивиденды'),
    Category(id: 'cat_crypto', name: 'Криптовалюта'),
    Category(id: 'cat_food', name: 'Еда'),
    Category(id: 'cat_transport', name: 'Транспорт'),
    Category(id: 'cat_rent', name: 'Аренда'),
    Category(id: 'cat_shopping', name: 'Покупки'),
    Category(id: 'cat_entertainment', name: 'Развлечения'),
  ];

  // 🔹 МЕТОД: получение категорий — можно легко заменить на API-запрос позже
  Future<List<Category>> getCategories() async {
    // 🔜 TODO: когда бэкенд добавит /v1/categories — раскомментируй:
    /*
    try {
      final res = await _dio.get<Map<String, dynamic>>('/v1/categories?userId=$userId');
      final list = List<Map<String, dynamic>>.from(res.data?['categories'] ?? []);
      return list.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      // fallback to known
    }
    */
    return knownCategories;
  }

  double _parseMoney(Map<String, dynamic>? money) {
    if (money == null) return 0.0;
    final amountStr = money['amount'] as String?;
    if (amountStr == null) return 0.0;
    try {
      return int.parse(amountStr) / 100.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> createTransaction({
    required double amount,
    required String categoryId,
    required String fromAccountId,
    String? toAccountId,
    required DateTime date,
    String description = '',
  }) async {
    final type = toAccountId != null && toAccountId.isNotEmpty
        ? 'TRANSACTION_TYPE_TRANSFER'
        : amount >= 0
            ? 'TRANSACTION_TYPE_INCOME'
            : 'TRANSACTION_TYPE_EXPENSE';

    final payload = <String, dynamic>{
      'userId': userId,
      'type': type,
      'amount': {
        'amount': (amount.abs() * 100).round().toString(),
        'currency': 'RUB',
      },
      'categoryId': categoryId,
      'fromAccountId': fromAccountId,
      'date': date.toUtc().toIso8601String(),
    };

    if (description.isNotEmpty) payload['description'] = description;
    if (toAccountId != null && toAccountId.isNotEmpty) {
      payload['toAccountId'] = toAccountId;
    }

    try {
      await _dio.post('/v1/transactions', data: payload);
    } on DioException catch (e) {
      print('🔴 createTransaction error: $e');
      if (e.response != null) {
        print('🔴 Status: ${e.response!.statusCode}');
        print('🔴 Body: ${e.response!.data}');
      }
      rethrow;
    }
  }

  Future<BalanceSummary> getBalance() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/v1/users/$userId/balance');
      final total = _parseMoney(res.data?['totalBalance']);
      return BalanceSummary(wallet: total, investments: 0.0);
    } catch (e) {
      print('🔴 getBalance error: $e');
      return _mockBalance();
    }
  }

  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 365));
      endDate ??= DateTime.now();
      await _dio.post('/v1/analytics', data: {
        'userId': userId,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
      });
    } catch (e) {
      print('🔴 getTransactions error: $e');
    }
    return _mockTransactions();
  }

  Future<List<Dividend>> getDividends() async => [
        Dividend(name: 'SBER', amount: 25.5, date: DateTime.now()),
      ];

  Future<List<ForecastPeriod>> getForecast({
    String period = 'TIME_PERIOD_MONTH',
    int periodsAhead = 3,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/v1/forecast', data: {
        'userId': userId,
        'period': period,
        'periodsAhead': periodsAhead,
      });
      final forecasts = List<Map<String, dynamic>>.from(res.data?['forecasts'] ?? []);
      return forecasts.map((f) => ForecastPeriod.fromJson(f)).toList();
    } catch (e) {
      print('🔴 getForecast error: $e');
      return _mockForecasts();
    }
  }

  // --- Моки ---
  BalanceSummary _mockBalance() => BalanceSummary(wallet: 37295.0, investments: 5000.0);
  List<Transaction> _mockTransactions() => [
        Transaction(
          date: DateTime.now(),
          amount: 5000,
          type: 'income',
          category: 'Зарплата',
          categoryId: 'cat_salary',
          source: 'T-банк',
          fromAccountId: 'acc_tbank',
          toAccountId: '',
          description: 'Аванс',
        ),
        Transaction(
          date: DateTime.now().subtract(const Duration(days: 1)),
          amount: -2000,
          type: 'expense',
          category: 'Еда',
          categoryId: 'cat_food',
          source: 'Сбербанк',
          fromAccountId: 'acc_sber',
          toAccountId: '',
          description: 'Продукты',
        ),
      ];
  List<ForecastPeriod> _mockForecasts() {
    final now = DateTime.now();
    return [
      ForecastPeriod(
        periodStart: DateTime(now.year, now.month, 1),
        periodEnd: DateTime(now.year, now.month + 1, 0),
        expectedIncome: 125000,
        expectedExpense: 62000,
        expectedBalance: 63000,
        categoryBreakdown: [
          CategorySpending(categoryId: 'cat_salary', totalAmount: 100000),
        ],
      ),
    ];
  }
}