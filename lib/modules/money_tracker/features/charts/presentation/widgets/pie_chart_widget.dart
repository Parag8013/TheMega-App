// lib/features/charts/presentation/widgets/pie_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/charts_provider.dart';

class PieChartWidget extends StatelessWidget {
  final ChartsProvider provider;
  final bool groupByDate;

  const PieChartWidget({
    Key? key,
    required this.provider,
    this.groupByDate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.yellow),
      );
    }

    if (provider.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'Something went wrong',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final data = groupByDate ? _getDailyData() : _getCategoryData();

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${provider.selectedType} data available',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'for this ${provider.selectedPeriod}',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // PROPER PADDING
      child: Row(
        children: [
          // LEFT: Compact Pie Chart (exactly like target image)
          Expanded(
            flex: 4, // Reduced from 5 to make chart smaller
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 160, // FIXED: Maximum width to match target
                maxHeight: 160,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    // Pie Chart with smaller radius
                    PieChart(
                      PieChartData(
                        sections: _buildPieSections(data),
                        centerSpaceRadius: 45, // Reduced from 60
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(enabled: false),
                      ),
                    ),
                    // Center text
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTotal(provider.total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16, // Slightly smaller
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 24), // Proper spacing

          // RIGHT: Legend (more space than chart)
          Expanded(
            flex: 5, // More space for legend
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.take(4).map((entry) {
                final percentage = (entry.value / provider.total * 100);
                final color = _getColorForCategory(entry.key, data.indexOf(entry));

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Color dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Category name
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Percentage
                      Text(
                        '${percentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTotal(double total) {
    if (total >= 100000) {
      return '${(total / 1000).toStringAsFixed(0)}K';
    } else if (total >= 1000) {
      return '${(total / 1000).toStringAsFixed(1)}K';
    } else {
      return total.toStringAsFixed(0);
    }
  }

  List<MapEntry<String, double>> _getCategoryData() {
    return provider.getTopCategories(limit: 6);
  }

  List<MapEntry<String, double>> _getDailyData() {
    final grouped = <String, double>{};

    provider.dailyTotals.forEach((dateStr, amount) {
      final date = DateTime.parse(dateStr);
      String key;

      if (provider.selectedPeriod == 'month') {
        key = 'Week ${((date.day - 1) ~/ 7) + 1}';
      } else {
        key = DateFormat('MMM').format(date);
      }

      grouped[key] = (grouped[key] ?? 0) + amount;
    });

    return grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
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

  List<PieChartSectionData> _buildPieSections(List<MapEntry<String, double>> data) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final dataEntry = entry.value;
      final percentage = dataEntry.value / provider.total * 100;
      final color = _getColorForCategory(dataEntry.key, index);

      return PieChartSectionData(
        value: dataEntry.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        color: color,
        radius: 40, // Reduced radius to match target
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.7,
      );
    }).toList();
  }
}