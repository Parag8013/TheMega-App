// lib/core/constants/category_constants.dart
import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryConstants {
  static final List<CategoryModel> expenseCategories = [
    CategoryModel(
      label: 'Shopping',
      icon: Icons.shopping_cart,
      color: Colors.amber,
    ),
    CategoryModel(label: 'Food', icon: Icons.restaurant, color: Colors.orange),
    CategoryModel(
      label: 'Phone',
      icon: Icons.phone_android,
      color: Colors.green,
    ),
    CategoryModel(
      label: 'Entertainment',
      icon: Icons.movie,
      color: Colors.purple,
    ),
    CategoryModel(label: 'Education', icon: Icons.school, color: Colors.indigo),
    CategoryModel(label: 'Beauty', icon: Icons.face, color: Colors.pink),
    CategoryModel(
      label: 'Sports',
      icon: Icons.sports_soccer,
      color: Colors.teal,
    ),
    CategoryModel(label: 'Social', icon: Icons.people, color: Colors.cyan),
    CategoryModel(
      label: 'Transportation',
      icon: Icons.directions_bus,
      color: Colors.brown,
    ),
    CategoryModel(
      label: 'Clothing',
      icon: Icons.checkroom,
      color: Colors.purple,
    ),
    CategoryModel(
      label: 'Car',
      icon: Icons.directions_car,
      color: Colors.deepOrange,
    ),
    CategoryModel(label: 'Alcohol', icon: Icons.local_bar, color: Colors.red),
    CategoryModel(label: 'Health', icon: Icons.favorite, color: Colors.red),
    CategoryModel(label: 'Pets', icon: Icons.pets, color: Colors.brown),
    CategoryModel(label: 'Travel', icon: Icons.flight, color: Colors.lime),
    CategoryModel(label: 'Home', icon: Icons.home, color: Colors.deepPurple),
    CategoryModel(
      label: 'Gifts',
      icon: Icons.card_giftcard,
      color: Colors.pink,
    ),
  ];

  static const Map<String, String> smsKeywordToCategory = {
    // Shopping & E-commerce
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Clothing',
    'nykaa': 'Beauty',
    'bigbasket': 'Shopping',
    'grofers': 'Shopping',
    'blinkit': 'Shopping',
    'dunzo': 'Shopping',

    // Food & Dining
    'swiggy': 'Food',
    'zomato': 'Food',
    'dominos': 'Food',
    'pizza hut': 'Food',
    'mcdonald': 'Food',
    'kfc': 'Food',
    'subway': 'Food',
    'starbucks': 'Food',

    // Transportation
    'uber': 'Transportation',
    'ola': 'Transportation',
    'rapido': 'Transportation',
    'metro': 'Transportation',
    'bus': 'Transportation',
    'railway': 'Transportation',
    'irctc': 'Travel',

    // Fuel & Car
    'petrol': 'Car',
    'diesel': 'Car',
    'fuel': 'Car',
    'hp petrol': 'Car',
    'ioc': 'Car',
    'bharat petroleum': 'Car',

    // Entertainment
    'netflix': 'Entertainment',
    'prime video': 'Entertainment',
    'hotstar': 'Entertainment',
    'spotify': 'Entertainment',
    'apple music': 'Entertainment',
    'bookmyshow': 'Entertainment',
    'pvr': 'Entertainment',
    'inox': 'Entertainment',

    // Utilities & Bills
    'electricity': 'Home',
    'water': 'Home',
    'gas': 'Home',
    'lpg': 'Home',
    'broadband': 'Phone',
    'wifi': 'Phone',
    'internet': 'Phone',

    // Mobile & Recharge
    'airtel': 'Phone',
    'jio': 'Phone',
    'vodafone': 'Phone',
    'bsnl': 'Phone',
    'vi': 'Phone',
    'idea': 'Phone',

    // Medical & Health
    'hospital': 'Health',
    'medical': 'Health',
    'pharmacy': 'Health',
    'medicine': 'Health',
    'doctor': 'Health',
    'clinic': 'Health',
    'apollo': 'Health',
    'fortis': 'Health',

    // Education
    'school': 'Education',
    'college': 'Education',
    'university': 'Education',
    'coaching': 'Education',
    'byju': 'Education',
    'unacademy': 'Education',

    // Investment & Finance
    'mutual fund': 'Investment',
    'sip': 'Investment',
    'fd': 'Investment',
    'insurance': 'Investment',
    'lic': 'Investment',
    'zerodha': 'Investment',
    'groww': 'Investment',
  };

  // 🎯 INCOME KEYWORDS
  static const Map<String, String> incomeKeywords = {
    'salary': 'Salary',
    'sal': 'Salary',
    'bonus': 'Bonus',
    'incentive': 'Bonus',
    'interest': 'Investments',
    'dividend': 'Investments',
    'refund': 'Others',
    'cashback': 'Others',
    'reward': 'Others',
    'commission': 'Part-Time',
    'freelance': 'Part-Time',
  };

  static final List<CategoryModel> incomeCategories = [
    CategoryModel(
      label: 'Salary',
      icon: Icons.account_balance_wallet,
      color: Colors.green,
    ),
    CategoryModel(
      label: 'Investments',
      icon: Icons.trending_up,
      color: Colors.blue,
    ),
    CategoryModel(
      label: 'Part-Time',
      icon: Icons.schedule,
      color: Colors.orange,
    ),
    CategoryModel(label: 'Bonus', icon: Icons.star, color: Colors.amber),
    CategoryModel(label: 'Others', icon: Icons.more_horiz, color: Colors.grey),
  ];

  static CategoryModel? getCategoryByLabel(String label, String type) {
    final categories = type == 'expense' ? expenseCategories : incomeCategories;
    try {
      return categories.firstWhere((cat) => cat.label == label);
    } catch (e) {
      return null;
    }
  }
}
