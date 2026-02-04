// lib/features/transactions/presentation/widgets/category_grid.dart
import 'package:flutter/material.dart';
import '../../../../core/models/category_model.dart';

class CategoryGrid extends StatefulWidget {
  final List<CategoryModel> categories;
  final String transactionType;
  final Function(CategoryModel) onCategorySelected;

  const CategoryGrid({
    Key? key,
    required this.categories,
    required this.transactionType,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  String? _selectedCategoryLabel;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 6 : (screenWidth > 800 ? 5 : 4);
    final spacing = screenWidth > 1200
        ? 24.0
        : (screenWidth > 800 ? 20.0 : 16.0);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: 0.85,
        ),
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isSelected = _selectedCategoryLabel == category.label;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryLabel = category.label;
              });
              widget.onCategorySelected(category);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.yellow[700] : Colors.grey[800],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: isSelected ? Colors.black : Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 8),

                // Text with proper constraints
                Flexible(
                  child: Text(
                    category.label,
                    style: TextStyle(
                      color: isSelected ? Colors.yellow[700] : Colors.white,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
