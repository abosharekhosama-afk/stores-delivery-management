import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OrdersDistributionChart extends StatelessWidget {
  final int total, accepted, rejected, completed;

  const OrdersDistributionChart({
    super.key,
    required this.total,
    required this.accepted,
    required this.rejected,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: [
            _section(completed.toDouble(), "تمت", Colors.green),
            _section(accepted.toDouble(), "مقبولة", Colors.blue),
            _section(rejected.toDouble(), "مرفوضة", Colors.red),
            _section(
              (total - (completed + accepted + rejected)).toDouble(),
              "انتظار",
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _section(double value, String title, Color color) {
    return PieChartSectionData(
      color: color,
      value: value,
      title: value > 0 ? '$title\n$value' : '',
      radius: 50,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
