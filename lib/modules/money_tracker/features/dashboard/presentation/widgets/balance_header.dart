// lib/features/dashboard/presentation/widgets/balance_header.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_formatter.dart';

class BalanceHeader extends StatelessWidget {
  final DateTime selectedDate;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final VoidCallback onCalendarTap;

  const BalanceHeader({
    Key? key,
    required this.selectedDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.onCalendarTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date selector
          GestureDetector(
            onTap: onCalendarTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('yyyy').format(selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      DateFormat('MMM').format(selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expenses
          _buildAmountColumn(
            'Expenses',
            CurrencyFormatter.format(totalExpense),
            Colors.red,
          ),

          // Income
          _buildAmountColumn(
            'Income',
            CurrencyFormatter.format(totalIncome),
            Colors.green,
          ),

          // Balance
          _buildAmountColumn(
            'Balance',
            CurrencyFormatter.format(balance),
            balance >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountColumn(String label, String amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
