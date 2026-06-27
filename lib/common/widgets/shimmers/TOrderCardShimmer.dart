import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/shimmer.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class TOrderCardShimmer extends StatelessWidget {
  const TOrderCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // شيمر الأيقونة
          const TShimmerEffect(width: 48, height: 48, radius: 12),
          const SizedBox(width: TSizes.spaceBtwItems),

          // شيمر بيانات الطلب
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TShimmerEffect(width: 100, height: 16),
                const SizedBox(height: 8),
                const TShimmerEffect(width: 150, height: 12),
              ],
            ),
          ),

          // شيمر السهم الصغير
          const TShimmerEffect(width: 16, height: 16, radius: 4),
        ],
      ),
    );
  }
}
