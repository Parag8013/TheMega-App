// lib/features/settings/presentation/screens/edit_recurring_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recurring_payment_provider.dart';
import '../../providers/category_provider.dart';
import '../../../accounts/providers/account_provider.dart';

class EditRecurringPaymentScreen extends StatefulWidget {
  final RecurringPayment payment;

  const EditRecurringPaymentScreen({Key? key, required this.payment})
    : super(key: key);

  @override
  State<EditRecurringPaymentScreen> createState() =>
      _EditRecurringPaymentScreenState();
}

class _EditRecurringPaymentScreenState
    extends State<EditRecurringPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _numberOfPaymentsController;

  late String _type;
  String? _selectedCategory;
  late String _frequency;
  late DateTime _startDate;
  late bool _isUnlimited;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.payment.name);
    _amountController = TextEditingController(
      text: widget.payment.amount.toString(),
    );
    _noteController = TextEditingController(text: widget.payment.note);
    _numberOfPaymentsController = TextEditingController(
      text: widget.payment.numberOfPayments?.toString() ?? '',
    );

    _type = widget.payment.type;
    _selectedCategory = widget.payment.category;
    _frequency = widget.payment.frequency;
    _startDate = widget.payment.startDate;
    _isUnlimited = widget.payment.numberOfPayments == null;
    _selectedAccountId = widget.payment.accountId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _numberOfPaymentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final accountProvider = context.watch<AccountProvider>();

    final categories = _type == 'expense'
        ? categoryProvider.expenseCategories
        : categoryProvider.incomeCategories;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Edit Recurring Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _savePayment,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.yellow[700],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Payment Name
            _buildSectionTitle('Payment Name'),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Netflix Subscription',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter payment name';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Type Selection (Expense/Income)
            _buildSectionTitle('Type'),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    'Expense',
                    'expense',
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    'Income',
                    'income',
                    Icons.arrow_downward,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Category Selection
            _buildSectionTitle('Category'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
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
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Amount
            _buildSectionTitle('Amount'),
            TextFormField(
              controller: _amountController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  color: Colors.yellow[700],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter valid amount';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Frequency
            _buildSectionTitle('Frequency'),
            Row(
              children: [
                Expanded(child: _buildFrequencyButton('Daily', 'daily')),
                const SizedBox(width: 8),
                Expanded(child: _buildFrequencyButton('Weekly', 'weekly')),
                const SizedBox(width: 8),
                Expanded(child: _buildFrequencyButton('Monthly', 'monthly')),
                const SizedBox(width: 8),
                Expanded(child: _buildFrequencyButton('Yearly', 'yearly')),
              ],
            ),

            const SizedBox(height: 24),

            // Start Date
            _buildSectionTitle('Start Date'),
            InkWell(
              onTap: _selectStartDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Icon(
                      Icons.calendar_today,
                      color: Colors.yellow[700],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Number of Payments
            _buildSectionTitle('Number of Payments'),
            Row(
              children: [
                Checkbox(
                  value: _isUnlimited,
                  onChanged: (value) {
                    setState(() {
                      _isUnlimited = value ?? true;
                      if (_isUnlimited) {
                        _numberOfPaymentsController.clear();
                      }
                    });
                  },
                  activeColor: Colors.yellow[700],
                ),
                const Text('Unlimited', style: TextStyle(color: Colors.white)),
              ],
            ),
            if (!_isUnlimited) ...[
              TextFormField(
                controller: _numberOfPaymentsController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter number',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (!_isUnlimited) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter number of payments';
                    }
                    final num = int.tryParse(value);
                    if (num == null || num <= 0) {
                      return 'Please enter valid number';
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),

            // Account Selection
            if (accountProvider.accounts.isNotEmpty) ...[
              _buildSectionTitle('Account'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAccountId,
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    items: accountProvider.accounts.map((account) {
                      return DropdownMenuItem(
                        value: account.id,
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.yellow[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(account.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAccountId = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Note
            _buildSectionTitle('Note (Optional)'),
            TextFormField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a note...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String value, IconData icon) {
    final isSelected = _type == value;
    return InkWell(
      onTap: () {
        setState(() {
          _type = value;
          _selectedCategory = null; // Reset category when type changes
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow[700] : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.yellow[700]! : Colors.grey[800]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyButton(String label, String value) {
    final isSelected = _frequency == value;
    return InkWell(
      onTap: () {
        setState(() {
          _frequency = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow[700] : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.yellow[700]! : Colors.grey[800]!,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey[400],
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _savePayment() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      final payment = RecurringPayment(
        id: widget.payment.id, // Keep the same ID
        name: _nameController.text.trim(),
        type: _type,
        category: _selectedCategory!,
        amount: double.parse(_amountController.text.trim()),
        frequency: _frequency,
        startDate: _startDate,
        numberOfPayments: _isUnlimited
            ? null
            : int.parse(_numberOfPaymentsController.text.trim()),
        accountId: _selectedAccountId,
        note: _noteController.text.trim(),
      );

      context.read<RecurringPaymentProvider>().updatePayment(payment);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${payment.name} updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
