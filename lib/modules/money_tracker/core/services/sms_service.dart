// lib/core/services/sms_service.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';

@pragma('vm:entry-point')
void backgroundSmsListener(SmsMessage message) async {
  print("🎯 BACKGROUND SMS RECEIVED!");
  print("📱 From: ${message.address}");
  print("📝 Body: ${message.body}");
  print("⏰ Date: ${message.date}");

  if (message.body != null && message.address != null) {
    try {
      await SmsService.parseAndSaveTransaction(message.body!, message.address!);
      print("✅ Background SMS processed successfully");
    } catch (e) {
      print("❌ Background SMS processing failed: $e");
    }
  }
}

class SmsService {
  static final Telephony _telephony = Telephony.instance;
  static final DatabaseHelper _db = DatabaseHelper.instance;
  static bool _isInitialized = false;

  // 🚀 FIXED initialization method
  static Future<void> initService() async {
    print("🎯 Initializing SMS service...");

    if (_isInitialized) {
      print("ℹ️ SMS service already initialized");
      return;
    }

    try {
      // Check SMS permission first
      final smsPermission = await Permission.sms.status;
      print("📱 SMS Permission: $smsPermission");

      if (smsPermission.isGranted) {
        print("🔧 Setting up SMS listeners...");

        // FIXED: No return value assignment
        _telephony.listenIncomingSms(
          onNewMessage: (SmsMessage message) {
            print("🎯 FOREGROUND SMS RECEIVED!");
            print("📱 From: ${message.address}");
            print("📝 Body: ${message.body}");

            if (message.body != null && message.address != null) {
              parseAndSaveTransaction(message.body!, message.address!);
            }
          },
          onBackgroundMessage: backgroundSmsListener,
          listenInBackground: true,
        );

        // Verify telephony permissions
        final bool? canReceiveSms = await _telephony.requestSmsPermissions;
        print("📥 Telephony SMS Permission: $canReceiveSms");

        _isInitialized = true;
        print("✅ SMS Auto-Detection Service ACTIVE!");
      } else {
        print("❌ SMS permission not granted: $smsPermission");
      }
    } catch (e) {
      print("❌ SMS service initialization error: $e");
      print("❌ Error details: ${e.toString()}");
    }
  }

  // 🔄 FIXED request permissions method
  static Future<bool> requestSmsPermission() async {
    print("🔐 Requesting SMS permissions...");

    try {
      // Request SMS permission
      final smsStatus = await Permission.sms.request();
      print("📱 SMS Permission Status: $smsStatus");

      if (smsStatus.isGranted) {
        print("✅ SMS Permission granted!");

        // Try to get telephony permissions
        try {
          final bool? telephonyPermission =
              await _telephony.requestSmsPermissions;
          print("📡 Telephony Permission: $telephonyPermission");
        } catch (e) {
          print("⚠️ Telephony permission request failed: $e");
        }

        return true;
      } else if (smsStatus.isPermanentlyDenied) {
        print("🚫 SMS Permission permanently denied");
        return false;
      } else {
        print("❌ SMS Permission denied: $smsStatus");
        return false;
      }
    } catch (e) {
      print("❌ Error requesting SMS permission: $e");
      return false;
    }
  }

  // 🎯 Enhanced SMS parsing with better logging
  static Future<void> parseAndSaveTransaction(
    String smsBody,
    String sender,
  ) async {
    print("\n🔍 ===================");
    print("🔍 PARSING SMS");
    print("🔍 From: $sender");
    print("🔍 Body: $smsBody");
    print("🔍 ===================");

    try {
      // Check if it's from a bank
      if (!_isFromBank(sender)) {
        print("ℹ️ SMS not from a recognized bank: $sender");
        return;
      }

      final transaction = _extractTransactionFromSMS(smsBody, sender);
      if (transaction != null) {
        print("✅ Transaction extracted: $transaction");
        await _saveTransaction(transaction);
        print("✅ Transaction saved successfully!");

        // Send a notification
        _sendTransactionNotification(transaction);
      } else {
        print("ℹ️ No valid transaction found in SMS");
      }
    } catch (e) {
      print("❌ Error parsing SMS: $e");
      print("❌ Stack trace: ${StackTrace.current}");
    }
  }

