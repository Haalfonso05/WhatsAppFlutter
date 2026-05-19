import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0);
final _date = DateFormat('dd/MM/yyyy');

String formatCurrency(double amount) => _currency.format(amount);

String formatDate(String isoDate) {
  try {
    return _date.format(DateTime.parse(isoDate).toLocal());
  } catch (_) {
    return isoDate;
  }
}

String todayPrefix() => DateTime.now().toIso8601String().substring(0, 10);
String currentMonthPrefix() => DateTime.now().toIso8601String().substring(0, 7);
