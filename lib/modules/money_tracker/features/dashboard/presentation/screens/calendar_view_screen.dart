// lib/features/dashboard/presentation/screens/calendar_view_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../transactions/providers/transaction_provider.dart';
import '../../../transactions/providers/debt_receivables_provider.dart';
import '../../../accounts/providers/account_provider.dart';
import '../../../settings/providers/category_provider.dart';
import '../../../transactions/presentation/screens/add_transaction_screen.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({Key? key}) : super(key: key);

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  late DateTime _selectedMonth;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _pageController = PageController(
      initialPage: _selectedMonth.month - 1 + (_selectedMonth.year - 2020) * 12,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Weekday headers
              _buildWeekdayHeaders(),

              // Calendar grid
              Expanded(child: _buildCalendarGrid(provider, isLandscape)),

              // Legend
              if (!isLandscape) _buildLegend(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final accountProvider = context.read<AccountProvider>();
          final transactionProvider = context.read<TransactionProvider>();
          final debtProvider = context.read<DebtReceivablesProvider>();
          final categoryProvider = context.read<CategoryProvider>();

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (newContext) => Theme(
                data: Theme.of(context),
                child: MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: accountProvider),
                    ChangeNotifierProvider.value(value: transactionProvider),
                    ChangeNotifierProvider.value(value: debtProvider),
                    ChangeNotifierProvider.value(value: categoryProvider),
                  ],
                  child: const AddTransactionScreen(),
                ),
              ),
            ),
          );

          if (result == true) {
            // Refresh is handled by provider listeners usually, but we can force reload if needed
            // TransactionProvider updates automatically on add/edit if it was used in AddTransactionScreen
            // But CalendarViewScreen might rely on transactions list in provider
            setState(() {}); // Trigger rebuild to refresh totals
          }
        },
        backgroundColor: Colors.yellow[700],
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 1)),
      ),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(TransactionProvider provider, bool isLandscape) {
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    // Calculate transaction totals for each day
    final dailyTotals = <int, Map<String, double>>{};

    for (final transaction in provider.transactions) {
      if (transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month) {
        final day = transaction.date.day;

        if (!dailyTotals.containsKey(day)) {
          dailyTotals[day] = {'income': 0.0, 'expense': 0.0};
        }

        if (transaction.type == 'income') {
          dailyTotals[day]!['income'] =
              dailyTotals[day]!['income']! + transaction.amount;
        } else if (transaction.type == 'expense') {
          dailyTotals[day]!['expense'] =
              dailyTotals[day]!['expense']! + transaction.amount;
        }
      }
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: startingWeekday + daysInMonth,
      itemBuilder: (context, index) {
        if (index < startingWeekday) {
          return const SizedBox.shrink();
        }

        final day = index - startingWeekday + 1;
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
        final isToday =
            date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        final income = dailyTotals[day]?['income'] ?? 0.0;
        final expense = dailyTotals[day]?['expense'] ?? 0.0;
        final hasTransactions = income > 0 || expense > 0;

        return _buildDayCell(
          day: day,
          income: income,
          expense: expense,
          isToday: isToday,
          hasTransactions: hasTransactions,
          isLandscape: isLandscape,
        );
      },
    );
  }

  Widget _buildDayCell({
    required int day,
    required double income,
    required double expense,
    required bool isToday,
    required bool hasTransactions,
    required bool isLandscape,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? Colors.yellow[700]!.withOpacity(0.2)
            : Colors.grey[900],
        border: Border.all(
          color: isToday ? Colors.yellow[700]! : Colors.grey[800]!,
          width: isToday ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Day number
          Text(
            day.toString(),
            style: TextStyle(
              color: isToday ? Colors.yellow[700] : Colors.white,
              fontSize: isLandscape ? 14 : 12,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            ),
          ),

          if (hasTransactions) ...[
            const SizedBox(height: 2),

            // Income
            if (income > 0)
              Flexible(
                child: Text(
                  _formatAmount(income),
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: isLandscape ? 11 : 9,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Expense
            if (expense > 0)
              Flexible(
                child: Text(
                  _formatAmount(expense),
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: isLandscape ? 11 : 9,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[800]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.green[400]!, 'Income'),
          const SizedBox(width: 24),
          _buildLegendItem(Colors.red[400]!, 'Expense'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    } else if (amount >= 10000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}
