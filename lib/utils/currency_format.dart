import 'package:intl/intl.dart';

class CurrencyFormat {
  static String convertToIdr(dynamic number) {
    NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Jika input adalah string dengan desimal
    if (number is String) {
      return currencyFormatter.format(double.parse(number));
    }

    // Jika input adalah double
    if (number is double) {
      return currencyFormatter.format(number);
    }

    // Jika input adalah int
    if (number is int) {
      return currencyFormatter.format(number);
    }

    return "Rp 0";
  }
}
