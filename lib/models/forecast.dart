// lib/models/forecast.dart
import 'package:intl/intl.dart';

class ForecastPeriod {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double expectedIncome;
  final double expectedExpense;
  final double expectedBalance;
  final List<CategorySpending> categoryBreakdown;

  ForecastPeriod({
    required this.periodStart,
    required this.periodEnd,
    required this.expectedIncome,
    required this.expectedExpense,
    required this.expectedBalance,
    required this.categoryBreakdown,
  });

  factory ForecastPeriod.fromJson(Map<String, dynamic> json) {
    return ForecastPeriod(
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      expectedIncome: _parseMoney(json['expectedIncome']),
      expectedExpense: _parseMoney(json['expectedExpense']),
      expectedBalance: _parseMoney(json['expectedBalance']),
      categoryBreakdown: List<Map<String, dynamic>>.from(json['categoryBreakdown'] ?? [])
          .map((item) => CategorySpending.fromJson(item))
          .toList(),
    );
  }

  static double _parseMoney(Map<String, dynamic>? money) {
    if (money == null) return 0.0;
    final amountStr = money['amount'] as String?;
    if (amountStr == null) return 0.0;
    try {
      return int.parse(amountStr) / 100.0;
    } catch (_) {
      return 0.0;
    }
  }

  String formatPeriodName() {
    final start = periodStart;
    final end = periodEnd;
    if (start.year == end.year) {
      if (start.month == end.month) {
        return DateFormat('MMMM yyyy', 'ru').format(start);
      } else {
        return '${DateFormat('MMMM', 'ru').format(start)}–${DateFormat('MMMM yyyy', 'ru').format(end)}';
      }
    } else {
      return '${DateFormat('MMMM yyyy', 'ru').format(start)} – ${DateFormat('MMMM yyyy', 'ru').format(end)}';
    }
  }
}

class CategorySpending {
  final String categoryId;
  final double totalAmount;

  CategorySpending({required this.categoryId, required this.totalAmount});

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      categoryId: json['categoryId'] as String? ?? '',
      totalAmount: ForecastPeriod._parseMoney(json['totalAmount']),
    );
  }
}