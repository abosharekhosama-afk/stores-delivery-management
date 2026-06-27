import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/texts%20copy/TProductsTitleText.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class TTextProductDetail extends StatelessWidget {
  const TTextProductDetail({
    super.key,
    required this.title,
    required this.subTitle,
  });
  final String title, subTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TproductText(title: title, smallSize: true),
        const SizedBox(width: TSizes.spaceBtwItems),
        Text(subTitle),
      ],
    );
  }
}
