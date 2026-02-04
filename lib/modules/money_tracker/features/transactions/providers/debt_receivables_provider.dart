// lib/features/transactions/providers/debt_receivables_provider.dart
import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/debt_receivable_model.dart';

enum DebtReceivableStatus { initial, loading, loaded, error }

class DebtReceivablesProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<DebtReceivable> _debtReceivables = [];
  DebtReceivableStatus _status = DebtReceivableStatus.initial;
  String? _errorMessage;

  // Getters
  List<DebtReceivable> get debtReceivables =>
      List.unmodifiable(_debtReceivables);
  DebtReceivableStatus get status => _status;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == DebtReceivableStatus.loading;
  bool get hasError => _status == DebtReceivableStatus.error;

  // Computed values
  List<DebtReceivable> get debts => _debtReceivables
      .where((dr) => dr.type == 'debt' && !dr.isSettled)
      .toList();

  List<DebtReceivable> get receivables => _debtReceivables
      .where((dr) => dr.type == 'receivable' && !dr.isSettled)
      .toList();

  double get totalDebt => debts.fold(0.0, (sum, dr) => sum + dr.amount);

  double get totalReceivable =>
      receivables.fold(0.0, (sum, dr) => sum + dr.amount);

  double get netPosition => totalReceivable - totalDebt;

  // Load all debt/receivables
  Future<void> loadDebtReceivables() async {
    try {
      _setLoading();
      final maps = await _db.getAllDebtReceivables();
      _debtReceivables = maps
          .map((map) => DebtReceivable.fromMap(map))
          .toList();
      _setLoaded();
    } catch (e) {
      _setError('Failed to load debt/receivables: ${e.toString()}');
    }
  }

  // Load unsettled only
  Future<void> loadUnsettledDebtReceivables() async {
    try {
      _setLoading();
      final maps = await _db.getUnsettledDebtReceivables();
      _debtReceivables = maps
          .map((map) => DebtReceivable.fromMap(map))
          .toList();
      _setLoaded();
    } catch (e) {
      _setError('Failed to load unsettled debt/receivables: ${e.toString()}');
    }
  }

  // Add debt/receivable
  Future<bool> addDebtReceivable(DebtReceivable debtReceivable) async {
    try {
      print('💾 Attempting to save debt/receivable: ${debtReceivable.toMap()}');
      await _db.insertDebtReceivable(debtReceivable.toMap());
      await loadDebtReceivables();
      print('✅ Debt/receivable saved successfully');
      return true;
    } catch (e) {
      print('❌ Error in addDebtReceivable: $e');
      _setError('Failed to add debt/receivable: ${e.toString()}');
      return false;
    }
  }

  // Update debt/receivable
  Future<bool> updateDebtReceivable(DebtReceivable debtReceivable) async {
    try {
      await _db.updateDebtReceivable(debtReceivable.toMap());
      await loadDebtReceivables();
      return true;
    } catch (e) {
      _setError('Failed to update debt/receivable: ${e.toString()}');
      return false;
    }
  }

  // Settle debt/receivable
  Future<bool> settleDebtReceivable(String id) async {
    try {
      await _db.settleDebtReceivable(id);
      await loadDebtReceivables();
      return true;
    } catch (e) {
      _setError('Failed to settle debt/receivable: ${e.toString()}');
      return false;
    }
  }

  // Delete debt/receivable
  Future<bool> deleteDebtReceivable(String id) async {
    try {
      await _db.deleteDebtReceivable(id);
      await loadDebtReceivables();
      return true;
    } catch (e) {
      _setError('Failed to delete debt/receivable: ${e.toString()}');
      return false;
    }
  }

  // Get totals
  Future<Map<String, double>> getTotals() async {
    try {
      return await _db.getDebtReceivableTotals();
    } catch (e) {
      return {'debt': 0.0, 'receivable': 0.0, 'net': 0.0};
    }
  }

  // Group by person
  Map<String, List<DebtReceivable>> get groupedByPerson {
    final grouped = <String, List<DebtReceivable>>{};

    for (final dr in _debtReceivables.where((dr) => !dr.isSettled)) {
      grouped.putIfAbsent(dr.personName, () => []).add(dr);
    }

    return grouped;
  }

  // Private state management methods
  void _setLoading() {
    _status = DebtReceivableStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoaded() {
    _status = DebtReceivableStatus.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = DebtReceivableStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_status == DebtReceivableStatus.error) {
      _status = DebtReceivableStatus.loaded;
    }
    notifyListeners();
  }
}
