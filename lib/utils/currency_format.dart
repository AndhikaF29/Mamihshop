import 'package:intl/intl.dart';

class CurrencyFormat {
  static String convertToIdr(dynamic number, {bool shortFormat = false}) {
  NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  
  double value = 0;
  if (number is String) {
    value = double.parse(number);
  } else if (number is double || number is int) {
    value = number.toDouble();
  }

  if (shortFormat && value >= 1000000) {
    return 'Rp ${(value/1000000).toStringAsFixed(1)}M';
  } else if (shortFormat && value >= 1000) {
    return 'Rp ${(value/1000).toStringAsFixed(1)}K';
  }
  
  return currencyFormatter.format(value);
}
}