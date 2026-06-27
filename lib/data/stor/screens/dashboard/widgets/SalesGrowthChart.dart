import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';

class SalesGrowthChart extends StatelessWidget {
  final double currentMonthSales;
  final double previousMonthSales;

  const SalesGrowthChart({
    super.key,
    required this.currentMonthSales,
    required this.previousMonthSales,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 0), // البداية
                FlSpot(1, previousMonthSales), // الشهر السابق
                FlSpot(2, currentMonthSales), // الشهر الحالي
              ],
              isCurved: true,
              color: TColors.primary,
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: TColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
