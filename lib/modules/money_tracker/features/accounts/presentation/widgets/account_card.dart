// lib/features/accounts/presentation/widgets/account_card.dart
import 'package:flutter/material.dart';
import '../../../../core/models/account_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/constants/account_constants.dart';
import '../../../../core/constants/custom_icon_constants.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;

  const AccountCard({Key? key, required this.account, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final balanceChange = account.currentBalance - account.initialBalance;
    final hasPositiveChange = balanceChange >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Row(
              children: [
                // Account icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.yellow[700]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildIcon(),
                ),

                const SizedBox(width: 16),

                // Account details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.accountType,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      if (account.note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          account.note,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Balance and change
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(account.currentBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (balanceChange != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: hasPositiveChange
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${hasPositiveChange ? '+' : ''}${CurrencyFormatter.formatCompact(balanceChange)}',
                          style: TextStyle(
                            color: hasPositiveChange
                                ? Colors.green
                                : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    // Check if it's a custom PNG icon
    if (CustomIconConstants.isCustomIcon(account.iconName)) {
      final assetPath = CustomIconConstants.getAssetPath(account.iconName);
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          assetPath!,
          fit: BoxFit.contain,
          color: Colors.yellow[700],
          colorBlendMode: BlendMode.srcIn,
        ),
      );
    }

    // Otherwise use Material icon
    final iconData = AccountConstants.getIconData(account.iconName);
    return Icon(iconData, color: Colors.yellow[700], size: 24);
  }
}
