import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class ProductVisibiltyWidget extends StatelessWidget {
  const ProductVisibiltyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => TRoundedContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("الرؤية", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: TSizes.spaceBtwItems),
            Row(
              children: [
                _buildVisibiltyRadioButton(ProductVisibility.published, "مرئي"),
                _buildVisibiltyRadioButton(ProductVisibility.hidden, "مخفي"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibiltyRadioButton(ProductVisibility value, String label) {
    final controller = ProductAdditionController.instance;
    return RadioMenuButton<ProductVisibility>(
      value: value,
      groupValue: controller.productVisibility.value,
      onChanged: (value) {
        if (value != null) {
          controller.productVisibility.value = value;
        }
      },
      child: Text(label),
    );
  }
}
