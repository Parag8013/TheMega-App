// lib/features/accounts/presentation/widgets/icon_selector.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/account_constants.dart';
import '../../../../core/constants/custom_icon_constants.dart';

class IconSelector extends StatelessWidget {
  final String selectedIcon;
  final Function(String) onIconSelected;

  const IconSelector({
    Key? key,
    required this.selectedIcon,
    required this.onIconSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Combine Material icons and custom PNG icons
    final totalIcons =
        AccountConstants.accountIcons.length +
        CustomIconConstants.customIcons.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: totalIcons,
        itemBuilder: (context, index) {
          // First show Material icons, then custom icons
          if (index < AccountConstants.accountIcons.length) {
            // Material Icon
            final iconName = AccountConstants.accountIcons.keys.elementAt(
              index,
            );
            final icon = AccountConstants.accountIcons.values.elementAt(index);
            final isSelected = selectedIcon == iconName;

            return GestureDetector(
              onTap: () => onIconSelected(iconName),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.yellow[700] : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: Colors.yellow[600]!, width: 2)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.black : Colors.white,
                  size: 24,
                ),
              ),
            );
          } else {
            // Custom PNG Icon
            final customIndex = index - AccountConstants.accountIcons.length;
            final iconName = CustomIconConstants.customIcons.keys.elementAt(
              customIndex,
            );
            final assetPath = CustomIconConstants.customIcons.values.elementAt(
              customIndex,
            );
            final isSelected = selectedIcon == iconName;

            return GestureDetector(
              onTap: () => onIconSelected(iconName),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.yellow[700] : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: Colors.yellow[600]!, width: 2)
                      : null,
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  color: isSelected ? Colors.black : null,
                  colorBlendMode: isSelected ? BlendMode.srcIn : null,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
