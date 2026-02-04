import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../../../core/models/category_model.dart';

class BudgetSettingsScreen extends StatelessWidget {
  const BudgetSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Budget Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          final categoryProvider = context.watch<CategoryProvider>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Monthly Budget
              _buildBudgetItem(
                context,
                icon: Icons.account_balance_wallet,
                label: 'Monthly Budget',
                budget: budgetProvider.monthlyBudget,
                onTap: () => _showBudgetDialog(
                  context,
                  'Monthly Budget',
                  budgetProvider.monthlyBudget,
                  (amount) => budgetProvider.setMonthlyBudget(amount),
                ),
              ),
              const Divider(color: Colors.grey, height: 32),

              // Category Budgets
              ...categoryProvider.expenseCategories.map((category) {
                final budget = budgetProvider.getCategoryBudget(category.label);
                return _buildBudgetItem(
                  context,
                  icon: category.icon,
                  label: category.label,
                  budget: budget,
                  color: category.color,
                  onTap: () => _showBudgetDialog(
                    context,
                    'Monthly Budget - ${category.label}',
                    budget,
                    (amount) => budgetProvider.setCategoryBudget(
                      category.label,
                      amount,
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBudgetItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double budget,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
              onPressed: () {},
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (color ?? Colors.yellow[700])!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color ?? Colors.yellow[700], size: 24),
            ),
          ],
        ),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        subtitle: budget > 0
            ? Text(
                '₹${budget.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.yellow[700], fontSize: 14),
              )
            : Text(
                'Not set',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onTap,
              child: Text('Edit', style: TextStyle(color: Colors.grey[400])),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(
    BuildContext context,
    String title,
    double currentBudget,
    Function(double) onSave,
  ) {
    final controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) {
        double amount = currentBudget;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixText: '₹',
                    prefixStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  onChanged: (value) {
                    amount = double.tryParse(value) ?? 0;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onSave(amount);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
