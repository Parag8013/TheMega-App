// lib/features/transactions/presentation/screens/debt_receivables_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/debt_receivables_provider.dart';
import '../../../../core/models/debt_receivable_model.dart';
import '../../../../core/utils/currency_formatter.dart';

class DebtReceivablesListScreen extends StatefulWidget {
  const DebtReceivablesListScreen({Key? key}) : super(key: key);

  @override
  State<DebtReceivablesListScreen> createState() =>
      _DebtReceivablesListScreenState();
}

class _DebtReceivablesListScreenState extends State<DebtReceivablesListScreen> {
  bool _showOnlyUnsettled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtReceivablesProvider>().loadDebtReceivables();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Debt & Receivables',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyUnsettled ? Icons.filter_list : Icons.filter_list_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _showOnlyUnsettled = !_showOnlyUnsettled);
            },
            tooltip: _showOnlyUnsettled ? 'Show All' : 'Show Unsettled Only',
          ),
        ],
      ),
      body: Consumer<DebtReceivablesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }

          final items = _showOnlyUnsettled
              ? provider.debtReceivables.where((dr) => !dr.isSettled).toList()
              : provider.debtReceivables;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    _showOnlyUnsettled
                        ? 'No unsettled debt/receivables'
                        : 'No debt/receivables found',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Group by person
          final grouped = <String, List<DebtReceivable>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.personName, () => []).add(item);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final personName = grouped.keys.elementAt(index);
              final personItems = grouped[personName]!;

              // Calculate totals for this person
              double totalDebt = 0;
              double totalReceivable = 0;
              for (final item in personItems) {
                if (!item.isSettled) {
                  if (item.type == 'debt') {
                    totalDebt += item.amount;
                  } else {
                    totalReceivable += item.amount;
                  }
                }
              }
              final netAmount = totalReceivable - totalDebt;

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: netAmount >= 0
                            ? Colors.green
                            : Colors.red,
                        child: Text(
                          personName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              personName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${personItems.length} transaction${personItems.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(netAmount.abs()),
                            style: TextStyle(
                              color: netAmount >= 0 ? Colors.green : Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            netAmount >= 0 ? 'You get' : 'You owe',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.white,
                  children: personItems
                      .map((item) => _buildDebtReceivableItem(item))
                      .toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDebtReceivableItem(DebtReceivable item) {
    final color = item.type == 'debt' ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isSettled ? Colors.grey[700]! : color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.type == 'debt' ? Icons.arrow_upward : Icons.arrow_downward,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(item.amount),
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: item.isSettled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      item.category,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (item.isSettled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[900]!.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: const Text(
                    'Settled',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.note,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(item.date),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
              Row(
                children: [
                  if (!item.isSettled) ...[
                    TextButton.icon(
                      onPressed: () => _settleDebtReceivable(item),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Settle'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    onPressed: () => _deleteDebtReceivable(item),
                    icon: const Icon(Icons.delete, size: 18),
                    color: Colors.red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _settleDebtReceivable(DebtReceivable item) {
    // Capture provider before showing dialog to avoid context issues
    final provider = context.read<DebtReceivablesProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Settle Transaction',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Mark this ${item.type} of ${CurrencyFormatter.format(item.amount)} as settled?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.settleDebtReceivable(item.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Marked as settled' : 'Failed to settle',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Settle'),
          ),
        ],
      ),
    );
  }

  void _deleteDebtReceivable(DebtReceivable item) {
    // Capture provider before showing dialog to avoid context issues
    final provider = context.read<DebtReceivablesProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Transaction',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete this ${item.type} of ${CurrencyFormatter.format(item.amount)}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.deleteDebtReceivable(item.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Deleted successfully' : 'Failed to delete',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
