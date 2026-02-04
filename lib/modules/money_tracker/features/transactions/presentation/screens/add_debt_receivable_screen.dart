// lib/features/transactions/presentation/screens/add_debt_receivable_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/debt_receivables_provider.dart';
import '../../../settings/providers/category_provider.dart';
import '../../../accounts/providers/account_provider.dart';
import '../../../../core/models/debt_receivable_model.dart';
import '../../../../core/utils/currency_formatter.dart';

class AddDebtReceivableScreen extends StatefulWidget {
  const AddDebtReceivableScreen({Key? key}) : super(key: key);

  @override
  State<AddDebtReceivableScreen> createState() =>
      _AddDebtReceivableScreenState();
}

class _AddDebtReceivableScreenState extends State<AddDebtReceivableScreen> {
  String _type = 'receivable'; // Default to receivable
  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _displayAmount = '0';
  String _actualAmount = '0';
  bool _hasDecimalPoint = false;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;

  @override
  void dispose() {
    _personNameController.dispose();
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

  void _submitDebtReceivable() async {
    if (_personNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter person name'),
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

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.yellow)),
    );

    try {
      final debtReceivable = DebtReceivable(
        type: _type,
        personName: _personNameController.text.trim(),
        amount: amount,
        category: _selectedCategory!,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );

      final provider = context.read<DebtReceivablesProvider>();
      final success = await provider.addDebtReceivable(debtReceivable);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_type == 'debt' ? 'Debt' : 'Receivable'} added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Close the form and return true
        Navigator.pop(context, true);
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = _type == 'debt'
        ? categoryProvider.expenseCategories
        : categoryProvider.incomeCategories;

    // Set default category if not selected
    if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.first.label;
    }

    final color = _type == 'debt' ? Colors.red : Colors.green;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Debt/Receivable',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTypeSelector(
                  'Debt',
                  'debt',
                  Icons.arrow_upward,
                  Colors.red,
                ),
                const SizedBox(width: 20),
                _buildTypeSelector(
                  'Receivable',
                  'receivable',
                  Icons.arrow_downward,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Person name input
            TextField(
              controller: _personNameController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: _type == 'debt' ? 'I owe to' : 'Owes me',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'Enter person name',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(Icons.person, color: color),
              ),
            ),
            const SizedBox(height: 20),

            // Amount display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '₹$_displayAmount',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 20),

            // Category selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category.label,
                      child: Row(
                        children: [
                          Icon(category.icon, color: category.color, size: 20),
                          const SizedBox(width: 12),
                          Text(category.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Note input
            TextField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter a note...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.note, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Calculator buttons
            Column(
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
                      onPressed: _selectDate,
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
                      onPressed: _submitDebtReceivable,
                      backgroundColor: Colors.green[700],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = value;
          _selectedCategory = null; // Reset category when type changes
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[700]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
