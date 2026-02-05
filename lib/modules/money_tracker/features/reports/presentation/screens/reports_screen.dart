import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../transactions/providers/transaction_provider.dart';
import '../../../transactions/providers/debt_receivables_provider.dart';
import '../../../transactions/presentation/screens/debt_receivables_list_screen.dart';
import '../../../accounts/providers/account_provider.dart';
import '../../../settings/providers/budget_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Reports',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.yellow[700],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Analytics'),
            Tab(text: 'Accounts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_AnalyticsTab(), _AccountsTab()],
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, BudgetProvider>(
      builder: (context, transactionProvider, budgetProvider, child) {
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month);

        // Calculate monthly stats
        final monthlyTransactions = transactionProvider.transactions.where((
          txn,
        ) {
          return txn.date.year == now.year && txn.date.month == now.month;
        }).toList();

        double totalIncome = 0;
        double totalExpense = 0;

        for (var txn in monthlyTransactions) {
          if (txn.type == 'income') {
            totalIncome += txn.amount;
          } else if (txn.type == 'expense') {
            totalExpense += txn.amount;
          }
        }

        final balance = totalIncome - totalExpense;

        // Get budget info
        final monthlyBudget = budgetProvider.monthlyBudget;
        final isBudgetExceeded =
            monthlyBudget > 0 && totalExpense > monthlyBudget;

        // Category breakdown
        final Map<String, double> expenseByCategory = {};
        for (var txn in monthlyTransactions) {
          if (txn.type == 'expense') {
            expenseByCategory[txn.category] =
                (expenseByCategory[txn.category] ?? 0) + txn.amount;
          }
        }

        final sortedCategories = expenseByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Month Header
            Text(
              _getMonthYear(now),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Income',
                    totalIncome,
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Expenses',
                    totalExpense,
                    Icons.arrow_upward,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildSummaryCard(
              'Balance',
              balance,
              balance >= 0 ? Icons.trending_up : Icons.trending_down,
              balance >= 0 ? Colors.green : Colors.red,
              isWide: true,
            ),

            const SizedBox(height: 24),

            // Monthly Budget Status
            if (monthlyBudget > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isBudgetExceeded
                      ? Colors.red[900]!.withOpacity(0.3)
                      : Colors.green[900]!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isBudgetExceeded ? Colors.red : Colors.green,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isBudgetExceeded
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle,
                              color:
                                  isBudgetExceeded ? Colors.red : Colors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Monthly Budget',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isBudgetExceeded ? '⚠️ EXCEEDED' : '✓ On Track',
                          style: TextStyle(
                            color: isBudgetExceeded ? Colors.red : Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent: ${CurrencyFormatter.format(totalExpense)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Budget: ${CurrencyFormatter.format(monthlyBudget)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (totalExpense / monthlyBudget).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation(
                          isBudgetExceeded ? Colors.red : Colors.green,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    if (isBudgetExceeded) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Exceeded by: ${CurrencyFormatter.format(totalExpense - monthlyBudget)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'Remaining: ${CurrencyFormatter.format(monthlyBudget - totalExpense)}',
                        style: TextStyle(
                          color: Colors.green[300],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Category Breakdown
            if (sortedCategories.isNotEmpty) ...[
              Text(
                'Expenses by Category',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ...sortedCategories.map((entry) {
                final percentage = (entry.value / totalExpense * 100);
                final categoryBudget = budgetProvider.getCategoryBudget(
                  entry.key,
                );
                final isCategoryBudgetExceeded =
                    categoryBudget > 0 && entry.value > categoryBudget;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCategoryBudgetExceeded
                          ? Colors.red
                          : Colors.grey[800]!,
                      width: isCategoryBudgetExceeded ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isCategoryBudgetExceeded) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'OVER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(entry.value),
                                style: TextStyle(
                                  color: isCategoryBudgetExceeded
                                      ? Colors.red
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (categoryBudget > 0)
                                Text(
                                  'of ${CurrencyFormatter.format(categoryBudget)}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey[800],
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.yellow[700],
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Icon(Icons.bar_chart, size: 64, color: Colors.grey[700]),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses this month',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    IconData icon,
    Color color, {
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _AccountsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AccountProvider, DebtReceivablesProvider>(
      builder: (context, accountProvider, debtProvider, child) {
        final accounts = accountProvider.accounts;

        if (accounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: Colors.grey[700],
                ),
                const SizedBox(height: 16),
                Text(
                  'No accounts found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Calculate totals
        double totalBalance = 0;
        double totalAssets = 0;
        double totalLiabilities = 0;

        for (var account in accounts) {
          totalBalance += account.currentBalance;
          if (account.currentBalance >= 0) {
            totalAssets += account.currentBalance;
          } else {
            totalLiabilities += account.currentBalance.abs();
          }
        }

        // Try to get debt/receivables totals (optional - won't crash if provider not available)
        double totalDebt = 0;
        double totalReceivable = 0;
        double netPosition = 0;

        try {
          final debtProvider = Provider.of<DebtReceivablesProvider>(
            context,
            listen: false,
          );
          totalDebt = debtProvider.totalDebt;
          totalReceivable = debtProvider.totalReceivable;
          netPosition = debtProvider.netPosition;

          // Load data if needed
          if (debtProvider.status == DebtReceivableStatus.initial) {
            Future.microtask(() => debtProvider.loadUnsettledDebtReceivables());
          }
        } catch (e) {
          // Provider not available - skip debt/receivables section
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Net Worth Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.yellow[700]!, Colors.orange[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Net Worth',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(totalBalance),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Assets & Liabilities
            Row(
              children: [
                Expanded(
                  child: _buildFinancialCard(
                    'Assets',
                    totalAssets,
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFinancialCard(
                    'Liabilities',
                    totalLiabilities,
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Debt/Receivables Section (only show if data exists)
            if (totalDebt > 0 || totalReceivable > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Debt & Receivables',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: netPosition >= 0
                          ? Colors.green[900]!.withOpacity(0.3)
                          : Colors.red[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: netPosition >= 0 ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Net: ${CurrencyFormatter.format(netPosition)}',
                      style: TextStyle(
                        color: netPosition >= 0 ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildFinancialCard(
                      'Receivables',
                      totalReceivable,
                      Icons.arrow_downward,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFinancialCard(
                      'Debts',
                      totalDebt,
                      Icons.arrow_upward,
                      Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // View All Button
              ElevatedButton.icon(
                onPressed: () async {
                  final debtProvider = Provider.of<DebtReceivablesProvider>(
                    context,
                    listen: false,
                  );
                  final accountProvider = Provider.of<AccountProvider>(
                    context,
                    listen: false,
                  );
                  final transactionProvider = Provider.of<TransactionProvider>(
                    context,
                    listen: false,
                  );

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider.value(value: debtProvider),
                          ChangeNotifierProvider.value(value: accountProvider),
                          ChangeNotifierProvider.value(
                              value: transactionProvider),
                        ],
                        child: const DebtReceivablesListScreen(),
                      ),
                    ),
                  );

                  // Reload data when returning from list screen
                  debtProvider.loadDebtReceivables();
                },
                icon: const Icon(Icons.list),
                label: const Text('View All Transactions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],

            // Accounts List
            Text(
              'All Accounts',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            ...accounts.map((account) {
              final isPositive = account.currentBalance >= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.yellow[700]!.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.yellow[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            account.accountType,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(account.currentBalance),
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildFinancialCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
