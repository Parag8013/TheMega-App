import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/recurring_payment_provider.dart';
import '../../../accounts/providers/account_provider.dart';
import 'category_settings_screen.dart';
import 'budget_settings_screen.dart';
import 'recurring_payments_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          _buildSettingTile(
            context,
            icon: Icons.category,
            title: 'Category Settings',
            subtitle: 'Manage expense and income categories',
            onTap: () {
              final categoryProvider = context.read<CategoryProvider>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: categoryProvider,
                    child: const CategorySettingsScreen(),
                  ),
                ),
              );
            },
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildSettingTile(
            context,
            icon: Icons.repeat,
            title: 'Regular Payments',
            subtitle: 'Set up recurring payments',
            onTap: () {
              final categoryProvider = context.read<CategoryProvider>();
              final accountProvider = context.read<AccountProvider>();
              final recurringProvider = context
                  .read<RecurringPaymentProvider>();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: recurringProvider),
                      ChangeNotifierProvider.value(value: categoryProvider),
                      ChangeNotifierProvider.value(value: accountProvider),
                    ],
                    child: const RecurringPaymentsScreen(),
                  ),
                ),
              );
            },
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildSettingTile(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Budget Settings',
            subtitle: 'Set monthly budgets for categories',
            onTap: () {
              final categoryProvider = context.read<CategoryProvider>();
              final budgetProvider = context.read<BudgetProvider>();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: budgetProvider),
                      ChangeNotifierProvider.value(value: categoryProvider),
                    ],
                    child: const BudgetSettingsScreen(),
                  ),
                ),
              );
            },
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildSettingTile(
            context,
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'Manage your profile',
            onTap: () {
              // TODO: Implement profile screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.yellow[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[400], fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
