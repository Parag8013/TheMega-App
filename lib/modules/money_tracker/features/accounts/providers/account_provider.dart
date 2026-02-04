// lib/features/accounts/providers/account_provider.dart
import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/account_model.dart';

enum AccountStatus { initial, loading, loaded, error }

class AccountProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Account> _accounts = [];
  AccountStatus _status = AccountStatus.initial;
  String? _errorMessage;

  // Getters
  List<Account> get accounts => List.unmodifiable(_accounts);
  AccountStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AccountStatus.loading;
  bool get hasError => _status == AccountStatus.error;

  double get totalBalance =>
      _accounts.fold(0.0, (sum, account) => sum + account.currentBalance);

  // Load accounts
  Future<void> loadAccounts() async {
    try {
      _setLoading();
      _accounts = await _db.getAllAccounts();
      _setLoaded();
    } catch (e) {
      _setError('Failed to load accounts: ${e.toString()}');
    }
  }

  // Add account
  Future<bool> addAccount(Account account) async {
    try {
      await _db.insertAccount(account);
      await loadAccounts(); // Reload all accounts
      return true;
    } catch (e) {
      _setError('Failed to add account: ${e.toString()}');
      return false;
    }
  }

  // Get account by ID
  Account? getAccountById(String accountId) {
    try {
      return _accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }

  // Update account
  Future<bool> updateAccount(Account account) async {
    try {
      await _db.updateAccount(account);
      await loadAccounts(); // Reload all accounts
      return true;
    } catch (e) {
      _setError('Failed to update account: ${e.toString()}');
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount(String accountId) async {
    try {
      await _db.deleteAccount(accountId);
      await loadAccounts(); // Reload all accounts
      return true;
    } catch (e) {
      _setError('Failed to delete account: ${e.toString()}');
      return false;
    }
  }

  // Check if account has sufficient balance
  Future<bool> hasInsufficientBalance(String accountId, double amount) async {
    try {
      final balance = await _db.getAccountBalance(accountId);
      return balance < amount;
    } catch (e) {
      return true; // Assume insufficient if error
    }
  }

  // Private state management
  void _setLoading() {
    _status = AccountStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoaded() {
    _status = AccountStatus.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AccountStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AccountStatus.error) {
      _status = AccountStatus.loaded;
    }
    notifyListeners();
  }
}
