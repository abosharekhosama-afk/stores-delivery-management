import 'package:flutter/material.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/constants/text_strings.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';

class sectionHeading extends StatelessWidget {
  const sectionHeading({
    super.key,
    required this.labelText,
    required this.showButtton,
    this.labelButton = TTexts.viewAll,
    this.onPressed,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
  });

  final String labelText;
  final bool showButtton;
  final Color? textColor;
  final String labelButton;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool dark = THelperFunctions.isDarkMode(context);
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            labelText,
            style: Theme.of(context).textTheme.headlineSmall!.apply(
              color: textColor ?? (dark ? TColors.white : TColors.dark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (showButtton)
            TextButton(
              onPressed: onPressed,
              child: Text(
                labelButton,
                style: Theme.of(context).textTheme.bodyMedium!.apply(
                  color:
                      textColor ?? (dark ? TColors.grey : TColors.darkerGrey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
