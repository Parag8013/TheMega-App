import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';

class CategoryBudget {
  final String category;
  double amount;

  CategoryBudget({required this.category, required this.amount});
}

class BudgetProvider with ChangeNotifier {
  final Map<String, CategoryBudget> _budgets = {};
  double _monthlyBudget = 0;
  bool _isLoaded = false;

  Map<String, CategoryBudget> get budgets => _budgets;
  double get monthlyBudget => _monthlyBudget;

  // Load budgets from database
  Future<void> loadBudgets() async {
    if (_isLoaded) return;

    // Load monthly budget
    _monthlyBudget = await DatabaseHelper.instance.getMonthlyBudget();

    // Load category budgets
    final categoryBudgets = await DatabaseHelper.instance
        .getAllCategoryBudgets();
    _budgets.clear();
    for (var entry in categoryBudgets.entries) {
      _budgets[entry.key] = CategoryBudget(
        category: entry.key,
        amount: entry.value,
      );
    }

    _isLoaded = true;
    notifyListeners();
  }

  void setMonthlyBudget(double amount) async {
    _monthlyBudget = amount;
    notifyListeners();

    // Save to database
    await DatabaseHelper.instance.setMonthlyBudget(amount);
  }

  void setCategoryBudget(String category, double amount) async {
    _budgets[category] = CategoryBudget(category: category, amount: amount);
    notifyListeners();

    // Save to database
    await DatabaseHelper.instance.setCategoryBudget(category, amount);
  }

  void removeCategoryBudget(String category) {
    _budgets.remove(category);
    notifyListeners();
  }

  double getCategoryBudget(String category) {
    return _budgets[category]?.amount ?? 0;
  }
}
