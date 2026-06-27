import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/shimmer.dart';

class TransactionShimmer extends StatelessWidget {
  const TransactionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 1. محاكاة الـ CircleAvatar (الأيقونة)
          const TShimmerEffect(width: 40, height: 40, radius: 40),
          const SizedBox(width: 16),

          // 2. محاكاة الـ Title والـ Subtitle بداخل الـ ListTile
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // محاكاة حقل العنوان (Title)
                const TShimmerEffect(width: 120, height: 14, radius: 4),
                const SizedBox(height: 8),
                // محاكاة حقل التاريخ (Subtitle)
                const TShimmerEffect(width: 80, height: 11, radius: 4),
              ],
            ),
          ),

          // 3. محاكاة الـ Trailing (المبلغ وحالة العملية الإكسسوارية باليمين)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // محاكاة قيمة المبلغ (Amount)
              const TShimmerEffect(width: 70, height: 15, radius: 4),
              const SizedBox(height: 8),
              // محاكاة نص الحالة (Status)
              const TShimmerEffect(width: 40, height: 11, radius: 4),
            ],
          ),
        ],
      ),
    );
  }
}
