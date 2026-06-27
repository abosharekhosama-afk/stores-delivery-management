import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/common/widgets/texts/section_heading.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class Tdashboardcard extends StatelessWidget {
  const Tdashboardcard({
    super.key,
    required this.title,
    required this.subTitle,
    this.icon = Iconsax.arrow_up3,
    this.color = TColors.success,
    required this.stats,
    this.onTap,
  });
  final String title, subTitle;
  final IconData icon;
  final Color color;
  final int stats;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return TRoundedContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(TSizes.lg),
      child: Column(
        children: [
          TSectionHeading(title: title, textColor: TColors.textSecondary),
          const SizedBox(height: TSizes.spaceBtwSections),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subTitle, style: Theme.of(context).textTheme.headlineMedium),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: TSizes.iconSm),
                        /*Text(
                          "$stats%",
                          style: Theme.of(context).textTheme.titleLarge!.apply(
                            color: color,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),*/
                      ],
                    ),
                  ),
                  /*SizedBox(
                    width: 135,
                    child: Text(
                      TTexts.confirmEmailSubTitle,
                      style: Theme.of(context).textTheme.labelMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),*/
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
