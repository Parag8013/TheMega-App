// lib/features/dashboard/presentation/screens/dashboard_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../transactions/providers/transaction_provider.dart';
import '../../../transactions/providers/debt_receivables_provider.dart';
import '../../../accounts/providers/account_provider.dart';
import '../../../charts/providers/charts_provider.dart';
import '../../../settings/providers/recurring_payment_provider.dart';
import '../../../shared/widgets/calendar_dialog.dart';
import '../../../transactions/presentation/screens/add_transaction_screen.dart';
import '../../../accounts/presentation/screens/accounts_list_screen.dart';
import '../../../charts/presentation/screens/charts_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../settings/providers/budget_provider.dart';
import '../../../settings/providers/category_provider.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../../core/models/transaction_model.dart';
import '../widgets/balance_header.dart';
import '../widgets/transaction_list.dart';
import 'calendar_view_screen.dart';
import '../../../../core/services/platform_aware_sms.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionProvider = context.read<TransactionProvider>();
      final accountProvider = context.read<AccountProvider>();
      final debtReceivablesProvider = context.read<DebtReceivablesProvider>();

      // Link transaction provider with account provider for balance updates
      transactionProvider.setAccountProvider(accountProvider);

      accountProvider.loadAccounts();
      transactionProvider.setSelectedDate(DateTime.now());

      // Load debt/receivables data on app start
      debtReceivablesProvider.loadDebtReceivables();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      title: const Text(
        'Money Tracker',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () {
            // Navigate back to mega app home
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          tooltip: 'Back to Mega App',
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearch(context),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _navigateToCalendarView(context),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: ListView(
        children: [
          GestureDetector(
            onTap: () => _showEditUsernameDialog(context),
            child: DrawerHeader(
              decoration: BoxDecoration(color: Colors.yellow[700]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<String>(
                    future: _getUsername(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'User',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  Text(
                    DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now()),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.white),
            title: const Text(
              'Accounts',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (newContext) => Theme(
                    data: Theme.of(context),
                    child: MultiProvider(
                      providers: [
                        ChangeNotifierProvider.value(
                          value: context.read<AccountProvider>(),
                        ),
                        ChangeNotifierProvider.value(
                          value: context.read<TransactionProvider>(),
                        ),
                      ],
                      child: const AccountsListScreen(),
                    ),
                  ),
                ),
              );
            },
          ),

          const Divider(color: Colors.grey),

          // 🎯 SMS SECTION (Android only)
          if (Platform.isAndroid) ...[
            ListTile(
              leading: Icon(Icons.auto_awesome, color: Colors.yellow[700]),
              title: const Text(
                'SMS Auto-Detection',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Automatically detect transactions from SMS',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: Icon(Icons.settings, color: Colors.grey[400], size: 20),
              onTap: () => _showSmsSettings(context),
            ),
            ListTile(
              leading: const Icon(Icons.sms, color: Colors.white),
              title: const Text(
                'SMS Permissions',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _requestSmsPermissions(context),
            ),
          ] else ...[
            // Show info message on non-Android platforms
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PlatformAwareSmsService.buildPlatformStatusWidget(context),
            ),
          ],

          const Divider(color: Colors.grey),

          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text(
              'Settings',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              final accountProvider = context.read<AccountProvider>();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (newContext) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: accountProvider),
                    ],
                    child: Theme(
                      data: Theme.of(context),
                      child: const SettingsScreen(),
                    ),
                  ),
                ),
              );
              // Reload transactions when coming back from settings
              if (context.mounted) {
                context.read<TransactionProvider>().loadTransactionsByMonth(
                  context.read<TransactionProvider>().selectedDate.year,
                  context.read<TransactionProvider>().selectedDate.month,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.yellow),
          );
        }

        if (provider.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red[400], size: 64),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage ?? 'Something went wrong',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadTransactionsByMonth(
                    provider.selectedDate.year,
                    provider.selectedDate.month,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Group transactions by date (recurring payments are now real transactions)
        final transactionGroups = _groupTransactionsByDate(
          provider.transactions,
        );

        return Column(
          children: [
            // Balance Header
            BalanceHeader(
              selectedDate: provider.selectedDate,
              totalIncome: provider.totalIncome,
              totalExpense: provider.totalExpense,
              balance: provider.balance,
              onCalendarTap: () => _showCalendarDialog(context),
            ),

            // Transaction List
            Expanded(
              child: TransactionList(transactionGroups: transactionGroups),
            ),
          ],
        );
      },
    );
  }

  Map<DateTime, List<MoneyTransaction>> _groupTransactionsByDate(
    List<MoneyTransaction> transactions,
  ) {
    final grouped = <DateTime, List<MoneyTransaction>>{};

    for (final transaction in transactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }

      grouped[dateKey]!.add(transaction);
    }

    // Sort each day's transactions by time (newest first)
    for (final dateKey in grouped.keys) {
      grouped[dateKey]!.sort((a, b) => b.date.compareTo(a.date));
    }

    return grouped;
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: Colors.grey[900],
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.receipt_long, 'Records', 0),
            _buildBottomNavItem(Icons.pie_chart, 'Charts', 1),
            const SizedBox(width: 40), // Space for FAB
            _buildBottomNavItem(Icons.insert_drive_file, 'Reports', 2),
            _buildBottomNavItem(Icons.person, 'Me', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onBottomNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.yellow[700] : Colors.grey),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.yellow[700] : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        // Check if accounts exist before allowing transaction creation
        final accountProvider = context.read<AccountProvider>();
        if (accountProvider.accounts.isEmpty) {
          _showNoAccountsDialog();
          return;
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (newContext) => Theme(
              data: Theme.of(context),
              child: MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(
                    value: context.read<AccountProvider>(),
                  ),
                  ChangeNotifierProvider.value(
                    value: context.read<TransactionProvider>(),
                  ),
                  ChangeNotifierProvider.value(
                    value: context.read<DebtReceivablesProvider>(),
                  ),
                  ChangeNotifierProvider.value(
                    value: context.read<CategoryProvider>(),
                  ),
                ],
                child: const AddTransactionScreen(),
              ),
            ),
          ),
        );

        if (result == true) {
          // Refresh transactions after adding
          final transactionProvider = context.read<TransactionProvider>();
          transactionProvider.loadTransactionsByMonth(
            transactionProvider.selectedDate.year,
            transactionProvider.selectedDate.month,
          );
        }
      },
      backgroundColor: Colors.yellow[700],
      foregroundColor: Colors.black,
      child: const Icon(Icons.add, size: 32),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);

    switch (index) {
      case 1: // Charts
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (newContext) => Theme(
              data: Theme.of(context),
              child: MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(
                    value: context.read<AccountProvider>(),
                  ),
                  ChangeNotifierProvider.value(
                    value: context.read<TransactionProvider>(),
                  ),
                  ChangeNotifierProvider.value(
                    value: context.read<ChartsProvider>(),
                  ),
                ],
                child: const ChartsScreen(),
              ),
            ),
          ),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case 2: // Reports
        final transactionProvider = context.read<TransactionProvider>();
        final accountProvider = context.read<AccountProvider>();
        final budgetProvider = context.read<BudgetProvider>();
        final debtReceivablesProvider = context.read<DebtReceivablesProvider>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (newContext) => MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: transactionProvider),
                ChangeNotifierProvider.value(value: accountProvider),
                ChangeNotifierProvider.value(value: budgetProvider),
                ChangeNotifierProvider.value(value: debtReceivablesProvider),
              ],
              child: Theme(
                data: Theme.of(context),
                child: const ReportsScreen(),
              ),
            ),
          ),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case 3: // Me/Profile
        final accountProvider = context.read<AccountProvider>();
        final transactionProvider = context.read<TransactionProvider>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (newContext) => MultiProvider(
              providers: [ChangeNotifierProvider.value(value: accountProvider)],
              child: Theme(
                data: Theme.of(context),
                child: const SettingsScreen(),
              ),
            ),
          ),
        ).then((_) {
          setState(() => _currentIndex = 0);
          // Reload transactions when coming back from settings
          transactionProvider.loadTransactionsByMonth(
            transactionProvider.selectedDate.year,
            transactionProvider.selectedDate.month,
          );
        });
        break;
      default: // Records
        setState(() => _currentIndex = 0);
    }
  }

  void _showCalendarDialog(BuildContext context) {
    // Show the month/year picker dialog (Legacy behavior for BalanceHeader)
    final provider = context.read<TransactionProvider>();
    showDialog(
      context: context,
      builder: (context) => CalendarDialog(
        initialYear: provider.selectedDate.year,
        initialMonth: provider.selectedDate.month - 1,
        onConfirm: (year, month) {
          provider.setSelectedDate(DateTime(year, month + 1));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _navigateToCalendarView(BuildContext context) {
    // Navigate to the new Calendar View Screen (For App Bar Icon)
    final transactionProvider = context.read<TransactionProvider>();
    final accountProvider = context.read<AccountProvider>();
    final debtProvider = context.read<DebtReceivablesProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (newContext) => Theme(
          data: Theme.of(context),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: transactionProvider),
              ChangeNotifierProvider.value(value: accountProvider),
              ChangeNotifierProvider.value(value: debtProvider),
              ChangeNotifierProvider.value(value: categoryProvider),
            ],
            child: const CalendarViewScreen(),
          ),
        ),
      ),
    );
  }

  void _showNoAccountsDialog() {
    // Capture providers before showing dialog
    final accountProvider = context.read<AccountProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final themeData = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'No Accounts Found',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You need to create at least one account before adding transactions.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (newContext) => Theme(
                    data: themeData,
                    child: MultiProvider(
                      providers: [
                        ChangeNotifierProvider.value(value: accountProvider),
                        ChangeNotifierProvider.value(
                          value: transactionProvider,
                        ),
                      ],
                      child: const AccountsListScreen(),
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[700],
              foregroundColor: Colors.black,
            ),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  // 🎯 SMS PERMISSIONS METHOD (Platform-aware)
  void _requestSmsPermissions(BuildContext context) async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SMS features are only available on Android devices'),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    Navigator.pop(context); // Close drawer

    try {
      final granted = await PlatformAwareSmsService.requestSmsPermission();

      if (!mounted) return;

      final snackBar = SnackBar(
        content: Row(
          children: [
            Icon(
              granted ? Icons.check_circle : Icons.error,
              color: granted ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                granted
                    ? '🎯 SMS Auto-Detection Enabled! Transactions will be added automatically.'
                    : '❌ SMS Permission Denied. Auto-detection won\'t work.',
              ),
            ),
          ],
        ),
        backgroundColor: granted ? Colors.green[800] : Colors.red[800],
        duration: const Duration(seconds: 4),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      if (granted) {
        // Re-initialize SMS service to start listening
        await PlatformAwareSmsService.initService();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting SMS permission: ${e.toString()}'),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  // 🎯 SMS SETTINGS DIALOG (Android only)
  void _showSmsSettings(BuildContext context) {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SMS features are only available on Android devices'),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }

    Navigator.pop(context); // Close drawer

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.yellow[700]),
            const SizedBox(width: 8),
            const Text(
              'SMS Auto-Detection',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Automatically detect and add transactions from bank SMS messages.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                'Supported Banks:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...[
                'HDFC Bank',
                'SBI',
                'ICICI Bank',
                'Axis Bank',
                'Kotak Bank',
                'Bank of Baroda',
              ].map(
                (bank) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[400],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(bank, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[900]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[700]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[400], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'SMS permissions are required for auto-detection to work.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[900]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[700]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.yellow[400],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Works automatically in background even when app is closed!',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestSmsPermissions(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[700],
              foregroundColor: Colors.black,
            ),
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: TransactionSearchDelegate(
        transactions: context.read<TransactionProvider>().transactions,
      ),
    );
  }

  Future<String> _getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('money_tracker_username') ?? 'User';
  }

  Future<void> _setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('money_tracker_username', username);
    setState(() {}); // Refresh the drawer
  }

  void _showEditUsernameDialog(BuildContext context) async {
    final usernameController = TextEditingController();
    final currentUsername = await _getUsername();
    usernameController.text = currentUsername;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Edit Username',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: usernameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.yellow[700]!, width: 2),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = usernameController.text.trim();
              if (newUsername.isNotEmpty) {
                await _setUsername(newUsername);
                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Username updated to "$newUsername"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[700],
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class TransactionSearchDelegate extends SearchDelegate<String> {
  final List transactions;

  TransactionSearchDelegate({required this.transactions});

  @override
  String get searchFieldLabel => 'Search by note, amount, or date';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'Search transactions',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final results = transactions.where((txn) {
      final lowerQuery = query.toLowerCase();
      final matchesNote = txn.note.toLowerCase().contains(lowerQuery);
      final matchesAmount = txn.amount.toString().contains(query);
      final matchesDate = DateFormat(
        'dd/MM/yyyy',
      ).format(txn.date).contains(query);
      return matchesNote || matchesAmount || matchesDate;
    }).toList();

    if (results.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final txn = results[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: txn.type == 'expense'
                    ? Colors.red[900]
                    : Colors.green[900],
                shape: BoxShape.circle,
              ),
              child: Icon(txn.categoryIcon, color: Colors.white, size: 20),
            ),
            title: Text(
              txn.category,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              txn.note.isEmpty ? 'No note' : txn.note,
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${txn.type == 'expense' ? '-' : '+'}₹${txn.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: txn.type == 'expense'
                        ? Colors.red[400]
                        : Colors.green[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('dd MMM').format(txn.date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
