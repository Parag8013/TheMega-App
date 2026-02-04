// lib/features/shared/widgets/calendar_dialog.dart
import 'package:flutter/material.dart';

class CalendarDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final Function(int year, int month) onConfirm;

  const CalendarDialog({
    Key? key,
    required this.initialYear,
    required this.initialMonth,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  late int selectedYear;
  late int selectedMonth;

  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialYear;
    selectedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    // Adjust dialog size and spacing for desktop
    final dialogMaxWidth = isDesktop ? 400.0 : double.infinity;
    final monthGridSpacing = isDesktop ? 8.0 : 12.0;
    final monthGridCrossAxisCount = isDesktop ? 4 : 3;
    final monthGridChildAspectRatio = isDesktop ? 2.0 : 2.5;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: dialogMaxWidth,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                'Select Month & Year',
                style: TextStyle(
                  color: Colors.yellow[700],
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // Year selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => setState(() => selectedYear--),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  Text(
                    selectedYear.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => selectedYear++),
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Month grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: monthGridCrossAxisCount,
                  mainAxisSpacing: monthGridSpacing,
                  crossAxisSpacing: monthGridSpacing,
                  childAspectRatio: monthGridChildAspectRatio,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final isSelected = index == selectedMonth;
                  return GestureDetector(
                    onTap: () => setState(() => selectedMonth = index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.yellow[700]
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.yellow[600]!, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          months[index],
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: BorderSide(color: Colors.grey[600]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          widget.onConfirm(selectedYear, selectedMonth),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
