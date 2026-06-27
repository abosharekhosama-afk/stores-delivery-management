import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/shimmer.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class TDashboardCardsShimmer extends StatelessWidget {
  const TDashboardCardsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TShimmerEffect(
                width: double.infinity,
                height: 150,
                radius: 20,
              ),
            ),
            SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: TShimmerEffect(
                width: double.infinity,
                height: 150,
                radius: 20,
              ),
            ),
          ],
        ),
        SizedBox(height: TSizes.spaceBtwItems),
        Row(
          children: [
            Expanded(
              child: TShimmerEffect(
                width: double.infinity,
                height: 150,
                radius: 20,
              ),
            ),
            SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: TShimmerEffect(
                width: double.infinity,
                height: 150,
                radius: 20,
              ),
            ),
          ],
        ),
        SizedBox(height: TSizes.spaceBtwItems),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TShimmerEffect(width: 40, height: 15, radius: 20),
                          TShimmerEffect(width: 20, height: 15, radius: 20),
                        ],
                      ),
                      SizedBox(height: TSizes.spaceBtwItems),
                      TShimmerEffect(
                        width: double.infinity,
                        height: 8,
                        radius: 20,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TShimmerEffect(width: 40, height: 15, radius: 20),
                          TShimmerEffect(width: 20, height: 15, radius: 20),
                        ],
                      ),
                      SizedBox(height: TSizes.spaceBtwItems),
                      TShimmerEffect(
                        width: double.infinity,
                        height: 15,
                        radius: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: TSizes.spaceBtwItems),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TShimmerEffect(width: 40, height: 15, radius: 20),
                    TShimmerEffect(width: 20, height: 15, radius: 20),
                  ],
                ),
                SizedBox(height: TSizes.spaceBtwItems),
                TShimmerEffect(width: double.infinity, height: 15, radius: 20),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
