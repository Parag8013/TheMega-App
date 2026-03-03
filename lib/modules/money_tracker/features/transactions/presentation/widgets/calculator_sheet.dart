// lib/features/transactions/presentation/widgets/calculator_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../accounts/providers/account_provider.dart';
import '../../../accounts/presentation/screens/add_account_screen.dart';
import '../../../../core/utils/currency_formatter.dart';

class CalculatorSheet extends StatefulWidget {
  final String category;
  final IconData categoryIcon;
  final Color? categoryColor;
  final String transactionType;
  final Function(double amount, String note, DateTime date, String accountId)
      onSubmit;

  const CalculatorSheet({
    Key? key,
    required this.category,
    required this.categoryIcon,
    this.categoryColor,
    required this.transactionType,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _expression = '0';
  String _displayAmount = '0';
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();
  bool _noteFieldFocused = false;

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
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  // --- Expression evaluation ---
  double _evaluate(String expr) {
    try {
      // Replace display symbols with math symbols
      expr = expr.replaceAll('×', '*').replaceAll('÷', '/');

      // Handle percentage: convert "X%" to "(X/100)"
      expr = expr.replaceAllMapped(
        RegExp(r'(\d+\.?\d*)%'),
        (m) => '(${m.group(1)}/100)',
      );

      // Simple expression parser supporting +, -, *, /
      return _parseExpression(expr);
    } catch (e) {
      return 0;
    }
  }

  double _parseExpression(String expr) {
    expr = expr.trim();
    if (expr.isEmpty) return 0;

    // Find last + or - (not inside parentheses, not at start)
    int parenDepth = 0;
    int lastAddSub = -1;
    for (int i = expr.length - 1; i >= 0; i--) {
      if (expr[i] == ')') parenDepth++;
      if (expr[i] == '(') parenDepth--;
      if (parenDepth == 0 && (expr[i] == '+' || expr[i] == '-') && i > 0) {
        lastAddSub = i;
        break;
      }
    }

    if (lastAddSub > 0) {
      final left = _parseExpression(expr.substring(0, lastAddSub));
      final op = expr[lastAddSub];
      final right = _parseTerm(expr.substring(lastAddSub + 1));
      return op == '+' ? left + right : left - right;
    }

    return _parseTerm(expr);
  }

  double _parseTerm(String expr) {
    expr = expr.trim();
    if (expr.isEmpty) return 0;

    // Find last * or /
    int parenDepth = 0;
    int lastMulDiv = -1;
    for (int i = expr.length - 1; i >= 0; i--) {
      if (expr[i] == ')') parenDepth++;
      if (expr[i] == '(') parenDepth--;
      if (parenDepth == 0 && (expr[i] == '*' || expr[i] == '/') && i > 0) {
        lastMulDiv = i;
        break;
      }
    }

    if (lastMulDiv > 0) {
      final left = _parseTerm(expr.substring(0, lastMulDiv));
      final op = expr[lastMulDiv];
      final right = _parseFactor(expr.substring(lastMulDiv + 1));
      if (op == '/') {
        return right != 0 ? left / right : 0;
      }
      return left * right;
    }

    return _parseFactor(expr);
  }

  double _parseFactor(String expr) {
    expr = expr.trim();
    if (expr.startsWith('(') && expr.endsWith(')')) {
      return _parseExpression(expr.substring(1, expr.length - 1));
    }
    return double.tryParse(expr) ?? 0;
  }

  // --- Input handlers ---
  void _addDigit(String digit) {
    setState(() {
      if (_expression == '0' && digit != '0') {
        _expression = digit;
      } else if (_expression == '0' && digit == '0') {
        // Don't add leading zeros
      } else {
        _expression += digit;
      }
      _updateDisplay();
    });
  }

  void _addDecimalPoint() {
    setState(() {
      // Find the last number segment (after any operator)
      final lastSegment = _expression.split(RegExp(r'[+\-×÷]')).last;
      if (!lastSegment.contains('.')) {
        if (_expression == '0') {
          _expression = '0.';
        } else {
          _expression += '.';
        }
        _updateDisplay();
      }
    });
  }

  void _addOperator(String op) {
    setState(() {
      final lastChar = _expression[_expression.length - 1];
      // Replace operator if last char is already an operator
      if ('+-×÷'.contains(lastChar)) {
        _expression = _expression.substring(0, _expression.length - 1) + op;
      } else if (lastChar != '.') {
        _expression += op;
      }
      _updateDisplay();
    });
  }

  void _addPercent() {
    setState(() {
      final lastChar = _expression[_expression.length - 1];
      if (!('+-×÷.%'.contains(lastChar)) && _expression != '0') {
        _expression += '%';
        _updateDisplay();
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_expression.length > 1) {
        _expression = _expression.substring(0, _expression.length - 1);
      } else {
        _expression = '0';
      }
      _updateDisplay();
    });
  }

  void _clear() {
    setState(() {
      _expression = '0';
      _displayAmount = '0';
    });
  }

  void _updateDisplay() {
    final amount = _evaluate(_expression);
    _displayAmount = CurrencyFormatter.format(amount.abs());
  }

  // --- Keyboard handler ---
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_noteFieldFocused) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Digit keys
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      _addDigit('0');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      _addDigit('1');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      _addDigit('2');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      _addDigit('3');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      _addDigit('4');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      _addDigit('5');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      _addDigit('6');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      _addDigit('7');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      _addDigit('8');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      _addDigit('9');
      return KeyEventResult.handled;
    }

