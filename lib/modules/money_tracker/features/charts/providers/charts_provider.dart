// lib/features/charts/providers/charts_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/date_utils.dart';

class ChartsProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  String _selectedType = 'expense';
  String _selectedPeriod = 'month';
  DateTime _selectedDate = DateTime.now();

  Map<String, double> _categoryTotals = {};
  Map<String, double> _dailyTotals = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String get selectedType => _selectedType;
  String get selectedPeriod => _selectedPeriod;
  DateTime get selectedDate => _selectedDate;
  Map<String, double> get categoryTotals => Map.unmodifiable(_categoryTotals);
  Map<String, double> get dailyTotals => Map.unmodifiable(_dailyTotals);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  double get total => _categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
  double get average => _categoryTotals.isEmpty ? 0.0 : total / _categoryTotals.length;

  // Setters
  void setType(String type) {
    if (_selectedType != type) {
      _selectedType = type;
      loadData();
    }
  }

  void setPeriod(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      _selectedDate = DateTime.now(); // Reset to current date
      loadData();
    }
  }

  void setDate(DateTime date) {
    if (!AppDateUtils.isSameMonth(_selectedDate, date) ||
        (_selectedPeriod == 'year' && _selectedDate.year != date.year)) {
      _selectedDate = date;
      loadData();
    }
  }

  // Load data
  Future<void> loadData() async {
    try {
      _setLoading(true);

      final startDate = _selectedPeriod == 'month'
          ? AppDateUtils.startOfMonth(_selectedDate)
          : AppDateUtils.startOfYear(_selectedDate);

      final endDate = _selectedPeriod == 'month'
          ? AppDateUtils.endOfMonth(_selectedDate)
          : AppDateUtils.endOfYear(_selectedDate);

      // Load category totals and daily totals in parallel
      final results = await Future.wait([
        _db.getCategoryTotals(_selectedType, startDate, endDate),
        _db.getDailyTotals(_selectedType, startDate, endDate),
      ]);

      _categoryTotals = results[0];
      _dailyTotals = results[1];

      _setLoaded();
    } catch (e) {
      _setError('Failed to load chart data: ${e.toString()}');
    }
  }

  // Get top categories (limited to top 10)
  List<MapEntry<String, double>> getTopCategories({int limit = 10}) {
    final sorted = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  // Get color for category (deterministic based on category name)
  Color getCategoryColor(String category) {
    final colors = [
      const Color(0xFF64B5F6), // Blue
      const Color(0xFFFFC107), // Amber/Yellow
      const Color(0xFFE91E63), // Pink
      const Color(0xFF4DB6AC), // Teal
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF00BCD4), // Cyan
    ];

    final index = category.hashCode.abs() % colors.length;
    return colors[index];
  }

  // Private state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _errorMessage = null;
    notifyListeners();
  }

  void _setLoaded() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}