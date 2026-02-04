// lib/features/charts/presentation/widgets/line_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/charts_provider.dart';

class LineChartWidget extends StatelessWidget {
  final ChartsProvider provider;

  const LineChartWidget({
    Key? key,
    required this.provider,
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

    if (provider.dailyTotals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Compact stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', provider.total),
              _buildStatItem('Average', provider.average),
              _buildStatItem('Days', provider.dailyTotals.length.toDouble()),
            ],
          ),

          const SizedBox(height: 16),

          // Compact chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getGridInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: _buildTitlesData(),
                borderData: FlBorderData(show: false),
                lineBarsData: [_buildLineBarData()],
                minX: 0,
                maxX: _getMaxX(),
                minY: 0,
                maxY: _getMaxY(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label == 'Days'
              ? value.toInt().toString()
              : '₹${_formatCompact(value)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value >= 100000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  LineChartBarData _buildLineBarData() {
    final sortedEntries = provider.dailyTotals.entries.toList()
      ..sort((a, b) => DateTime.parse(a.key).compareTo(DateTime.parse(b.key)));

    final spots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.yellow[700],
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: Colors.yellow[700]!,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.yellow[700]!.withOpacity(0.1),
      ),
    );
  }

  FlTitlesData _buildTitlesData() {
    final sortedEntries = provider.dailyTotals.entries.toList()
      ..sort((a, b) => DateTime.parse(a.key).compareTo(DateTime.parse(b.key)));

    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: _getGridInterval(),
          getTitlesWidget: (value, meta) {
            return Text(
              _formatCompact(value),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 9,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 25,
          interval: _getBottomInterval(),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < sortedEntries.length) {
              final date = DateTime.parse(sortedEntries[index].key);
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  DateFormat('dd').format(date),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                  ),
                ),
              );
            }
            return const Text('');
          },
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _getMaxX() {
    return (provider.dailyTotals.length - 1).toDouble();
  }

  double _getMaxY() {
    final maxValue = provider.dailyTotals.values.isNotEmpty
        ? provider.dailyTotals.values.reduce((a, b) => a > b ? a : b)
        : 0.0;
    return maxValue * 1.2;
  }

  double _getGridInterval() {
    final maxY = _getMaxY();
    return maxY / 4;
  }

  double _getBottomInterval() {
    final count = provider.dailyTotals.length;
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 31) return 5;
    return 10;
  }
}