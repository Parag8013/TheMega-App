// lib/features/charts/presentation/screens/charts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/line_chart_widget.dart';
import '../widgets/category_stats_list.dart';
import '../../providers/charts_provider.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({Key? key}) : super(key: key);

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChartsProvider>().loadData();
    });
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
        title: Consumer<ChartsProvider>(
          builder: (context, provider, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provider.selectedType == 'expense' ? 'Expenses' : 'Income',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  color: Colors.grey[800],
                  onSelected: (value) => provider.setType(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'expense',
                      child: Text('Expenses', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 'income',
                      child: Text('Income', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ChartsProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Period selector
              _buildPeriodSelector(provider),

              // Date selector
              _buildDateSelector(provider),

              // FIXED: Compact chart area (30% of screen)
              Container(
                height: 260, // Reduced from 380 to make it compact
                child: Column(
                  children: [
                    // Compact chart container
                    SizedBox(
                      height: 200, // Reduced from 300
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          PieChartWidget(provider: provider),
                          PieChartWidget(provider: provider, groupByDate: true),
                          LineChartWidget(provider: provider),
                        ],
                      ),
                    ),

                    // Tab indicators
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return GestureDetector(
                            onTap: () => _tabController.animateTo(index),
                            child: AnimatedBuilder(
                              animation: _tabController,
                              builder: (context, _) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: _tabController.index == index
                                        ? Colors.white
                                        : Colors.grey[600],
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // EXPANDED: Category statistics take most of the screen (70%)
              Expanded(
                child: CategoryStatsList(provider: provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(ChartsProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: ['month', 'year'].map((period) {
          final isSelected = period == provider.selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.setPeriod(period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  period.capitalize(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSelector(ChartsProvider provider) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 12,
        itemBuilder: (context, index) {
          final date = provider.selectedPeriod == 'month'
              ? DateTime.now().subtract(Duration(days: 30 * index))
              : DateTime(DateTime.now().year - index, 1, 1);

          final isSelected = provider.selectedPeriod == 'month'
              ? date.month == provider.selectedDate.month &&
              date.year == provider.selectedDate.year
              : date.year == provider.selectedDate.year;

          String label;
          if (provider.selectedPeriod == 'month') {
            label = index == 0 ? 'This Month' : DateFormat('MMM yyyy').format(date);
          } else {
            label = index == 0 ? 'This Year' : date.year.toString();
          }

          return GestureDetector(
            onTap: () => provider.setDate(date),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Colors.yellow[700]! : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}