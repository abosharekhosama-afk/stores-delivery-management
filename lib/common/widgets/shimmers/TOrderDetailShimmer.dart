import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/shimmer.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class TOrderDetailShimmer extends StatelessWidget {
  const TOrderDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // شيمر الهيدر (تذكرة التسليم)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const TShimmerEffect(
                  width: 200,
                  height: 80,
                  radius: 20,
                ), // كود التسليم
                const SizedBox(height: 20),
                const TShimmerEffect(width: 150, height: 15), // التاريخ
                const SizedBox(height: 12),
                const TShimmerEffect(
                  width: 100,
                  height: 25,
                  radius: 100,
                ), // البادج
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    TShimmerEffect(width: 120, height: 20),
                    TShimmerEffect(width: 60, height: 15),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwItems),

                // تكرار شيمر بطاقات المنتجات
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 2,
                  itemBuilder: (_, __) => Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    height: 250, // ارتفاع تقريبي للبطاقة مع الـ Stepper
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const TShimmerEffect(
                              width: 90,
                              height: 90,
                              radius: 20,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                TShimmerEffect(width: 120, height: 15),
                                SizedBox(height: 8),
                                TShimmerEffect(width: 80, height: 12),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        const TShimmerEffect(
                          width: double.infinity,
                          height: 40,
                          radius: 12,
                        ), // Stepper area
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
