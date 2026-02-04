// lib/features/charts/presentation/widgets/category_stats_list.dart
import 'package:flutter/material.dart';
import '../../providers/charts_provider.dart';

class CategoryStatsList extends StatelessWidget {
  final ChartsProvider provider;

  const CategoryStatsList({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.yellow),
      );
    }

    final categories = provider.getTopCategories();

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No categories found',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final percentage = (category.value / provider.total * 100);
          final color = _getColorForCategory(category.key, index);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 0.5),
            ),
            child: Row(
              children: [
                // Category icon with matching color
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(category.key),
                    color: color,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 16),

                // Category details - takes most space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category name and percentage in one row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Progress bar with amount
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
                            _formatAmount(category.value),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Format amount to match target image
  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else if (amount >= 10000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else if (amount >= 1000) {
      return '${amount.toStringAsFixed(0)}';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Color _getColorForCategory(String category, int index) {
    final colors = [
      const Color(0xFFFFCA28), // Yellow/Gold for Electronics
      const Color(0xFF26C6DA), // Cyan for Travel
      const Color(0xFFEC407A), // Pink for Food
      const Color(0xFF42A5F5), // Blue for Shopping
      const Color(0xFF66BB6A), // Green
      const Color(0xFFAB47BC), // Purple
      const Color(0xFFFF7043), // Orange
      const Color(0xFF78909C), // Blue Grey
    ];

    return colors[index % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    // Map specific categories to match target design
    final iconMap = {
      'Electronics': Icons.devices,
      'Travel': Icons.flight,
      'Food': Icons.restaurant,
      'Shopping': Icons.shopping_cart,
      'Car': Icons.directions_car,
      'Transportation': Icons.directions_bus,
      'Phone': Icons.phone_android,
      'Entertainment': Icons.movie,
      'Education': Icons.school,
      'Beauty': Icons.face,
      'Sports': Icons.sports,
      'Social': Icons.people,
      'Clothing': Icons.checkroom,
      'Alcohol': Icons.local_bar,
      'Cigarettes': Icons.smoking_rooms,
      'Health': Icons.health_and_safety,
      'Pets': Icons.pets,
      'Repairs': Icons.build,
      'Housing': Icons.home_repair_service,
      'Home': Icons.home,
      'Gifts': Icons.card_giftcard,
      'Donations': Icons.favorite,
      'Lottery': Icons.casino,
      'Snacks': Icons.fastfood,
      'Kids': Icons.child_care,
      'Vegetables': Icons.eco,
      'Fruits': Icons.apple,
      'SMS': Icons.sms,
      'Salary': Icons.account_balance_wallet,
      'Investments': Icons.trending_up,
      'Part-Time': Icons.schedule,
      'Bonus': Icons.star,
      'Others': Icons.more_horiz,
    };

    return iconMap[category] ?? Icons.category;
  }
}
