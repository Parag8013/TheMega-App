// lib/core/constants/account_constants.dart
import 'package:flutter/material.dart';

class AccountConstants {
  static const List<String> accountTypes = [
    'Cash',
    'Bank Account',
    'Credit Card',
    'E-Wallet',
    'Investment',
    'Savings',
    'Current Account',
    'Fixed Deposit',
    'Crypto Wallet',
    'Other',
  ];

  static const List<String> currencies = [
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
    'INR (₹)',
    'CNY (¥)',
    'JPY (¥)',
    'AUD (A\$)',
    'CAD (C\$)',
    'CHF (Fr)',
    'BTC (₿)',
  ];

  static const Map<String, IconData> accountIcons = {
    'cash': Icons.money,
    'credit_card': Icons.credit_card,
    'wallet': Icons.account_balance_wallet,
    'bank': Icons.account_balance,
    'savings': Icons.savings,
    'investment': Icons.trending_up,
    'dollar': Icons.attach_money,
    'euro': Icons.euro,
    'pound': Icons.currency_pound,
    'bitcoin': Icons.currency_bitcoin,
    'paypal': Icons.payment,
    'mobile_wallet': Icons.phone_android,
    'piggy_bank': Icons.account_balance_wallet_outlined,
    'chart': Icons.bar_chart,
    'percent': Icons.percent,
  };

  static IconData getIconData(String iconName) {
    return accountIcons[iconName] ?? Icons.account_balance_wallet;
  }

  static String getDisplayCurrency(String currencyCode) {
    switch (currencyCode) {
      case 'USD (\$)': return '\$';
      case 'EUR (€)': return '€';
      case 'GBP (£)': return '£';
      case 'INR (₹)': return '₹';
      case 'CNY (¥)':
      case 'JPY (¥)': return '¥';
      case 'AUD (A\$)': return 'A\$';
      case 'CAD (C\$)': return 'C\$';
      case 'CHF (Fr)': return 'Fr';
      case 'BTC (₿)': return '₿';
      default: return '₹';
    }
  }
}