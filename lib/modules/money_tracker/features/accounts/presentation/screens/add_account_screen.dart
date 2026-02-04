// lib/features/accounts/presentation/screens/add_account_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../widgets/icon_selector.dart';
import '../../../../core/models/account_model.dart';
import '../../../../core/constants/account_constants.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({Key? key}) : super(key: key);

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = AccountConstants.accountTypes[0];
  String _selectedCurrency = AccountConstants.currencies[3]; // INR
  String _selectedIcon = AccountConstants.accountIcons.keys.first;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
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
          'Add Account',
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
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
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
                    .map((currency) => DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCurrency = value!);
                },
              ),
            ),

            const SizedBox(height: 20),

            _buildSection(
              'Initial Amount',
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration('0'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please enter initial amount';
                  }
                  final amount = double.tryParse(value!);
                  if (amount == null) {
                    return 'Please enter a valid amount';
                  }
                  if (amount < 0) {
                    return 'Amount cannot be negative';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            _buildSection(
              'Choose Icon',
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
                decoration: _buildInputDecoration('Add a note...'),
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
            Container(
              width: 3,
              height: 20,
              color: Colors.yellow[700],
            ),
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
      final account = Account(
        name: _nameController.text.trim(),
        accountType: _selectedType,
        currency: _selectedCurrency,
        initialBalance: double.parse(_amountController.text),
        iconName: _selectedIcon,
        note: _noteController.text.trim(),
      );

      final success = await context.read<AccountProvider>().addAccount(account);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account "${account.name}" created successfully!'),
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
              content: Text(error ?? 'Failed to create account'),
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