// lib/services/real_api_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fintrack/models/transaction.dart';
import 'package:fintrack/models/balance.dart';
import 'package:fintrack/models/dividend.dart';
import 'package:fintrack/models/forecast.dart';

// Только для web
import 'dart:html' as html;

enum TransactionType {
  unspecified,
  income,
  expense,
  transfer;

  static TransactionType fromString(String value) => switch (value) {
        'TRANSACTION_TYPE_INCOME' => income,
        'TRANSACTION_TYPE_EXPENSE' => expense,
        'TRANSACTION_TYPE_TRANSFER' => transfer,
        _ => unspecified,
      };

  String toBackendString() => switch (this) {
        income => 'TRANSACTION_TYPE_INCOME',
        expense => 'TRANSACTION_TYPE_EXPENSE',
        transfer => 'TRANSACTION_TYPE_TRANSFER',
        unspecified => 'TRANSACTION_TYPE_UNSPECIFIED',
      };

  String toModelType() => switch (this) {
        income => 'income',
        expense => 'expense',
        transfer => 'transfer',
        unspecified => 'other',
      };
}

class RealApiService {
  final Dio _dio;
  final String _baseUrl;
  final String userId;

  // 🔥 Локальное хранилище
  final List<Transaction> _localTransactions = [];

  RealApiService({
    String baseUrl = 'http://localhost:8080',
    required this.userId,
  })  : _baseUrl = baseUrl,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: 5000,
          receiveTimeout: 10000,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    // Загружаем из localStorage при старте
    _localTransactions.addAll(_loadFromStorage());
  }

  // =============== localStorage ===============
  void _saveToStorage() {
    try {
      final json = jsonEncode(_localTransactions.map((t) => t.toJson()).toList());
      html.window.localStorage['fintrack_txs_$userId'] = json;
    } catch (e) {
      print('⚠️ localStorage save failed: $e');
    }
  }

  List<Transaction> _loadFromStorage() {
    try {
      final json = html.window.localStorage['fintrack_txs_$userId'];
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('⚠️ localStorage load failed: $e');
      return [];
    }
  }

  // =============== Вспомогательное ===============
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
    return map[id] ?? 'Неизвестно';
  }

  String _getAccountName(String id) {
    final map = {
      'acc_tbank': 'T-банк',
      'acc_sber': 'Сбербанк',
      'acc_vtb': 'ВТБ',
      'acc_cash': 'Наличные',
      'acc_ps': 'ПСБ',
    };
    return map[id] ?? 'Счёт $id';
  }

  // =============== ОСНОВНОЙ МЕТОД: добавление + локальное сохранение ===============
  Future<void> createTransaction({
    required double amount,
    required String categoryId,
    required String fromAccountId,
    String? toAccountId,
    required DateTime date,
    String description = '',
  }) async {
    final type = toAccountId != null && toAccountId.isNotEmpty
        ? TransactionType.transfer
        : amount >= 0
            ? TransactionType.income
            : TransactionType.expense;

    // 🔥 Optimistic: сразу добавляем локально — UI обновится мгновенно
    final tx = Transaction(
      id: '', // пока не нужен
      date: date,
      amount: amount,
      type: type.toModelType(),
      category: _getCategoryName(categoryId),
      categoryId: categoryId,
      source: _getAccountName(fromAccountId),
      fromAccountId: fromAccountId,
      toAccountId: toAccountId ?? '',
      description: description,
    );

    _localTransactions.add(tx);
    _saveToStorage(); // 👈 сохраняем в localStorage
    print('✅ Added locally: $tx');

    // Отправляем в бэк
    final payload = {
      'userId': userId,
      'type': type.toBackendString(),
      'amount': {
        'amount': (amount.abs() * 100).round().toString(),
        'currency': 'RUB',
      },
      'categoryId': categoryId,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId ?? '',
      'date': date.toUtc().toIso8601String(),
      'description': description,
    };

    try {
      await _dio.post('/v1/transactions', data: payload);
      print('✅ Sent to backend');
    } on DioException catch (e) {
      print('⚠️ Backend failed, but UI updated: ${e.message}');
      // Не удаляем — пусть остаётся
    }
  }

  // =============== GET-методы ===============
  Future<BalanceSummary> getBalance() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/v1/users/$userId/balance');
      final total = _parseMoney(res.data?['totalBalance']);
      return BalanceSummary(wallet: total, investments: 0.0);
    } catch (e) {
      print('⚠️ getBalance failed → fallback to local sum');
      final wallet = _localTransactions.where((t) => t.type != 'transfer').fold(0.0, (sum, t) => sum + t.amount);
      return BalanceSummary(wallet: wallet, investments: 0.0);
    }
  }

  double _parseMoney(Map<String, dynamic>? money) {
    if (money == null) return 0.0;
    final amountStr = money['amount'] as String?;
    if (amountStr == null) return 0.0;
    try {
      return int.parse(amountStr) / 100.0;
    } catch (e) {
      return 0.0;
    }
  }

  // 🔥 ВСЕГДА возвращаем локальные транзакции — с фильтрацией
  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _localTransactions.where((t) {
      final d = t.date;
      return (startDate == null || !d.isBefore(startDate)) &&
          (endDate == null || !d.isAfter(endDate));
    }).toList();
  }

  Future<List<Dividend>> getDividends() async => [
        Dividend(name: 'SBER', amount: 25.5, date: DateTime.now()),
        Dividend(name: 'GAZP', amount: 12.3, date: DateTime.now().subtract(const Duration(days: 10))),
        Dividend(name: 'LKOH', amount: 8.7, date: DateTime.now().add(const Duration(days: 3))),
      ];

  Future<List<ForecastPeriod>> getForecast({
    String period = 'TIME_PERIOD_MONTH',
    int periodsAhead = 3,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/v1/forecast',
         {
          'userId': userId,
          'period': period,
          'periodsAhead': periodsAhead,
        },
      );
      final forecasts = List<Map<String, dynamic>>.from(res.data?['forecasts'] ?? []);
      return forecasts.map((f) => ForecastPeriod.fromJson(f)).toList();
    } catch (e) {
      print('⚠️ getForecast failed → mock');
      return _mockForecasts();
    }
  }

  // =============== Моки (только для прогноза и инициализации) ===============
  void initializeWithMocksIfEmpty() {
    if (_localTransactions.isEmpty) {
      print('ℹ️ Initializing with mocks');
      _localTransactions.addAll(_mockTransactions());
      _saveToStorage();
    }
  }

  List<Transaction> _mockTransactions() => [
        Transaction(
          id: '',
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
          id: '',
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
        Transaction(
          id: '',
          date: DateTime.now().subtract(const Duration(days: 3)),
          amount: -800,
          type: 'expense',
          category: 'Транспорт',
          categoryId: 'cat_transport',
          source: 'ВТБ',
          fromAccountId: 'acc_vtb',
          toAccountId: '',
          description: 'Метро',
        ),
        Transaction(
          id: '',
          date: DateTime.now().subtract(const Duration(days: 5)),
          amount: 1000,
          type: 'income',
          category: 'Подработка',
          categoryId: 'cat_freelance',
          source: 'Наличные',
          fromAccountId: 'acc_cash',
          toAccountId: '',
          description: 'Fiverr',
        ),
        Transaction(
          id: '',
          date: DateTime.now().subtract(const Duration(days: 7)),
          amount: -3500,
          type: 'expense',
          category: 'Аренда',
          categoryId: 'cat_rent',
          source: 'T-банк',
          fromAccountId: 'acc_tbank',
          toAccountId: '',
          description: 'Квартира',
        ),
      ];

  List<ForecastPeriod> _mockForecasts() {
    final now = DateTime.now();
    return [
      ForecastPeriod(
        periodStart: DateTime(now.year, now.month, 1),
        periodEnd: DateTime(now.year, now.month + 1, 0),
        expectedIncome: 125_000,
        expectedExpense: 62_000,
        expectedBalance: 63_000,
        categoryBreakdown: [
          CategorySpending(categoryId: 'cat_salary', totalAmount: 100_000),
          CategorySpending(categoryId: 'cat_freelance', totalAmount: 25_000),
        ],
      ),
    ];
  }
}