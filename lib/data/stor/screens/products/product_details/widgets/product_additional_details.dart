// ويدجيت إضافية لعرض تفاصيل المنتج التقنية
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';

class TProductAdditionalDetails extends StatelessWidget {
  final ProductModel product;
  const TProductAdditionalDetails({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildGridItem(
                context,
                Iconsax.category,
                "التصنيف",
                "ID: ${product.categoryId}",
              ),
              _buildGridItem(
                context,
                Iconsax.calendar,
                "التاريخ",

                product.date != null
                    ? DateFormat('hh:mm a | yyyy-MM-dd').format(product.date!)
                    : "غير معرف",
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          Row(
            children: [
              _buildGridItem(
                context,
                Iconsax.barcode,
                "SKU",
                product.sku ?? "N/A",
              ),
              _buildGridItem(
                context,
                Iconsax.star,
                "المميز",
                product.isFeatured! ? "نعم" : "لا",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 20, color: TColors.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
