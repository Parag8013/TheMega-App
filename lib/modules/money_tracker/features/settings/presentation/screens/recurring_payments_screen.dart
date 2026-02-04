import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recurring_payment_provider.dart';
import '../../../accounts/providers/account_provider.dart';
import '../../../transactions/providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import 'add_recurring_payment_screen.dart';
import 'edit_recurring_payment_screen.dart';

class RecurringPaymentsScreen extends StatelessWidget {
  const RecurringPaymentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Regular Payments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<RecurringPaymentProvider>(
        builder: (context, provider, child) {
          if (provider.payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'No records',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.payments.length,
            itemBuilder: (context, index) {
              final payment = provider.payments[index];
              final categoryProvider = context.read<CategoryProvider>();
              final categories = payment.type == 'expense'
                  ? categoryProvider.expenseCategories
                  : categoryProvider.incomeCategories;

              final category = categories.firstWhere(
                (cat) => cat.label == payment.category,
                orElse: () => categories.first,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, color: category.color, size: 24),
                  ),
                  title: Text(
                    payment.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '₹${payment.amount.toStringAsFixed(0)} • ${_capitalizeFirst(payment.frequency)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      if (payment.numberOfPayments != null)
                        Text(
                          '${payment.numberOfPayments} payments',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.yellow[700]),
                        onPressed: () =>
                            _navigateToEditPayment(context, payment),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () =>
                            _confirmDelete(context, provider, payment),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellow[700],
        onPressed: () async {
          final categoryProvider = context.read<CategoryProvider>();
          final accountProvider = context.read<AccountProvider>();
          final recurringProvider = context.read<RecurringPaymentProvider>();

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: categoryProvider),
                  ChangeNotifierProvider.value(value: accountProvider),
                  ChangeNotifierProvider.value(value: recurringProvider),
                ],
                child: const AddRecurringPaymentScreen(),
              ),
            ),
          );

          // If payment was added, reload transactions in the background
          if (result == true && context.mounted) {
            // Access transaction provider if available to reload
            try {
              final transactionProvider = context.read<TransactionProvider>();
              await transactionProvider.loadTransactionsByMonth(
                transactionProvider.selectedDate.year,
                transactionProvider.selectedDate.month,
              );
            } catch (e) {
              // Transaction provider might not be available in this context
            }
          }
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _navigateToEditPayment(BuildContext context, RecurringPayment payment) {
    final categoryProvider = context.read<CategoryProvider>();
    final accountProvider = context.read<AccountProvider>();
    final recurringProvider = context.read<RecurringPaymentProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: categoryProvider),
            ChangeNotifierProvider.value(value: accountProvider),
            ChangeNotifierProvider.value(value: recurringProvider),
          ],
          child: EditRecurringPaymentScreen(payment: payment),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    RecurringPaymentProvider provider,
    RecurringPayment payment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Payment',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${payment.name}"?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              provider.removePayment(payment.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
