import 'package:flutter/material.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';

class TProductTitlePrice extends StatelessWidget {
  const TProductTitlePrice({
    super.key,
    required this.product,
    this.selectedVariation,
  });
  final ProductModel product;
  final ProductVariationModel? selectedVariation;

  @override
  Widget build(BuildContext context) {
    double price = selectedVariation != null
        ? selectedVariation!.price
        : product.price;
    double salePrice = selectedVariation != null
        ? selectedVariation!.salePrice
        : product.salePrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // السعر والخصم في الأعلى بشكل بارز
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "\$${salePrice > 0 ? salePrice : price}",
              style: Theme.of(context).textTheme.displaySmall!.copyWith(
                color: TColors.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            if (salePrice > 0) ...[
              const SizedBox(width: 10),
              Text(
                "\$$price",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 10),
              _buildDiscountBadge(price, salePrice),
            ],
          ],
        ),
        const SizedBox(height: 10),
        // اسم المنتج بخط عريض وفخم
        Text(
          product.title,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountBadge(double price, double sale) {
    double pct = ((price - sale) / price) * 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "${pct.toStringAsFixed(0)}% OFF",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
