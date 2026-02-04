// lib/features/accounts/presentation/screens/edit_account_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../widgets/icon_selector.dart';
import '../../../../core/models/account_model.dart';
import '../../../../core/constants/account_constants.dart';

class EditAccountScreen extends StatefulWidget {
  final Account account;

  const EditAccountScreen({Key? key, required this.account}) : super(key: key);

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  late final TextEditingController _currentBalanceController;

  late String _selectedType;
  late String _selectedCurrency;
  late String _selectedIcon;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _noteController = TextEditingController(text: widget.account.note);
    _currentBalanceController = TextEditingController(
      text: widget.account.currentBalance.toStringAsFixed(2),
    );
    _selectedType = widget.account.accountType;
    _selectedCurrency = widget.account.currency;
    _selectedIcon = widget.account.iconName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _currentBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Edit Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAccount,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.yellow,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.yellow[700],
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
            _buildSection(
              'Account Name',
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration('Enter account name'),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter account name';
                  }
                  if (value!.trim().length < 2) {
                    return 'Account name must be at least 2 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
            ),

            const SizedBox(height: 20),

            _buildSection(
              'Account Type',
              DropdownButtonFormField<String>(
                value: _selectedType,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(''),
                dropdownColor: Colors.grey[800],
                items: AccountConstants.accountTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
            ),

            const SizedBox(height: 20),

            _buildSection(
              'Currency',
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(''),
                dropdownColor: Colors.grey[800],
                items: AccountConstants.currencies
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCurrency = value!);
                },
              ),
            ),

            const SizedBox(height: 20),

            _buildSection(
              'Current Balance',
              TextFormField(
                controller: _currentBalanceController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration('Enter current balance'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter current balance';
                  }
                  final amount = double.tryParse(value!);
                  if (amount == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            _buildSection(
              'Icon',
              IconSelector(
                selectedIcon: _selectedIcon,
                onIconSelected: (icon) {
                  setState(() => _selectedIcon = icon);
                },
              ),
            ),

            const SizedBox(height: 20),

            _buildSection(
              'Note (Optional)',
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration('Enter a note'),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 20, color: Colors.yellow[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.yellow[700]!, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newBalance = double.parse(_currentBalanceController.text.trim());

      final updatedAccount = Account(
        id: widget.account.id,
        name: _nameController.text.trim(),
        accountType: _selectedType,
        currency: _selectedCurrency,
        initialBalance: widget.account.initialBalance,
        currentBalance: newBalance,
        iconName: _selectedIcon,
        note: _noteController.text.trim(),
        createdAt: widget.account.createdAt,
        updatedAt: DateTime.now(),
      );

      final success = await context.read<AccountProvider>().updateAccount(
        updatedAccount,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Account "${updatedAccount.name}" updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          final error = context.read<AccountProvider>().errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to update account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
