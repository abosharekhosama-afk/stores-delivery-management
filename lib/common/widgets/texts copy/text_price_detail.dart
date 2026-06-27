import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/texts%20copy/text_price.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class TTextPriceDetail extends StatelessWidget {
  const TTextPriceDetail({
    super.key,
    required this.labele,
    required this.oldPrice,
    required this.newPrice,
  });

  final String labele, oldPrice, newPrice;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text("$labele: ", style: Theme.of(context).textTheme.labelLarge),

        Text(
          oldPrice,
          style: Theme.of(
            context,
          ).textTheme.titleSmall!.apply(decoration: TextDecoration.lineThrough),
        ),
        const SizedBox(width: TSizes.spaceBtwItems / 2),
        TTextPrice(price: newPrice),
      ],
    );
  }
}
