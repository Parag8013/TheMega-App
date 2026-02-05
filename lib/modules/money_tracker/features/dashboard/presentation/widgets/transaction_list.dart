import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/providers/transaction_provider.dart';
import '../../../settings/providers/category_provider.dart';
import '../../../accounts/providers/account_provider.dart';
import '../screens/transaction_details_screen.dart';

class TransactionList extends StatelessWidget {
  final Map<DateTime, List<MoneyTransaction>> transactionGroups;

  const TransactionList({Key? key, required this.transactionGroups})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (transactionGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add your first transaction',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: transactionGroups.length,
      itemBuilder: (context, index) {
        final date = transactionGroups.keys.elementAt(index);
        final transactions = transactionGroups[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Divider between date groups
            if (index > 0)
              Divider(
                height: 1,
                color: Colors.grey[800],
                indent: 16,
                endIndent: 16,
              ),

            // Date header with daily totals - FIXED OVERFLOW
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Date text - takes available space
                  Expanded(
                    flex: 3,
                    child: Text(
                      DateFormat('d MMM yyyy, EEEE').format(date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Daily totals - fixed width to prevent overflow
                  Expanded(flex: 2, child: _buildDailyTotals(transactions)),
                ],
              ),
            ),

            // Transaction items - skip transfer_in (only show transfer_out)
            ...transactions.where((t) => t.transferType != 'transfer_in').map(
                  (transaction) => _buildTransactionItem(context, transaction),
                ),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // FIXED: Proper layout for daily totals (excluding transfers)
  Widget _buildDailyTotals(List<MoneyTransaction> transactions) {
    final income = transactions
        .where((t) => t.type == 'income' && t.transferType == null)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.type == 'expense' && t.transferType == null)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Income row
        if (income > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Income: ',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Flexible(
                child: Text(
                  _formatAmount(income),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

        // Expense row
        if (expense > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Expenses: ',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Flexible(
                child: Text(
                  _formatAmount(expense),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Format amount with rupee symbol
  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  Widget _buildTransactionItem(
    BuildContext context,
    MoneyTransaction transaction,
  ) {
    // Check if this is a transfer
    final isTransfer = transaction.transferType == 'transfer_out';

    final isExpense = transaction.type == 'expense';
    final color = isTransfer
        ? Colors.yellow[600]!
        : (isExpense ? Colors.red : Colors.green);
    final prefix = isTransfer ? '' : (isExpense ? '-' : '+');

    return GestureDetector(
      onTap: () {
        // Navigate to transaction details screen with providers
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (newContext) => MultiProvider(
              providers: [
                ChangeNotifierProvider.value(
                  value: context.read<TransactionProvider>(),
                ),
                ChangeNotifierProvider.value(
                  value: context.read<CategoryProvider>(),
                ),
                ChangeNotifierProvider.value(
                  value: context.read<AccountProvider>(),
                ),
              ],
              child: TransactionDetailsScreen(transaction: transaction),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTransfer ? Icons.swap_horiz : transaction.categoryIcon,
                      color: color,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Transaction details - takes available space
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTransfer
                              ? 'Transfer'
                              : (transaction.note.isNotEmpty
                                  ? transaction.note
                                  : transaction.category),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTransfer
                              ? transaction.note.isNotEmpty
                                  ? transaction.note
                                  : transaction.category
                              : (transaction.note.isNotEmpty
                                  ? transaction.category
                                  : ''),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Amount - fixed width to prevent overflow
                  SizedBox(
                    width: 100,
                    child: Text(
                      '$prefix${_formatAmount(transaction.amount)}',
                      style: TextStyle(
                        color: isTransfer ? Colors.white : color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
