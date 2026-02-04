import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/models/category_model.dart';

class AddCategoryScreen extends StatefulWidget {
  final String initialType;

  const AddCategoryScreen({Key? key, required this.initialType})
    : super(key: key);

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _type = 'expense';
  IconData _selectedIcon = Icons.shopping_cart;
  Color _selectedColor = Colors.amber;

  final List<Color> _colors = [
    Colors.amber,
    Colors.teal,
    Colors.pink,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.brown,
    Colors.deepOrange,
    Colors.cyan,
    Colors.deepPurple,
    Colors.lime,
    Colors.indigo,
    Colors.yellow,
  ];

  final List<IconData> _entertainmentIcons = [
    Icons.videogame_asset,
    Icons.sports_esports,
    Icons.theater_comedy,
    Icons.sports_soccer,
    Icons.music_note,
    Icons.movie,
    Icons.tv,
    Icons.sports_basketball,
    Icons.casino,
    Icons.sports_baseball,
    Icons.pool,
    Icons.toys,
    Icons.celebration,
    Icons.park,
    Icons.sports_tennis,
  ];

  final List<IconData> _foodIcons = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.fastfood,
    Icons.lunch_dining,
    Icons.dinner_dining,
    Icons.breakfast_dining,
    Icons.local_pizza,
    Icons.icecream,
    Icons.cake,
    Icons.local_bar,
    Icons.ramen_dining,
  ];

  final List<IconData> _transportIcons = [
    Icons.directions_car,
    Icons.directions_bus,
    Icons.train,
    Icons.flight,
    Icons.directions_bike,
    Icons.local_taxi,
    Icons.local_shipping,
    Icons.motorcycle,
  ];

  final List<IconData> _shoppingIcons = [
    Icons.shopping_cart,
    Icons.shopping_bag,
    Icons.store,
    Icons.local_grocery_store,
    Icons.checkroom,
    Icons.watch,
  ];

  final List<IconData> _healthIcons = [
    Icons.medical_services,
    Icons.health_and_safety,
    Icons.local_hospital,
    Icons.medication,
    Icons.fitness_center,
  ];

  final List<IconData> _otherIcons = [
    Icons.home,
    Icons.pets,
    Icons.school,
    Icons.work,
    Icons.account_balance,
    Icons.card_giftcard,
    Icons.phone_android,
    Icons.computer,
    Icons.lightbulb,
    Icons.local_gas_station,
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add category',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveCategory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTypeSelector('Expense', 'expense'),
                const SizedBox(width: 20),
                _buildTypeSelector('Income', 'income'),
              ],
            ),
            const SizedBox(height: 30),

            // Icon preview
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _selectedColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(_selectedIcon, color: _selectedColor, size: 48),
              ),
            ),
            const SizedBox(height: 30),

            // Name input
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Please enter the category name',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 30),

            // Color selector
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // Icon sections
            _buildIconSection('Entertainment', _entertainmentIcons),
            _buildIconSection('Food', _foodIcons),
            _buildIconSection('Transport', _transportIcons),
            _buildIconSection('Shopping', _shoppingIcons),
            _buildIconSection('Health', _healthIcons),
            _buildIconSection('Other', _otherIcons),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(String label, String value) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow[700] : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.yellow[700]! : Colors.grey[700]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey[700]!,
                  width: 2,
                ),
                color: isSelected ? Colors.black : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSection(String title, List<IconData> icons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: icons.map((icon) {
            final isSelected = icon == _selectedIcon;
            return GestureDetector(
              onTap: () => setState(() => _selectedIcon = icon),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _selectedColor.withOpacity(0.3)
                      : Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: _selectedColor, width: 2)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? _selectedColor : Colors.grey[600],
                  size: 28,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _saveCategory() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    final category = CategoryModel(
      label: _nameController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
    );

    if (_type == 'expense') {
      context.read<CategoryProvider>().addExpenseCategory(category);
    } else {
      context.read<CategoryProvider>().addIncomeCategory(category);
    }

    Navigator.pop(context);
  }
}
