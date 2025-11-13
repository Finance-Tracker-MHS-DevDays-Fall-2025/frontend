// lib/models/balance.dart
class BalanceSummary {
  final double wallet;
  final double investments;

  BalanceSummary({required this.wallet, required this.investments});

  @override
  String toString() => 'BalanceSummary(wallet: $wallet, investments: $investments)';
}