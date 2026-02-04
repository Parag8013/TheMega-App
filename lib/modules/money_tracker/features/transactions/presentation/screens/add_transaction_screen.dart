// lib/features/transactions/presentation/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/category_grid.dart';
import '../widgets/calculator_sheet.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/debt_receivables_provider.dart';
import '../../../accounts/providers/account_provider.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/models/transaction_model.dart';
import 'add_debt_receivable_screen.dart';
import '../../../settings/providers/category_provider.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
          title: const Text(
            'Add',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.yellow[700],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Expense'),
              Tab(text: 'Income'),
              Tab(text: 'Transfer'),
              Tab(text: 'Debt/Receivable'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ExpenseTab(),
            _IncomeTab(),
            _TransferTab(),
            _DebtReceivableTab(),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, _) {
        return CategoryGrid(
          categories: categoryProvider.expenseCategories,
          transactionType: 'expense',
          onCategorySelected: (category) =>
              _showCalculator(context, category, 'expense'),
        );
      },
    );
  }

  void _showCalculator(BuildContext context, category, String type) {
    // Capture providers before showing modal
    final accountProvider = context.read<AccountProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final themeData = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Theme(
        data: themeData,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accountProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: CalculatorSheet(
              category: category.label,
              categoryIcon: category.icon,
              transactionType: type,
              onSubmit: (amount, note, date, accountId) async {
                final transaction = MoneyTransaction(
                  accountId: accountId,
                  amount: amount,
                  category: category.label,
                  note: note,
                  type: type,
                  date: date,
                );

                final success = await transactionProvider.addTransaction(
                  transaction,
                );

                if (success) {
                  // Update account provider to refresh balances
                  accountProvider.loadAccounts();
                  Navigator.pop(sheetContext); // Close calculator
                  Navigator.pop(context, true); // Close add screen with success
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, _) {
        return CategoryGrid(
          categories: categoryProvider.incomeCategories,
          transactionType: 'income',
          onCategorySelected: (category) =>
              _showCalculator(context, category, 'income'),
        );
      },
    );
  }

  void _showCalculator(BuildContext context, category, String type) {
    // Capture providers before showing modal
    final accountProvider = context.read<AccountProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final themeData = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Theme(
        data: themeData,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: accountProvider),
            ChangeNotifierProvider.value(value: transactionProvider),
          ],
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: CalculatorSheet(
              category: category.label,
              categoryIcon: category.icon,
              transactionType: type,
              onSubmit: (amount, note, date, accountId) async {
                final transaction = MoneyTransaction(
                  accountId: accountId,
                  amount: amount,
                  category: category.label,
                  note: note,
                  type: type,
                  date: date,
                );

                final success = await transactionProvider.addTransaction(
                  transaction,
                );

                if (success) {
                  accountProvider.loadAccounts();
                  Navigator.pop(sheetContext); // Close calculator
                  Navigator.pop(context, true); // Close add screen with success
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TransferTab extends StatefulWidget {
  @override
  _TransferTabState createState() => _TransferTabState();
}

class _TransferTabState extends State<_TransferTab> {
  String? _fromAccountId;
  String? _toAccountId;
  double _amount = 0;
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _selectFromAccount() async {
    final accountProvider = context.read<AccountProvider>();
    final accounts = accountProvider.accounts;

    if (accounts.isEmpty) {
      _showNoAccountsDialog();
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AccountSelector(
        accounts: accounts,
        title: 'Select Source Account',
        excludeAccountId: _toAccountId,
      ),
    );

    if (selected != null) {
      setState(() => _fromAccountId = selected);
    }
  }

  void _selectToAccount() async {
    final accountProvider = context.read<AccountProvider>();
    final accounts = accountProvider.accounts;

    if (accounts.isEmpty) {
      _showNoAccountsDialog();
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AccountSelector(
        accounts: accounts,
        title: 'Select Destination Account',
        excludeAccountId: _fromAccountId,
      ),
    );

    if (selected != null) {
      setState(() => _toAccountId = selected);
    }
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.yellow[700]!,
              onPrimary: Colors.black,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showNoAccountsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('No Accounts', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Please create at least two accounts to make a transfer.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.yellow[700])),
          ),
        ],
      ),
    );
  }

  void _submitTransfer() async {
    if (_fromAccountId == null || _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both accounts')),
      );
      return;
    }

    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination must be different'),
        ),
      );
      return;
    }

    final transactionProvider = context.read<TransactionProvider>();
    final accountProvider = context.read<AccountProvider>();

    // Get account names for display in notes
    final fromAccount = accountProvider.accounts.firstWhere(
      (a) => a.id == _fromAccountId,
    );
    final toAccount = accountProvider.accounts.firstWhere(
      (a) => a.id == _toAccountId,
    );

    // Create two transactions: one expense from source, one income to destination
    // Generate unique IDs and a shared transfer ID
    final timestamp = DateTime.now();
    final transferId = 'transfer_${timestamp.microsecondsSinceEpoch}';
    final expenseId = 'txn_${timestamp.microsecondsSinceEpoch}';
    final incomeId = 'txn_${timestamp.microsecondsSinceEpoch + 1}';

    // Build descriptive notes showing source and destination
    final transferNote = _note.isEmpty
        ? 'Transfer: ${fromAccount.name} → ${toAccount.name}'
        : '$_note (${fromAccount.name} → ${toAccount.name})';

    final expenseTransaction = MoneyTransaction(
      id: expenseId,
      accountId: _fromAccountId!,
      amount: _amount,
      category: 'Transfer',
      note: transferNote,
      type: 'expense',
      date: _selectedDate,
      transferId: transferId,
      transferType: 'transfer_out',
    );

    final incomeTransaction = MoneyTransaction(
      id: incomeId,
      accountId: _toAccountId!,
      amount: _amount,
      category: 'Transfer',
      note: transferNote,
      type: 'income',
      date: _selectedDate,
      transferId: transferId,
      transferType: 'transfer_in',
    );

    final success1 = await transactionProvider.addTransaction(
      expenseTransaction,
    );
    final success2 = await transactionProvider.addTransaction(
      incomeTransaction,
    );

    if (success1 && success2) {
      await accountProvider.loadAccounts();
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transfer failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    final fromAccount = _fromAccountId != null
        ? accountProvider.accounts.firstWhere(
            (a) => a.id == _fromAccountId,
            orElse: () => accountProvider.accounts.first,
          )
        : null;
    final toAccount = _toAccountId != null
        ? accountProvider.accounts.firstWhere(
            (a) => a.id == _toAccountId,
            orElse: () => accountProvider.accounts.first,
          )
        : null;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 600 : double.infinity,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Account selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TransferSelector(
                    label: 'From',
                    accountName: fromAccount?.name,
                    accountBalance: fromAccount?.currentBalance,
                    onTap: _selectFromAccount,
                    isDesktop: isDesktop,
                  ),
                  SizedBox(width: isDesktop ? 32 : 20),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.yellow[700],
                    size: isDesktop ? 36 : 32,
                  ),
                  SizedBox(width: isDesktop ? 32 : 20),
                  _TransferSelector(
                    label: 'To',
                    accountName: toAccount?.name,
                    accountBalance: toAccount?.currentBalance,
                    onTap: _selectToAccount,
                    isDesktop: isDesktop,
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 40 : 32),

              // Amount input
              Text(
                'Amount',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 32),
                decoration: InputDecoration(
                  hintText: '₹0',
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  border: InputBorder.none,
                  prefixText: '₹',
                  prefixStyle: TextStyle(
                    color: Colors.yellow[700],
                    fontSize: 32,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _amount = double.tryParse(value) ?? 0;
                  });
                },
              ),
              Divider(color: Colors.grey[800]),
              const SizedBox(height: 24),

              // Note input
              Text(
                'Note (Optional)',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.yellow[700]!),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _note = value);
                },
              ),
              const SizedBox(height: 24),

              // Date selector
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.yellow[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _submitTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: isDesktop ? 18 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Transfer',
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferSelector extends StatelessWidget {
  final String label;
  final String? accountName;
  final double? accountBalance;
  final VoidCallback onTap;
  final bool isDesktop;

  const _TransferSelector({
    required this.label,
    this.accountName,
    this.accountBalance,
    required this.onTap,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = isDesktop ? 140.0 : 100.0;
    final iconSize = isDesktop ? 40.0 : 32.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: isDesktop ? 200 : null,
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accountName != null
                ? Colors.yellow[700]!
                : Colors.grey[800]!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              accountName != null ? Icons.account_balance_wallet : Icons.add,
              color: accountName != null
                  ? Colors.yellow[700]
                  : Colors.grey[600],
              size: iconSize,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: isDesktop ? 13 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (accountName != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  accountName!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (accountBalance != null) ...[
                const SizedBox(height: 2),
                Text(
                  '₹${accountBalance!.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: isDesktop ? 13 : 12,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountSelector extends StatelessWidget {
  final List accounts;
  final String title;
  final String? excludeAccountId;

  const _AccountSelector({
    required this.accounts,
    required this.title,
    this.excludeAccountId,
  });

  @override
  Widget build(BuildContext context) {
    final filteredAccounts = accounts
        .where((account) => account.id != excludeAccountId)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...filteredAccounts.map(
            (account) => ListTile(
              leading: Icon(
                Icons.account_balance_wallet,
                color: Colors.yellow[700],
              ),
              title: Text(
                account.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '₹${account.currentBalance.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.grey[400]),
              ),
              onTap: () => Navigator.pop(context, account.id),
            ),
          ),
        ],
      ),
    );
  }
}

// Debt/Receivable Tab
class _DebtReceivableTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 20),
            Text(
              'Track Debt & Receivables',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Record money you owe or others owe you',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Builder(
              builder: (builderContext) {
                return ElevatedButton(
                  onPressed: () async {
                    try {
                      // Get providers from the builder context
                      final debtProvider = Provider.of<DebtReceivablesProvider>(
                        builderContext,
                        listen: false,
                      );
                      final categoryProvider = Provider.of<CategoryProvider>(
                        builderContext,
                        listen: false,
                      );

                      final result = await Navigator.push(
                        builderContext,
                        MaterialPageRoute(
                          builder: (context) => MultiProvider(
                            providers: [
                              ChangeNotifierProvider.value(value: debtProvider),
                              ChangeNotifierProvider.value(
                                value: categoryProvider,
                              ),
                            ],
                            child: const AddDebtReceivableScreen(),
                          ),
                        ),
                      );
                      if (result == true && builderContext.mounted) {
                        Navigator.pop(builderContext, true);
                      }
                    } catch (e) {
                      // Provider not available
                      if (builderContext.mounted) {
                        ScaffoldMessenger.of(builderContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Debt/Receivables feature is not available',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Debt/Receivable',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
