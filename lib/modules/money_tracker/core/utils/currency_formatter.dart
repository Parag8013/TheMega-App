// lib/core/utils/currency_formatter.dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
    locale: 'hi_IN',
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  // UPDATED: Better compact formatting
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      // 1 crore and above
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      // 1 lakh and above
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      // 1 thousand and above
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      // Less than 1000
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  static String formatWithDecimals(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'hi_IN',
    );
    return formatter.format(amount);
  }

  // For very small spaces - ultra compact
  static String formatUltraCompact(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}