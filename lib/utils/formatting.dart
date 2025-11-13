// lib/utils/formatting.dart
import 'dart:math' as math;

String formatMoney(double amount, {int decimals = 0}) {
  final sign = amount.sign;
  final abs = amount.abs();

  final scaled = (abs * math.pow(10, decimals)).round();
  final wholePart = (scaled ~/ math.pow(10, decimals)).toInt();
  final fractionalPart = scaled % math.pow(10, decimals);

  String formattedWhole = wholePart.toString();
  if (wholePart >= 1000) {
    final buffer = StringBuffer();
    var i = 0;
    for (var j = formattedWhole.length - 1; j >= 0; j--) {
      if (i > 0 && i % 3 == 0) buffer.write(' ');
      buffer.write(formattedWhole[j]);
      i++;
    }
    formattedWhole = buffer.toString().split('').reversed.join('');
  }

  var result = sign < 0 ? '−' : '';
  result += formattedWhole;
  if (decimals > 0 && fractionalPart > 0) {
    result += ',${fractionalPart.toInt().toString().padLeft(decimals, '0')}';
  } else if (decimals > 0) {
    result += ',${'0' * decimals}';
  }

  return result;
}