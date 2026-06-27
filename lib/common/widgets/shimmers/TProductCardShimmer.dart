import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/shimmer.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class TProductCardShimmer extends StatelessWidget {
  const TProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      ),
      child: Row(
        children: [
          // شيمر الصورة
          const TShimmerEffect(
            width: 90,
            height: 90,
            radius: TSizes.borderRadiusMd,
          ),
          const SizedBox(width: TSizes.spaceBtwItems),

          // شيمر النصوص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TShimmerEffect(width: 150, height: 15),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                const TShimmerEffect(width: 80, height: 12),
                const SizedBox(height: TSizes.spaceBtwItems),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [TShimmerEffect(width: 60, height: 20)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
