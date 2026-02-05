// lib/core/database/database_helper.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../../../../core/services/module_launcher.dart';

class DatabaseHelper {
  static const String dbName = 'money_tracker.db';
  static const int dbVersion = 6; // Incremented to fix foreign key constraints

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  static ModuleContext? _moduleContext;

  /// Initialize database with module context for isolated storage
  void initializeWithContext(ModuleContext context) {
    _moduleContext = context;

    // Initialize sqflite for desktop platforms
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Use module context for isolated database path
    final String path;
    if (_moduleContext != null) {
      path = _moduleContext!.getDatabasePath(dbName);
      print('💰 Using module database path: $path');
    } else {
      // Fallback: Use a fixed path for early initialization (before module context is set)
      // This allows providers to load data during app startup
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? '';
        final docsPath =
            '$userProfile\\OneDrive\\Documents\\mega_app_modules\\money_tracker\\data';
        Directory(docsPath).createSync(recursive: true);
        path = '$docsPath\\$dbName';
      } else if (Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['HOME'] ?? '';
        final docsPath = '$home/Documents/mega_app_modules/money_tracker/data';
        Directory(docsPath).createSync(recursive: true);
        path = '$docsPath/$dbName';
      } else {
        // For mobile, use standard path
        path = join(await getDatabasesPath(), dbName);
      }
      print('⚠️ Using fallback database path: $path');
    }

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new tables for version 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          icon_name TEXT NOT NULL,
          color_value INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          monthly_budget REAL NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS category_budgets (
          category_name TEXT PRIMARY KEY,
          amount REAL NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_payments (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          frequency TEXT NOT NULL CHECK(frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
          start_date TEXT NOT NULL,
          account_id TEXT NOT NULL,
          number_of_payments INTEGER,
          note TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recurring_payments_date ON recurring_payments(start_date)',
      );
    }

    if (oldVersion < 3) {
      // Add table to track processed recurring payment occurrences
      await db.execute('''
        CREATE TABLE IF NOT EXISTS processed_recurring_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recurring_payment_id TEXT NOT NULL,
          occurrence_date TEXT NOT NULL,
          transaction_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          UNIQUE(recurring_payment_id, occurrence_date),
          FOREIGN KEY (recurring_payment_id) REFERENCES recurring_payments (id) ON DELETE CASCADE,
          FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_processed_recurring_date ON processed_recurring_payments(occurrence_date)',
      );
    }

    if (oldVersion < 4) {
      // Add transfer tracking columns
      await db.execute('ALTER TABLE transactions ADD COLUMN transfer_id TEXT');
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN transfer_type TEXT',
      );

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_transfer ON transactions(transfer_id)',
      );
    }

    if (oldVersion < 5) {
      // Add debt/receivables table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debt_receivables (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL CHECK(type IN ('debt', 'receivable')),
          person_name TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          note TEXT,
          linked_account_id TEXT,
          linked_transaction_id TEXT,
          is_settled INTEGER NOT NULL DEFAULT 0,
          transaction_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (linked_account_id) REFERENCES accounts (id),
          FOREIGN KEY (linked_transaction_id) REFERENCES transactions (id)
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_debt_receivables_date ON debt_receivables(transaction_date)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_debt_receivables_person ON debt_receivables(person_name)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_debt_receivables_settled ON debt_receivables(is_settled)',
      );
    }

    if (oldVersion < 6) {
      // Fix foreign key constraints on debt_receivables table
      // Need to recreate table with ON DELETE SET NULL

      // Create temporary table with new schema
      await db.execute('''
        CREATE TABLE debt_receivables_new (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL CHECK(type IN ('debt', 'receivable')),
          person_name TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          note TEXT,
          linked_account_id TEXT,
          linked_transaction_id TEXT,
          is_settled INTEGER NOT NULL DEFAULT 0,
          transaction_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (linked_account_id) REFERENCES accounts (id) ON DELETE SET NULL,
          FOREIGN KEY (linked_transaction_id) REFERENCES transactions (id) ON DELETE SET NULL
        )
      ''');

      // Copy data from old table
      await db.execute('''
        INSERT INTO debt_receivables_new 
        SELECT * FROM debt_receivables
      ''');

      // Drop old table
      await db.execute('DROP TABLE debt_receivables');

      // Rename new table
      await db.execute(
          'ALTER TABLE debt_receivables_new RENAME TO debt_receivables');

      // Recreate indexes
      await db.execute(
        'CREATE INDEX idx_debt_receivables_date ON debt_receivables(transaction_date)',
      );
      await db.execute(
        'CREATE INDEX idx_debt_receivables_person ON debt_receivables(person_name)',
      );
      await db.execute(
        'CREATE INDEX idx_debt_receivables_settled ON debt_receivables(is_settled)',
      );
    }

    print('✅ Database upgraded to version $newVersion');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        account_type TEXT NOT NULL,
        currency TEXT NOT NULL,
        initial_balance REAL NOT NULL,
        current_balance REAL NOT NULL,
        icon_name TEXT NOT NULL,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        transaction_type TEXT NOT NULL CHECK(transaction_type IN ('income', 'expense')),
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        transfer_id TEXT,
        transfer_type TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        icon_name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monthly_budget REAL NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // Category Budgets table
    await db.execute('''
      CREATE TABLE category_budgets (
        category_name TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Recurring Payments table
    await db.execute('''
      CREATE TABLE recurring_payments (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        frequency TEXT NOT NULL CHECK(frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
        start_date TEXT NOT NULL,
        account_id TEXT NOT NULL,
        number_of_payments INTEGER,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    // Indexes for performance
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(transaction_date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_account ON transactions(account_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_type ON transactions(transaction_type)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_transfer ON transactions(transfer_id)',
    );
    await db.execute(
      'CREATE INDEX idx_recurring_payments_date ON recurring_payments(start_date)',
    );

    // Processed Recurring Payments table (for tracking which transactions have been created)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS processed_recurring_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recurring_payment_id TEXT NOT NULL,
        occurrence_date TEXT NOT NULL,
        transaction_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(recurring_payment_id, occurrence_date),
        FOREIGN KEY (recurring_payment_id) REFERENCES recurring_payments (id) ON DELETE CASCADE,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_processed_recurring_date ON processed_recurring_payments(occurrence_date)',
    );

    // Debt/Receivables table (version 5)
    await db.execute('''
      CREATE TABLE debt_receivables (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL CHECK(type IN ('debt', 'receivable')),
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        linked_account_id TEXT,
        linked_transaction_id TEXT,
        is_settled INTEGER NOT NULL DEFAULT 0,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (linked_account_id) REFERENCES accounts (id) ON DELETE SET NULL,
        FOREIGN KEY (linked_transaction_id) REFERENCES transactions (id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_debt_receivables_date ON debt_receivables(transaction_date)',
    );
    await db.execute(
      'CREATE INDEX idx_debt_receivables_person ON debt_receivables(person_name)',
    );
    await db.execute(
      'CREATE INDEX idx_debt_receivables_settled ON debt_receivables(is_settled)',
    );

    print('✅ Database created successfully');
  }

  // TRANSACTION OPERATIONS
  Future<String> insertTransaction(MoneyTransaction transaction) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Validate account exists
      final accountExists = await txn.query(
        'accounts',
        where: 'id = ? AND is_active = 1',
        whereArgs: [transaction.accountId],
      );

      if (accountExists.isEmpty) {
        throw Exception('Account not found');
      }

      final currentBalance = accountExists.first['current_balance'] as double;

      // Check insufficient balance for expenses
      if (transaction.type == 'expense' &&
          currentBalance < transaction.amount) {
        throw Exception('Insufficient balance');
      }

      // Insert transaction
      await txn.insert('transactions', transaction.toMap());

      // Update account balance
      final balanceChange = transaction.type == 'expense'
          ? -transaction.amount
          : transaction.amount;

      await txn.update(
        'accounts',
        {
          'current_balance': currentBalance + balanceChange,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [transaction.accountId],
      );

      return transaction.id;
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Get transaction details before deleting
      final transactionMaps = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (transactionMaps.isEmpty) {
        throw Exception('Transaction not found');
      }

      final transaction = MoneyTransaction.fromMap(transactionMaps.first);

      // Delete the transaction
      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      // Reverse the balance change in the account
      final accountMaps = await txn.query(
        'accounts',
        where: 'id = ?',
        whereArgs: [transaction.accountId],
      );

      if (accountMaps.isNotEmpty) {
        final currentBalance = accountMaps.first['current_balance'] as double;
        final balanceChange = transaction.type == 'expense'
            ? transaction.amount // Add back expense amount
            : -transaction.amount; // Subtract income amount

        await txn.update(
          'accounts',
          {
            'current_balance': currentBalance + balanceChange,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [transaction.accountId],
        );
      }
    });
  }

  Future<void> updateTransaction(MoneyTransaction transaction) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Get old transaction to reverse its balance effect
      final oldTransactionMaps = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      if (oldTransactionMaps.isEmpty) {
        throw Exception('Transaction not found');
      }

      final oldTransaction = MoneyTransaction.fromMap(oldTransactionMaps.first);

      // Update the transaction
      await txn.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      // If account or amount or type changed, update balances
      if (oldTransaction.accountId != transaction.accountId ||
          oldTransaction.amount != transaction.amount ||
          oldTransaction.type != transaction.type) {
        // Reverse old transaction's balance effect
        final oldAccountMaps = await txn.query(
          'accounts',
          where: 'id = ?',
          whereArgs: [oldTransaction.accountId],
        );

        if (oldAccountMaps.isNotEmpty) {
          final oldBalance = oldAccountMaps.first['current_balance'] as double;
          final oldChange = oldTransaction.type == 'expense'
              ? oldTransaction.amount
              : -oldTransaction.amount;

          await txn.update(
            'accounts',
            {
              'current_balance': oldBalance + oldChange,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [oldTransaction.accountId],
          );
        }

        // Apply new transaction's balance effect
        final newAccountMaps = await txn.query(
          'accounts',
          where: 'id = ?',
          whereArgs: [transaction.accountId],
        );

        if (newAccountMaps.isNotEmpty) {
          final newBalance = newAccountMaps.first['current_balance'] as double;
          final newChange = transaction.type == 'expense'
              ? -transaction.amount
              : transaction.amount;

          await txn.update(
            'accounts',
            {
              'current_balance': newBalance + newChange,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [transaction.accountId],
          );
        }
      }
    });
  }

  Future<List<MoneyTransaction>> getTransactionsByMonth(
    int year,
    int month,
  ) async {
    final db = await database;

    final startDate = DateTime(year, month, 1).toUtc();
    final endDate = DateTime(year, month + 1, 1).toUtc();

    final maps = await db.query(
      'transactions',
      where: 'transaction_date >= ? AND transaction_date < ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'transaction_date DESC, created_at DESC',
    );

    return maps.map((map) => MoneyTransaction.fromMap(map)).toList();
  }

  // ADDED: Missing method
  Future<List<MoneyTransaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;

    final maps = await db.query(
      'transactions',
      where: 'transaction_date >= ? AND transaction_date <= ?',
      whereArgs: [
        startDate.toUtc().toIso8601String(),
        endDate.toUtc().toIso8601String(),
      ],
      orderBy: 'transaction_date DESC',
    );

    return maps.map((map) => MoneyTransaction.fromMap(map)).toList();
  }

  // ACCOUNT OPERATIONS
  Future<String> insertAccount(Account account) async {
    final db = await database;
    await db.insert('accounts', account.toMap());
    return account.id;
  }

  Future<List<Account>> getAllAccounts() async {
    final db = await database;
    final maps = await db.query(
      'accounts',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<Account?> getAccountById(String accountId) async {
    final db = await database;
    final maps = await db.query(
      'accounts',
      where: 'id = ? AND is_active = 1',
      whereArgs: [accountId],
    );

    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<double> getAccountBalance(String accountId) async {
    final db = await database;
    final result = await db.query(
      'accounts',
      columns: ['current_balance'],
      where: 'id = ? AND is_active = 1',
      whereArgs: [accountId],
    );

    if (result.isEmpty) throw Exception('Account not found');
    return result.first['current_balance'] as double;
  }

  Future<void> updateAccount(Account account) async {
    final db = await database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccount(String accountId) async {
    final db = await database;
    // Soft delete by marking as inactive
    await db.update(
      'accounts',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [accountId],
    );
    // Also delete associated transactions
    await db.delete(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }

  // ADDED: Missing validation method
  Future<bool> canMakeTransaction(
    String accountId,
    double amount,
    String type,
  ) async {
    if (type != 'expense') return true;

    try {
      final balance = await getAccountBalance(accountId);
      return balance >= amount;
    } catch (e) {
      return false;
    }
  }

  // ADDED: Missing statistics methods
  Future<Map<String, double>> getCategoryTotals(
    String type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;

    final maps = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total
      FROM transactions 
      WHERE transaction_type = ? 
        AND transaction_date >= ? 
        AND transaction_date <= ?
      GROUP BY category
      ORDER BY total DESC
    ''',
      [
        type,
        startDate.toUtc().toIso8601String(),
        endDate.toUtc().toIso8601String(),
      ],
    );

    return Map.fromEntries(
      maps.map(
        (map) => MapEntry(
          map['category'] as String,
          (map['total'] as num).toDouble(),
        ),
      ),
    );
  }

  // ADDED: Missing daily totals method
  Future<Map<String, double>> getDailyTotals(
    String type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;

    final maps = await db.rawQuery(
      '''
      SELECT DATE(transaction_date) as date, SUM(amount) as total
      FROM transactions 
      WHERE transaction_type = ? 
        AND transaction_date >= ? 
        AND transaction_date <= ?
      GROUP BY DATE(transaction_date)
      ORDER BY date ASC
    ''',
      [
        type,
        startDate.toUtc().toIso8601String(),
        endDate.toUtc().toIso8601String(),
      ],
    );

    return Map.fromEntries(
      maps.map(
        (map) =>
            MapEntry(map['date'] as String, (map['total'] as num).toDouble()),
      ),
    );
  }

  // CATEGORY OPERATIONS
  Future<void> insertCategory(
    String id,
    String name,
    String iconName,
    int colorValue,
  ) async {
    final db = await database;
    await db.insert(
        'categories',
        {
          'id': id,
          'name': name,
          'icon_name': iconName,
          'color_value': colorValue,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'created_at DESC');
  }

  Future<void> deleteCategory(String name) async {
    final db = await database;
    await db.delete('categories', where: 'name = ?', whereArgs: [name]);
  }

  // BUDGET OPERATIONS
  Future<void> setMonthlyBudget(double amount) async {
    final db = await database;
    final existing = await db.query('budgets', limit: 1);

    if (existing.isEmpty) {
      await db.insert('budgets', {
        'monthly_budget': amount,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } else {
      await db.update(
        'budgets',
        {
          'monthly_budget': amount,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<double> getMonthlyBudget() async {
    final db = await database;
    final result = await db.query('budgets', limit: 1);
    if (result.isEmpty) return 0;
    return (result.first['monthly_budget'] as num).toDouble();
  }

  Future<void> setCategoryBudget(String categoryName, double amount) async {
    final db = await database;
    await db.insert(
        'category_budgets',
        {
          'category_name': categoryName,
          'amount': amount,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, double>> getAllCategoryBudgets() async {
    final db = await database;
    final maps = await db.query('category_budgets');
    return Map.fromEntries(
      maps.map(
        (map) => MapEntry(
          map['category_name'] as String,
          (map['amount'] as num).toDouble(),
        ),
      ),
    );
  }

  // RECURRING PAYMENT OPERATIONS
  Future<void> insertRecurringPayment(Map<String, dynamic> payment) async {
    final db = await database;
    await db.insert(
      'recurring_payments',
      payment,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllRecurringPayments() async {
    final db = await database;
    return await db.query('recurring_payments', orderBy: 'created_at DESC');
  }

  Future<void> deleteRecurringPayment(String id) async {
    final db = await database;
    await db.delete('recurring_payments', where: 'id = ?', whereArgs: [id]);
  }

  // Process recurring payments into real transactions
  Future<int> processRecurringPayments() async {
    final db = await database;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int processed = 0;

    // Get all recurring payments
    final payments = await getAllRecurringPayments();

    for (var paymentMap in payments) {
      final payment = _parseRecurringPayment(paymentMap);
      final startDate = payment['start_date'] as DateTime;
      final normalizedStart = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      // Process all occurrences from start date up to and including today
      DateTime checkDate = normalizedStart;
      int occurrenceCount = 0;
      final numberOfPayments = payment['number_of_payments'] as int?;

      while (!checkDate.isAfter(todayDate)) {
        // Check if we've reached the limit before processing
        if (numberOfPayments != null && occurrenceCount >= numberOfPayments) {
          break;
        }

        // Check if already processed for this date
        final alreadyProcessed = await _isAlreadyProcessed(
          payment['id'] as String,
          checkDate,
        );

        if (!alreadyProcessed) {
          try {
            // Create real transaction
            await _createTransactionFromRecurring(payment, checkDate);
            processed++;
          } catch (e) {
            print('Error processing recurring payment ${payment['id']}: $e');
          }
        }

        // Increment occurrence count after processing (or skipping)
        occurrenceCount++;

        // Move to next occurrence date
        final frequency = payment['frequency'] as String;
        switch (frequency) {
          case 'daily':
            checkDate = DateTime(
              checkDate.year,
              checkDate.month,
              checkDate.day + 1,
            );
            break;
          case 'weekly':
            checkDate = DateTime(
              checkDate.year,
              checkDate.month,
              checkDate.day + 7,
            );
            break;
          case 'monthly':
            checkDate = DateTime(
              checkDate.year,
              checkDate.month + 1,
              checkDate.day,
            );
            break;
          case 'yearly':
            checkDate = DateTime(
              checkDate.year + 1,
              checkDate.month,
              checkDate.day,
            );
            break;
        }
      }
    }

    return processed;
  }

  Map<String, dynamic> _parseRecurringPayment(Map<String, dynamic> payment) {
    return {
      'id': payment['id'],
      'name': payment['name'],
      'type': payment['type'],
      'category': payment['category'],
      'amount': (payment['amount'] as num).toDouble(),
      'frequency': payment['frequency'],
      'start_date': DateTime.parse(payment['start_date'] as String).toLocal(),
      'account_id': payment['account_id'],
      'number_of_payments': payment['number_of_payments'] as int?,
      'note': payment['note'] ?? '',
    };
  }

  Future<bool> _isAlreadyProcessed(
    String recurringPaymentId,
    DateTime date,
  ) async {
    final db = await database;
    final dateStr = date.toUtc().toIso8601String().split(
          'T',
        )[0]; // Get date part only

    final result = await db.query(
      'processed_recurring_payments',
      where: 'recurring_payment_id = ? AND occurrence_date LIKE ?',
      whereArgs: [recurringPaymentId, '$dateStr%'],
    );

    return result.isNotEmpty;
  }

  Future<void> _createTransactionFromRecurring(
    Map<String, dynamic> payment,
    DateTime date,
  ) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Create transaction ID based on normalized date (not milliseconds)
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final transactionId =
          'txn_recurring_${payment['id']}_${normalizedDate.millisecondsSinceEpoch}';

      // Check if transaction already exists
      final existingTransaction = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (existingTransaction.isNotEmpty) {
        // Transaction already exists, skip
        return;
      }

      // Validate account exists
      final accountExists = await txn.query(
        'accounts',
        where: 'id = ? AND is_active = 1',
        whereArgs: [payment['account_id']],
      );

      if (accountExists.isEmpty) {
        throw Exception('Account not found for recurring payment');
      }

      final currentBalance = accountExists.first['current_balance'] as double;
      final amount = payment['amount'] as double;
      final type = payment['type'] as String;

      // Check insufficient balance for expenses
      if (type == 'expense' && currentBalance < amount) {
        throw Exception('Insufficient balance for recurring payment');
      }

      // Insert transaction
      await txn.insert('transactions', {
        'id': transactionId,
        'account_id': payment['account_id'],
        'amount': amount,
        'category': payment['category'],
        'note':
            '🔄 ${payment['name']}${payment['note'].toString().isNotEmpty ? ' - ${payment['note']}' : ''}',
        'transaction_type': type,
        'transaction_date': DateTime(
          date.year,
          date.month,
          date.day,
          12,
          0,
          0,
        ).toUtc().toIso8601String(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Update account balance
      final balanceChange = type == 'expense' ? -amount : amount;

      await txn.update(
        'accounts',
        {
          'current_balance': currentBalance + balanceChange,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [payment['account_id']],
      );

      // Mark as processed
      await txn.insert('processed_recurring_payments', {
        'recurring_payment_id': payment['id'],
        'occurrence_date': DateTime(
          date.year,
          date.month,
          date.day,
          12,
          0,
          0,
        ).toUtc().toIso8601String(),
        'transaction_id': transactionId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

  // DEBT/RECEIVABLES OPERATIONS
  Future<String> insertDebtReceivable(
    Map<String, dynamic> debtReceivable,
  ) async {
    final db = await database;
    await db.insert('debt_receivables', debtReceivable);
    return debtReceivable['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getAllDebtReceivables() async {
    final db = await database;
    return await db.query('debt_receivables', orderBy: 'transaction_date DESC');
  }

  Future<List<Map<String, dynamic>>> getDebtReceivablesByType(
    String type,
  ) async {
    final db = await database;
    return await db.query(
      'debt_receivables',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'transaction_date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getUnsettledDebtReceivables() async {
    final db = await database;
    return await db.query(
      'debt_receivables',
      where: 'is_settled = 0',
      orderBy: 'transaction_date DESC',
    );
  }

  Future<void> updateDebtReceivable(Map<String, dynamic> debtReceivable) async {
    final db = await database;
    await db.update(
      'debt_receivables',
      debtReceivable,
      where: 'id = ?',
      whereArgs: [debtReceivable['id']],
    );
  }

  Future<void> settleDebtReceivable(String id) async {
    final db = await database;
    await db.update(
      'debt_receivables',
      {'is_settled': 1, 'updated_at': DateTime.now().toUtc().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDebtReceivable(String id) async {
    final db = await database;
    await db.delete('debt_receivables', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getDebtReceivableTotals() async {
    final db = await database;

    final debtResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM debt_receivables WHERE type = ? AND is_settled = 0',
      ['debt'],
    );

    final receivableResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM debt_receivables WHERE type = ? AND is_settled = 0',
      ['receivable'],
    );

    final totalDebt = (debtResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final totalReceivable =
        (receivableResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return {
      'debt': totalDebt,
      'receivable': totalReceivable,
      'net': totalReceivable - totalDebt,
    };
  }
}
