import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/common/widgets/texts/section_heading.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class TSelectedVariationCard extends StatelessWidget {
  const TSelectedVariationCard({super.key, required this.variation});

  final ProductVariationModel? variation;

  @override
  Widget build(BuildContext context) {
    if (variation == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: TColors.cardBackgroundColor,
        //color: Colors.grey.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withAlpha((0.2 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TSectionHeading(title: "تفاصيل المتغير"),
              const Spacer(),
              Text(
                "المخزون: ${variation!.stock}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          Row(
            children: [
              // صورة الفاريشن إذا وجدت
              if (variation!.image.isNotEmpty)
                TRoundedImage(
                  image: variation!.image,
                  imageType: ImageType.network,
                  width: 50,
                  height: 50,
                ),
              const SizedBox(width: TSizes.md),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("السعر: \$${variation!.price}"),
                  if (variation!.sku.isNotEmpty) Text("SKU: ${variation!.sku}"),
                ],
              ),
            ],
          ),

          if (variation!.description != null &&
              variation!.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                variation!.description!,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
