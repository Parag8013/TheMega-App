// lib/features/transactions/presentation/widgets/calculator_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../accounts/providers/account_provider.dart';
import '../../../accounts/presentation/screens/add_account_screen.dart';
import '../../../../core/utils/currency_formatter.dart';

class CalculatorSheet extends StatefulWidget {
  final String category;
  final IconData categoryIcon;
  final String transactionType;
  final Function(double amount, String note, DateTime date, String accountId)
  onSubmit;

  const CalculatorSheet({
    Key? key,
    required this.category,
    required this.categoryIcon,
    required this.transactionType,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _displayAmount = '0';
  String _actualAmount = '0';
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  final TextEditingController _noteController = TextEditingController();
  bool _hasDecimalPoint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountProvider = context.read<AccountProvider>();
      if (accountProvider.accounts.isNotEmpty) {
        setState(() {
          _selectedAccountId = accountProvider.accounts.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    setState(() {
      if (_actualAmount == '0' && digit != '0') {
        _actualAmount = digit;
      } else if (_actualAmount != '0') {
        _actualAmount += digit;
      }
      _updateDisplay();
    });
  }

  void _addDecimalPoint() {
    if (!_hasDecimalPoint) {
      setState(() {
        if (_actualAmount == '0') {
          _actualAmount = '0.';
        } else {
          _actualAmount += '.';
        }
        _hasDecimalPoint = true;
        _updateDisplay();
      });
    }
  }

  void _backspace() {
    setState(() {
      if (_actualAmount.length > 1) {
        final removedChar = _actualAmount[_actualAmount.length - 1];
        if (removedChar == '.') {
          _hasDecimalPoint = false;
        }
        _actualAmount = _actualAmount.substring(0, _actualAmount.length - 1);
      } else {
        _actualAmount = '0';
        _hasDecimalPoint = false;
      }
      _updateDisplay();
    });
  }

  void _clear() {
    setState(() {
      _actualAmount = '0';
      _displayAmount = '0';
      _hasDecimalPoint = false;
    });
  }

  void _updateDisplay() {
    final amount = double.tryParse(_actualAmount) ?? 0;
    _displayAmount = CurrencyFormatter.format(amount);
  }

  void _showAccountSelector() {
    // Capture providers before showing modal
    final accountProvider = context.read<AccountProvider>();
    final themeData = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: accountProvider,
        child: Consumer<AccountProvider>(
          builder: (context, accountProvider, _) {
            if (accountProvider.accounts.isEmpty) {
              return _buildNoAccountsView(
                sheetContext,
                accountProvider,
                themeData,
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.grey),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: accountProvider.accounts.length,
                  itemBuilder: (context, index) {
                    final account = accountProvider.accounts[index];
                    final isSelected = _selectedAccountId == account.id;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? Colors.yellow[700]
                            : Colors.grey[700],
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                      title: Text(
                        account.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${account.accountType} • ${CurrencyFormatter.format(account.currentBalance)}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: Colors.yellow[700])
                          : null,
                      selected: isSelected,
                      onTap: () {
                        setState(() => _selectedAccountId = account.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoAccountsView(
    BuildContext context,
    AccountProvider accountProvider,
    ThemeData themeData,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          const Text(
            'No Accounts Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You need to create at least one account before adding transactions.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (newContext) => Theme(
                          data: themeData,
                          child: ChangeNotifierProvider.value(
                            value: accountProvider,
                            child: const AddAccountScreen(),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(primary: Colors.yellow[700]!),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Widget _buildCalcButton({
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    return Expanded(
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Colors.grey[800],
            foregroundColor: textColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: icon != null
              ? Icon(icon, size: 24)
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.yellow[700],
                  child: Icon(widget.categoryIcon, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Consumer<AccountProvider>(
                  builder: (context, provider, _) {
                    final selectedAccount = provider.accounts
                        .where((a) => a.id == _selectedAccountId)
                        .firstOrNull;

                    return TextButton.icon(
                      onPressed: _showAccountSelector,
                      icon: const Icon(Icons.account_balance_wallet),
                      label: Text(
                        selectedAccount?.name ?? 'Select Account',
                        style: TextStyle(
                          color: selectedAccount == null
                              ? Colors.red
                              : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Amount display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              '${widget.transactionType == 'expense' ? '-' : '+'}$_displayAmount',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: widget.transactionType == 'expense'
                    ? Colors.red
                    : Colors.green,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // Note input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter a note...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.note, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => _note = value,
            ),
          ),

          const SizedBox(height: 16),

          // Calculator buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Row 1
                Row(
                  children: [
                    _buildCalcButton(
                      label: '7',
                      onPressed: () => _addDigit('7'),
                    ),
                    _buildCalcButton(
                      label: '8',
                      onPressed: () => _addDigit('8'),
                    ),
                    _buildCalcButton(
                      label: '9',
                      onPressed: () => _addDigit('9'),
                    ),
                    _buildCalcButton(
                      label: DateFormat('dd MMM').format(_selectedDate),
                      onPressed: _showDatePicker,
                      backgroundColor: Colors.yellow[700],
                      textColor: Colors.black,
                    ),
                  ],
                ),

                // Row 2
                Row(
                  children: [
                    _buildCalcButton(
                      label: '4',
                      onPressed: () => _addDigit('4'),
                    ),
                    _buildCalcButton(
                      label: '5',
                      onPressed: () => _addDigit('5'),
                    ),
                    _buildCalcButton(
                      label: '6',
                      onPressed: () => _addDigit('6'),
                    ),
                    _buildCalcButton(
                      label: 'C',
                      onPressed: _clear,
                      backgroundColor: Colors.orange[700],
                    ),
                  ],
                ),

                // Row 3
                Row(
                  children: [
                    _buildCalcButton(
                      label: '1',
                      onPressed: () => _addDigit('1'),
                    ),
                    _buildCalcButton(
                      label: '2',
                      onPressed: () => _addDigit('2'),
                    ),
                    _buildCalcButton(
                      label: '3',
                      onPressed: () => _addDigit('3'),
                    ),
                    _buildCalcButton(
                      label: '',
                      icon: Icons.backspace,
                      onPressed: _backspace,
                      backgroundColor: Colors.red[700],
                    ),
                  ],
                ),

                // Row 4
                Row(
                  children: [
                    _buildCalcButton(label: '.', onPressed: _addDecimalPoint),
                    _buildCalcButton(
                      label: '0',
                      onPressed: () => _addDigit('0'),
                    ),
                    _buildCalcButton(
                      label: '00',
                      onPressed: () {
                        _addDigit('0');
                        _addDigit('0');
                      },
                    ),
                    _buildCalcButton(
                      label: '',
                      icon: Icons.check,
                      onPressed: _submitTransaction,
                      backgroundColor: Colors.green[700],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _submitTransaction() async {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_actualAmount) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check balance for expenses
    if (widget.transactionType == 'expense') {
      final accountProvider = context.read<AccountProvider>();
      final selectedAccount = accountProvider.accounts
          .where((a) => a.id == _selectedAccountId)
          .firstOrNull;

      if (selectedAccount != null && selectedAccount.currentBalance < amount) {
        // Show popup dialog for low balance
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Low Balance',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your account balance is insufficient for this transaction.',
                  style: TextStyle(color: Colors.grey[300]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Balance:',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            '₹${selectedAccount.currentBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaction Amount:',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            '₹${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shortfall:',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            '₹${(amount - selectedAccount.currentBalance).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Do you want to proceed anyway?',
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Proceed Anyway'),
              ),
            ],
          ),
        );

        if (shouldProceed != true) {
          return; // User cancelled
        }
      }
    }

    widget.onSubmit(amount, _note, _selectedDate, _selectedAccountId!);
  }
}