    // Operators
    if (key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
      _addOperator('+');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _addOperator('-');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.numpadMultiply ||
        key == LogicalKeyboardKey.asterisk) {
      _addOperator('×');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.numpadDivide ||
        key == LogicalKeyboardKey.slash) {
      _addOperator('÷');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.percent) {
      _addPercent();
      return KeyEventResult.handled;
    }

    // Decimal
    if (key == LogicalKeyboardKey.period ||
        key == LogicalKeyboardKey.numpadDecimal) {
      _addDecimalPoint();
      return KeyEventResult.handled;
    }

    // Backspace
    if (key == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }

    // Delete = clear
    if (key == LogicalKeyboardKey.delete) {
      _clear();
      return KeyEventResult.handled;
    }

    // Enter = submit
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _submitTransaction();
      return KeyEventResult.handled;
    }

    // Escape = close
    if (key == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _showAccountSelector() {
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
                  child: const Text(
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
                        backgroundColor:
                            isSelected ? Colors.yellow[700] : Colors.grey[700],
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                      title: Text(
                        account.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
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
                    side: const BorderSide(color: Colors.grey),
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
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 52,
        margin: const EdgeInsets.all(3),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Colors.grey[800],
            foregroundColor: textColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          child: icon != null
              ? Icon(icon, size: 22)
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.categoryColor ?? Colors.yellow[700]!;

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
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
                    backgroundColor: iconColor.withOpacity(0.2),
                    child: Icon(widget.categoryIcon, color: iconColor),
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

            // Expression display (small, shows the math expression)
            if (_expression.contains(RegExp(r'[+\-×÷%]')))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _expression,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

            // Amount display (big, shows the result)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              child: Focus(
                onFocusChange: (hasFocus) {
                  _noteFieldFocused = hasFocus;
                  if (!hasFocus) {
                    _keyboardFocusNode.requestFocus();
                  }
                },
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
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                    _keyboardFocusNode.requestFocus();
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Calculator buttons - 5 columns
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  // Row 1: 7 8 9 ÷ Date
                  Row(
                    children: [
                      _buildCalcButton(
                          label: '7', onPressed: () => _addDigit('7')),
                      _buildCalcButton(
                          label: '8', onPressed: () => _addDigit('8')),
                      _buildCalcButton(
                          label: '9', onPressed: () => _addDigit('9')),
                      _buildCalcButton(
                        label: '÷',
                        onPressed: () => _addOperator('÷'),
                        backgroundColor: Colors.blueGrey[700],
                      ),
                      _buildCalcButton(
                        label: DateFormat('dd MMM').format(_selectedDate),
                        onPressed: _showDatePicker,
                        backgroundColor: Colors.yellow[700],
                        textColor: Colors.black,
                      ),
                    ],
                  ),

                  // Row 2: 4 5 6 × C
                  Row(
                    children: [
                      _buildCalcButton(
                          label: '4', onPressed: () => _addDigit('4')),
                      _buildCalcButton(
                          label: '5', onPressed: () => _addDigit('5')),
                      _buildCalcButton(
                          label: '6', onPressed: () => _addDigit('6')),
                      _buildCalcButton(
                        label: '×',
                        onPressed: () => _addOperator('×'),
                        backgroundColor: Colors.blueGrey[700],
                      ),
                      _buildCalcButton(
                        label: 'C',
                        onPressed: _clear,
                        backgroundColor: Colors.orange[700],
                      ),
                    ],
                  ),

                  // Row 3: 1 2 3 - ⌫
                  Row(
                    children: [
                      _buildCalcButton(
                          label: '1', onPressed: () => _addDigit('1')),
                      _buildCalcButton(
                          label: '2', onPressed: () => _addDigit('2')),
                      _buildCalcButton(
                          label: '3', onPressed: () => _addDigit('3')),
                      _buildCalcButton(
                        label: '-',
                        onPressed: () => _addOperator('-'),
                        backgroundColor: Colors.blueGrey[700],
                      ),
                      _buildCalcButton(
                        label: '',
                        icon: Icons.backspace,
                        onPressed: _backspace,
                        backgroundColor: Colors.red[700],
                      ),
                    ],
                  ),

                  // Row 4: . 0 % + ✓
                  Row(
                    children: [
                      _buildCalcButton(label: '.', onPressed: _addDecimalPoint),
                      _buildCalcButton(
                          label: '0', onPressed: () => _addDigit('0')),
                      _buildCalcButton(
                        label: '%',
                        onPressed: _addPercent,
                        backgroundColor: Colors.blueGrey[700],
                      ),
                      _buildCalcButton(
                        label: '+',
                        onPressed: () => _addOperator('+'),
                        backgroundColor: Colors.blueGrey[700],
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

            const SizedBox(height: 16),
          ],
        ),
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

    final amount = _evaluate(_expression);
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
          return;
        }
      }
    }

    widget.onSubmit(amount, _note, _selectedDate, _selectedAccountId!);
  }
}
