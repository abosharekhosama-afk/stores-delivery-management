import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/shimmer.dart';

class TMerchantActionShimmer extends StatelessWidget {
  const TMerchantActionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // شيمر صورة المنتج
              const TShimmerEffect(width: 90, height: 90, radius: 15),
              const SizedBox(width: 12),
              // شيمر النصوص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    TShimmerEffect(width: 120, height: 12),
                    SizedBox(height: 8),
                    TShimmerEffect(width: 180, height: 16),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TShimmerEffect(width: 50, height: 14),
                        TShimmerEffect(width: 70, height: 20, radius: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // شيمر الأزرار
          Row(
            children: const [
              Expanded(
                child: TShimmerEffect(
                  width: double.infinity,
                  height: 40,
                  radius: 12,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TShimmerEffect(
                  width: double.infinity,
                  height: 40,
                  radius: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
