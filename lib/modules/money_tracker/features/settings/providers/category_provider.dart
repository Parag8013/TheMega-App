import 'package:flutter/material.dart';
import '../../../core/constants/category_constants.dart';
import '../../../core/models/category_model.dart';
import '../../../core/database/database_helper.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _expenseCategories = List.from(
    CategoryConstants.expenseCategories,
  );
  List<CategoryModel> _incomeCategories = List.from(
    CategoryConstants.incomeCategories,
  );

  bool _isLoaded = false;

  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<CategoryModel> get incomeCategories => _incomeCategories;

  // Load categories from database
  Future<void> loadCategories() async {
    if (_isLoaded) return;

    final categories = await DatabaseHelper.instance.getAllCategories();

    if (categories.isEmpty) {
      // First time - save default categories to database
      await _saveDefaultCategories();
      _isLoaded = true;
      notifyListeners();
      return;
    }

    // Start with default categories
    final expenseSet = <String, CategoryModel>{};
    final incomeSet = <String, CategoryModel>{};

    // Add all default categories first
    for (var cat in CategoryConstants.expenseCategories) {
      expenseSet[cat.label] = cat;
    }
    for (var cat in CategoryConstants.incomeCategories) {
      incomeSet[cat.label] = cat;
    }

    // Then add/override with custom categories from database
    for (var cat in categories) {
      final category = CategoryModel(
        label: cat['name'] as String,
        icon: IconData(
          int.parse(cat['icon_name'] as String),
          fontFamily: 'MaterialIcons',
        ),
        color: Color(cat['color_value'] as int),
      );

      // Check if it's a default income category
      final isDefaultIncome = CategoryConstants.incomeCategories.any(
        (c) => c.label == category.label,
      );

      if (isDefaultIncome) {
        incomeSet[category.label] = category;
      } else {
        // Either default expense or custom category
        expenseSet[category.label] = category;
      }
    }

    _expenseCategories = expenseSet.values.toList();
    _incomeCategories = incomeSet.values.toList();

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveDefaultCategories() async {
    for (var cat in CategoryConstants.expenseCategories) {
      await DatabaseHelper.instance.insertCategory(
        '${cat.label}_${DateTime.now().microsecondsSinceEpoch}',
        cat.label,
        cat.icon.codePoint.toString(),
        cat.color.value,
      );
    }

    for (var cat in CategoryConstants.incomeCategories) {
      await DatabaseHelper.instance.insertCategory(
        '${cat.label}_${DateTime.now().microsecondsSinceEpoch}',
        cat.label,
        cat.icon.codePoint.toString(),
        cat.color.value,
      );
    }
  }

  void addExpenseCategory(CategoryModel category) async {
    _expenseCategories.add(category);
    notifyListeners();

    // Save to database
    await DatabaseHelper.instance.insertCategory(
      '${category.label}_${DateTime.now().microsecondsSinceEpoch}',
      category.label,
      category.icon.codePoint.toString(),
      category.color.value,
    );
  }

  void addIncomeCategory(CategoryModel category) async {
    _incomeCategories.add(category);
    notifyListeners();

    // Save to database
    await DatabaseHelper.instance.insertCategory(
      '${category.label}_${DateTime.now().microsecondsSinceEpoch}',
      category.label,
      category.icon.codePoint.toString(),
      category.color.value,
    );
  }

  void removeExpenseCategory(String label) async {
    _expenseCategories.removeWhere((cat) => cat.label == label);
    notifyListeners();

    // Delete from database
    await DatabaseHelper.instance.deleteCategory(label);
  }

  void removeIncomeCategory(String label) async {
    _incomeCategories.removeWhere((cat) => cat.label == label);
    notifyListeners();

    // Delete from database
    await DatabaseHelper.instance.deleteCategory(label);
  }
}
