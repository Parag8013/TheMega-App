import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../transactions/providers/transaction_provider.dart';
import '../../../transactions/presentation/screens/edit_transaction_screen.dart';
import '../../../settings/providers/category_provider.dart';
import '../../../accounts/providers/account_provider.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final MoneyTransaction transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final accountProvider = context.watch<AccountProvider>();

    final expenseCategory = categoryProvider.expenseCategories
        .where((c) => c.label == transaction.category)
        .firstOrNull;
    final incomeCategory = categoryProvider.incomeCategories
        .where((c) => c.label == transaction.category)
        .firstOrNull;
    final category =
        expenseCategory ??
        incomeCategory ??
        categoryProvider.expenseCategories.first;

    // Get account name
    final account = accountProvider.accounts
        .where((a) => a.id == transaction.accountId)
        .firstOrNull;
    final accountName = account?.name ?? 'Unknown Account';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Details', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Icon and Name
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.icon,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          transaction.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Type
                  _buildDetailRow(
                    'Type',
                    transaction.type == 'expense' ? 'Expense' : 'Income',
                  ),
                  const SizedBox(height: 24),

                  // Amount
                  _buildDetailRow(
                    'Amount',
                    transaction.amount.toStringAsFixed(0),
                  ),
                  const SizedBox(height: 24),

                  // Account
                  _buildDetailRow('Account', accountName),
                  const SizedBox(height: 24),

                  // Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(transaction.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '( Add ${DateFormat('dd MMM yyyy HH:mm:ss').format(transaction.date)} )',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Note
                  _buildDetailRow(
                    'Note',
                    transaction.note.isEmpty ? 'No note' : transaction.note,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Edit Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editTransaction(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteTransaction(context),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ],
    );
  }

  void _editTransaction(BuildContext context) {
    // Check if this is a virtual transaction (recurring payment)
    if (transaction.id.startsWith('recurring_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot edit recurring payment transactions. Edit the recurring payment settings instead.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to edit transaction screen
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
          child: EditTransactionScreen(transaction: transaction),
        ),
      ),
    ).then((updated) {
      if (updated == true && context.mounted) {
        Navigator.pop(context, true); // Return to dashboard with refresh flag
      }
    });
  }

  void _deleteTransaction(BuildContext context) {
    // Check if this is a virtual transaction (recurring payment)
    if (transaction.id.startsWith('recurring_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete recurring payment transactions. Delete the recurring payment settings instead.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Transaction',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this transaction?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<TransactionProvider>().deleteTransaction(
                  transaction.id,
                );
                if (context.mounted) {
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.pop(
                    context,
                    true,
                  ); // Return to dashboard with refresh flag
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting transaction: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
