// lib/features/transactions/providers/transaction_provider.dart
import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/transaction_model.dart';
import '../../accounts/providers/account_provider.dart';

enum TransactionStatus { initial, loading, loaded, error }

class TransactionProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  AccountProvider? _accountProvider;

  // Set account provider to reload accounts after transactions
  void setAccountProvider(AccountProvider accountProvider) {
    _accountProvider = accountProvider;
  }

  List<MoneyTransaction> _transactions = [];
  TransactionStatus _status = TransactionStatus.initial;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  // Getters
  List<MoneyTransaction> get transactions => List.unmodifiable(_transactions);
  TransactionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  // Computed values
  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  bool get isLoading => _status == TransactionStatus.loading;
  bool get hasError => _status == TransactionStatus.error;

  // Set selected date and load transactions
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await loadTransactionsByMonth(date.year, date.month);
  }

  // Load transactions by month
  Future<void> loadTransactionsByMonth(int year, int month) async {
    try {
      _setLoading();

      // Process any pending recurring payments into real transactions
      await _db.processRecurringPayments();

      // Reload accounts to reflect new balances
      await _accountProvider?.loadAccounts();

      _transactions = await _db.getTransactionsByMonth(year, month);
      // Sort by date (recent to oldest)
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _setLoaded();
    } catch (e) {
      _setError('Failed to load transactions: ${e.toString()}');
    }
  }

  // Load transactions by date range
  Future<void> loadTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      _setLoading();
      _transactions = await _db.getTransactionsByDateRange(startDate, endDate);
      // Sort by date (recent to oldest)
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _setLoaded();
    } catch (e) {
      _setError('Failed to load transactions: ${e.toString()}');
    }
  }

  // Add transaction
  Future<bool> addTransaction(MoneyTransaction transaction) async {
    try {
      // Validate transaction before adding
      final canAdd = await _db.canMakeTransaction(
        transaction.accountId,
        transaction.amount,
        transaction.type,
      );

      if (!canAdd) {
        _setError('Insufficient balance for this transaction');
        return false;
      }

      await _db.insertTransaction(transaction);

      // Reload transactions for current period
      await loadTransactionsByMonth(_selectedDate.year, _selectedDate.month);

      // Reload accounts to update balances
      await _accountProvider?.loadAccounts();

      return true;
    } catch (e) {
      _setError('Failed to add transaction: ${e.toString()}');
      return false;
    }
  }

  // Get transactions grouped by date
  Map<DateTime, List<MoneyTransaction>> get transactionsGroupedByDate {
    final grouped = <DateTime, List<MoneyTransaction>>{};

    // Filter out transfer_in transactions to avoid showing duplicates
    final filteredTransactions = _transactions
        .where((t) => t.transferType != 'transfer_in')
        .toList();

    for (final transaction in filteredTransactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }

    // Sort dates in descending order
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Map.fromEntries(sortedEntries);
  }

  // Get category totals for a specific type and period
  Future<Map<String, double>> getCategoryTotals(
    String type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _db.getCategoryTotals(type, startDate, endDate);
    } catch (e) {
      return {};
    }
  }

  // Get daily totals for charts
  Future<Map<String, double>> getDailyTotals(
    String type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _db.getDailyTotals(type, startDate, endDate);
    } catch (e) {
      return {};
    }
  }

  // Private state management methods
  void _setLoading() {
    _status = TransactionStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoaded() {
    _status = TransactionStatus.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = TransactionStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  // Delete transaction
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _db.deleteTransaction(transactionId);

      // Reload transactions for current period
      await loadTransactionsByMonth(_selectedDate.year, _selectedDate.month);

      // Reload accounts to update balances
      await _accountProvider?.loadAccounts();

      return true;
    } catch (e) {
      _setError('Failed to delete transaction: ${e.toString()}');
      return false;
    }
  }

  // Update transaction
  Future<bool> updateTransaction(MoneyTransaction transaction) async {
    try {
      await _db.updateTransaction(transaction);

      // Reload transactions for current period
      await loadTransactionsByMonth(_selectedDate.year, _selectedDate.month);

      // Reload accounts to update balances
      await _accountProvider?.loadAccounts();

      return true;
    } catch (e) {
      _setError('Failed to update transaction: ${e.toString()}');
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_status == TransactionStatus.error) {
      _status = TransactionStatus.loaded;
    }
    notifyListeners();
  }
}
