// lib/services/real_api_service.dart
import 'package:dio/dio.dart';
import 'package:fintrack/models/transaction.dart';
import 'package:fintrack/models/dividend.dart';
import 'package:fintrack/models/forecast.dart';
import 'package:fintrack/models/balance.dart';

class Account {
  final String id;
  final String name;
  final String type;
  final double balance;
  final String currency;
  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'RUB',
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    final balanceMap = (json['balance'] as Map<String, dynamic>?) ?? {};
    return Account(
      id: json['accountId'] as String? ?? '',
      name: json['name'] as String? ?? 'Без названия',
      type: json['type'] as String? ?? 'ACCOUNT_TYPE_REGULAR',
      balance: _parseMoney(balanceMap),
      currency: balanceMap['currency'] as String? ?? 'RUB',
    );
  }

  static double _parseMoney(Map<String, dynamic>? money) {
    if (money == null) return 0.0;
    final amount = money['amount'];
    if (amount == null) return 0.0;
    String s = amount is String ? amount.trim() : amount.toString().trim();
    try {
      return double.parse(s);
    } catch (e) {
      return 0.0;
    }
  }
}

class Category {
  final String id;
  final String name;
  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Без названия',
      );
}

class RealApiService {
  final Dio _dio;
  final String userId;

  RealApiService({
    String baseUrl = 'http://158.160.202.247:8080/api/v1',
    required this.userId,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ));

  List<Transaction> _cachedTransactions = [];
  BalanceSummary? _cachedBalance;
  List<Account> _cachedAccounts = [];

  static final List<Category> knownCategories = [
    Category(id: 'cat_salary', name: 'Зарплата'),
    Category(id: 'cat_food', name: 'Еда'),
    Category(id: 'cat_transport', name: 'Транспорт'),
    Category(id: 'cat_freelance', name: 'Подработка'),
    Category(id: 'cat_rent', name: 'Аренда'),
    Category(id: 'cat_dividends', name: 'Дивиденды'),
    Category(id: 'cat_crypto', name: 'Криптовалюта'),
    Category(id: 'cat_shopping', name: 'Покупки'),
    Category(id: 'cat_entertainment', name: 'Развлечения'),
  ];

  String _toProtoTimestamp(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}.'
        '${utc.millisecond.toString().padLeft(3, '0')}Z';
  }

  Future<BalanceSummary> getBalance() async {
    if (_cachedBalance != null) return _cachedBalance!;
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/$userId/balance');
      final data = res.data;
      if (data == null) throw Exception('Empty balance');

      final totalBalanceMap = data['totalBalance'] as Map<String, dynamic>?;
      final total = Account._parseMoney(totalBalanceMap);
      double wallet = total, investments = 0.0;

      final accounts = data['accounts'];
      if (accounts is List) {
        wallet = 0.0;
        investments = 0.0;
        for (var item in accounts) {
          if (item is Map<String, dynamic>) {
            final bal = Account._parseMoney(item['balance'] ?? {});
            final type = item['type'] as String? ?? '';
            if (type == 'ACCOUNT_TYPE_INVESTMENT') investments += bal;
            else wallet += bal;
          }
        }
      }

      return _cachedBalance = BalanceSummary(wallet: wallet, investments: investments);
    } catch (e) {
      print('getBalance: $e');
      rethrow;
    }
  }

  Future<List<Account>> getAccounts() async {
    if (_cachedAccounts.isNotEmpty) return _cachedAccounts;
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/$userId/balance');
      final accounts = (res.data?['accounts'] as List?) ?? [];
      return _cachedAccounts = accounts
          .whereType<Map<String, dynamic>>()
          .map(Account.fromJson)
          .toList();
    } catch (e) {
      print('getAccounts: $e');
      return [];
    }
  }

  Future<List<Category>> getCategories() async => knownCategories;

  Future<Transaction> createTransaction({
  required double amount,
  required String fromAccountId,
  String? toAccountId,
  required DateTime date,
  String description = '',
  required String type,
}) async {
  final payload = <String, dynamic>{
    'userId': userId,
    'type': type,
    'amount': {'amount': amount.abs().round().toString(), 'currency': 'RUB'},
    'fromAccountId': fromAccountId,
    'date': _toProtoTimestamp(date),
    if (description.isNotEmpty) 'description': description,
    if (toAccountId != null && toAccountId.isNotEmpty) 'toAccountId': toAccountId,
  };

  print('POST /transactions: $payload');
  try {
    final res = await _dio.post<Map<String, dynamic>>('/transactions', data: payload);
    final newTx = Transaction.fromJson(res.data ?? {});

    _cachedTransactions.clear();
    _cachedBalance = null;
    _cachedAccounts.clear();

    print('Created: ${newTx.id}, category: ${newTx.category}');
    return newTx;
  } catch (e) {
    print('createTransaction: $e');
    rethrow;
  }
}

  Future<List<Transaction>> getTransactions({DateTime? startDate, DateTime? endDate}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/$userId/transactions');
      final data = res.data;
      if (data == null) {
        print('getTransactions: response data is null');
        return [];
      }

      final txList = data['transactions'];
      if (txList is! List) {
        print('getTransactions: expected "transactions": [...], got $data');
        return [];
      }

      final parsed = txList
          .whereType<Map<String, dynamic>>()
          .map((json) => Transaction.fromJson(json))
          .toList();

      return _cachedTransactions = parsed;
    } catch (e) {
      print('getTransactions: $e');
      return _cachedTransactions;
    }
  }

  Future<List<Dividend>> getDividends() async => [
        Dividend(name: 'SBER', amount: 25.5, date: DateTime.now().subtract(const Duration(days: 3))),
        Dividend(name: 'VTBR', amount: 12.3, date: DateTime.now().subtract(const Duration(days: 10))),
      ];

  Future<List<ForecastPeriod>> getForecast({String period = 'TIME_PERIOD_MONTH', int periodsAhead = 3}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/forecast',
        data: {
          'userId': userId,
          'period': period,
          'periodsAhead': periodsAhead,
        },
      );
      final forecasts = (res.data?['forecasts'] as List?) ?? [];
      return forecasts.map((f) => ForecastPeriod.fromJson(f)).toList();
    } catch (e) {
      print('getForecast: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getAnalytics({DateTime? startDate, DateTime? endDate}) async {
    try {
      endDate ??= DateTime.now();
      startDate ??= endDate.subtract(const Duration(days: 30));
      final payload = {
        'userId': userId,
        'startDate': _toProtoTimestamp(startDate),
        'endDate': _toProtoTimestamp(endDate),
      };
      final res = await _dio.post<Map<String, dynamic>>('/analytics', data: payload);
      return res.data ?? {};
    } catch (e) {
      print('getAnalytics: $e');
      return {};
    }
  }
}