  // 🏦 Check if SMS is from a bank
  static bool _isFromBank(String sender) {
    final bankKeywords = [
      'hdfc',
      'sbi',
      'icici',
      'axis',
      'kotak',
      'bob',
      'pnb',
      'bank',
      'paytm',
      'phonepe',
      'gpay',
      'upi',
      'card',
      'alert',
    ];

    final senderLower = sender.toLowerCase();
    final isBank = bankKeywords.any((keyword) => senderLower.contains(keyword));
    print("🏦 Is '$sender' a bank? $isBank");
    return isBank;
  }

  // 🎯 ENHANCED TRANSACTION EXTRACTION
  static TransactionData? _extractTransactionFromSMS(
    String smsBody,
    String sender,
  ) {
    print("🔍 Analyzing SMS content...");

    // 💳 ENHANCED DEBIT PATTERNS (Expenses)
    final debitPatterns = [
      // HDFC Patterns
      RegExp(r'spent\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'txn\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'sent\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),

      // SBI Patterns
      RegExp(r'debited\s+by\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'debited\s+by\s+([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(
        r'a\/c\s+\w+\s*[-]*\s*debited\s+by\s+([\d,]+\.?\d*)',
        caseSensitive: false,
      ),

      // UPI Patterns
      RegExp(r'upi.*debited.*?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'debited.*?([\d,]+\.?\d*).*upi', caseSensitive: false),

      // Generic patterns
      RegExp(r'debited\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'withdrawn\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'purchase\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'paid\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];

    // 💰 ENHANCED CREDIT PATTERNS (Income)
    final creditPatterns = [
      RegExp(r'credited to .*? rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'credited\s+by\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'credited\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(
        r'a\/c\s+\w+\s*[-]*\s*credited\s+by\s+rs\.?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(r'received\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'deposited\s+rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];

    // Check for debit transactions
    print("🔍 Checking for debit patterns...");
    for (int i = 0; i < debitPatterns.length; i++) {
      final pattern = debitPatterns[i];
      final match = pattern.firstMatch(smsBody);
      if (match != null) {
        final amount = _parseAmount(match.group(1)!);
        print("💳 DEBIT FOUND! Pattern $i matched, Amount: $amount");
        if (amount > 0) {
          final merchant = _extractMerchant(smsBody);
          final transaction = TransactionData(
            amount: amount,
            type: 'expense',
            merchant: merchant,
            category: _categorizeMerchant(merchant),
            bank: _identifyBank(sender),
          );
          print("💳 Created expense transaction: $transaction");
          return transaction;
        }
      }
    }

    // Check for credit transactions
    print("🔍 Checking for credit patterns...");
    for (int i = 0; i < creditPatterns.length; i++) {
      final pattern = creditPatterns[i];
      final match = pattern.firstMatch(smsBody);
      if (match != null) {
        final amount = _parseAmount(match.group(1)!);
        print("💰 CREDIT FOUND! Pattern $i matched, Amount: $amount");
        if (amount > 0) {
          final merchant = _extractMerchant(smsBody);
          final transaction = TransactionData(
            amount: amount,
            type: 'income',
            merchant: merchant,
            category: _categorizeIncome(merchant),
            bank: _identifyBank(sender),
          );
          print("💰 Created income transaction: $transaction");
          return transaction;
        }
      }
    }

    print("ℹ️ No transaction patterns matched");
    return null;
  }

  // 💰 Parse amount from string
  static double _parseAmount(String amountStr) {
    final cleanAmount = amountStr.replaceAll(',', '').replaceAll(' ', '');
    final amount = double.tryParse(cleanAmount) ?? 0.0;
    print("💰 Parsed amount '$amountStr' -> $amount");
    return amount;
  }

  // 🏪 Extract merchant/description
  static String _extractMerchant(String smsBody) {
    print("🏪 Extracting merchant from: $smsBody");

    final merchantPatterns = [
      RegExp(
        r'at\s+([^on\n]+?)(?:\s+on|\s+by|\s+ref|\s+not)',
        caseSensitive: false,
      ),
      RegExp(r'to\s+([^on\n]+?)(?:\s+on|\s+ref|\s+not)', caseSensitive: false),
      RegExp(
        r'from\s+([^on\n]+?)(?:\s+on|\s+ref|\s+not)',
        caseSensitive: false,
      ),
      RegExp(r'trf\s+to\s+([^on\n]+?)(?:\s+ref|\s+not)', caseSensitive: false),
      RegExp(
        r'transfer\s+from\s+([^on\n]+?)(?:\s+ref|\s+not)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in merchantPatterns) {
      final match = pattern.firstMatch(smsBody);
      if (match != null) {
        final merchant = match.group(1)?.trim() ?? '';
        if (merchant.isNotEmpty && merchant.length > 2) {
          final cleaned = _cleanMerchantName(merchant);
          print("🏪 Extracted merchant: '$merchant' -> '$cleaned'");
          return cleaned;
        }
      }
    }

    print("🏪 No merchant found, using default");
    return "SMS Transaction";
  }

  static String _cleanMerchantName(String merchant) {
    return merchant
        .replaceAll(RegExp(r'\d+'), '') // Remove numbers
        .replaceAll(RegExp(r'[*@#]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' ') // Clean multiple spaces
        .trim()
        .split(' ')
        .take(3) // First 3 words only
        .join(' ')
        .toLowerCase()
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  static String _categorizeMerchant(String merchant) {
    final merchantLower = merchant.toLowerCase();
    print("🏷️ Categorizing merchant: '$merchant'");

    final categoryMap = {
      // Shopping
      'amazon': 'Shopping', 'flipkart': 'Shopping', 'myntra': 'Shopping',
      'nykaa': 'Beauty', 'bigbasket': 'Shopping', 'pay': 'Shopping',

      // Food
      'swiggy': 'Food', 'zomato': 'Food', 'dominos': 'Food',
      'mcdonald': 'Food', 'kfc': 'Food', 'pizza': 'Food',

      // Transport
      'uber': 'Transportation',
      'ola': 'Transportation',
      'rapido': 'Transportation',
      'metro': 'Transportation', 'petrol': 'Car', 'fuel': 'Car',

      // Entertainment
      'netflix': 'Entertainment',
      'prime': 'Entertainment',
      'spotify': 'Entertainment',
      'bookmyshow': 'Entertainment',

      // Utilities
      'electricity': 'Home', 'water': 'Home', 'gas': 'Home',
      'mobile': 'Phone', 'airtel': 'Phone', 'jio': 'Phone',

      // Medical
      'hospital': 'Health', 'medical': 'Health', 'pharmacy': 'Health',
    };

    for (final key in categoryMap.keys) {
      if (merchantLower.contains(key)) {
        print("🏷️ Categorized '$merchant' as '${categoryMap[key]}'");
        return categoryMap[key]!;
      }
    }

    // Default categorization based on keywords
    if (merchantLower.contains('card') || merchantLower.contains('credit')) {
      return 'Shopping';
    }
    if (merchantLower.contains('utility') || merchantLower.contains('bill')) {
      return 'Home';
    }

    print("🏷️ Using default category for '$merchant'");
    return 'Shopping'; // Default expense category
  }

  static String _categorizeIncome(String description) {
    final descLower = description.toLowerCase();

    if (descLower.contains('salary') || descLower.contains('sal'))
      return 'Salary';
    if (descLower.contains('bonus')) return 'Bonus';
    if (descLower.contains('interest')) return 'Investments';
    if (descLower.contains('dividend')) return 'Investments';
    if (descLower.contains('refund')) return 'Others';

    return 'Others';
  }

  static String _identifyBank(String sender) {
    final senderLower = sender.toLowerCase();

    if (senderLower.contains('hdfc')) return 'HDFC Bank';
    if (senderLower.contains('sbi')) return 'SBI';
    if (senderLower.contains('icici')) return 'ICICI Bank';
    if (senderLower.contains('axis')) return 'Axis Bank';
    if (senderLower.contains('kotak')) return 'Kotak Bank';
    if (senderLower.contains('bob')) return 'Bank of Baroda';
    if (senderLower.contains('pnb')) return 'Punjab National Bank';

    return 'Bank';
  }

  // 💾 Save transaction with better error handling
  static Future<void> _saveTransaction(TransactionData data) async {
    print("💾 Attempting to save transaction...");

    try {
      // Ensure database is ready
      await _db.database;
      print("💾 Database ready");

      // Get or create account
      final accounts = await _db.getAllAccounts();
      String accountId;

      if (accounts.isEmpty) {
        print("💾 No accounts found, creating default account");
        final defaultAccount = Account(
          name: '${data.bank} Account',
          accountType: 'Bank Account',
          currency: 'INR (₹)',
          initialBalance: 0,
          iconName: 'bank',
          note: 'Auto-created from SMS',
        );
        accountId = await _db.insertAccount(defaultAccount);
        print("💾 Created default account: $accountId");
      } else {
        accountId = accounts.first.id;
        print("💾 Using existing account: $accountId");
      }

      // Create transaction
      final transaction = MoneyTransaction(
        accountId: accountId,
        amount: data.amount,
        category: data.category,
        note: 'Auto: ${data.merchant}',
        type: data.type,
        date: DateTime.now(),
      );

      print(
        "💾 Inserting transaction: ${transaction.type} ₹${transaction.amount}",
      );
      await _db.insertTransaction(transaction);

      print("✅ SMS Transaction saved successfully!");
      print("✅ Type: ${data.type}");
      print("✅ Amount: ₹${data.amount}");
      print("✅ Category: ${data.category}");
      print("✅ Merchant: ${data.merchant}");
    } catch (e) {
      print("❌ Error saving SMS transaction: $e");
      print("❌ Stack trace: ${StackTrace.current}");
      rethrow;
    }
  }

  // 📱 Send notification about new transaction
  static void _sendTransactionNotification(TransactionData data) {
    print(
      "📱 Transaction notification: ${data.type} ₹${data.amount} - ${data.category}",
    );
    // You can add local notifications here later
  }

  // 🔄 Reset service (for troubleshooting)
  static Future<void> resetService() async {
    print("🔄 Resetting SMS service...");
    _isInitialized = false;
    await Future.delayed(const Duration(milliseconds: 500));
    await initService();
  }

  // 📊 Get service status
  static Future<Map<String, dynamic>> getServiceStatus() async {
    final smsPermission = await Permission.sms.status;
    final phonePermission = await Permission.phone.status;

    return {
      'initialized': _isInitialized,
      'smsPermission': smsPermission.toString(),
      'phonePermission': phonePermission.toString(),
      'canReceiveSms': await _telephony.requestSmsPermissions,
    };
  }
}

// 📊 Transaction data model
class TransactionData {
  final double amount;
  final String type;
  final String merchant;
  final String category;
  final String bank;

  TransactionData({
    required this.amount,
    required this.type,
    required this.merchant,
    required this.category,
    required this.bank,
  });

  @override
  String toString() {
    return 'TransactionData(amount: ₹$amount, type: $type, merchant: $merchant, category: $category, bank: $bank)';
  }
}
