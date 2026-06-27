import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/layouts/sidebars/sidebar_controller.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class TMenuItem extends StatelessWidget {
  const TMenuItem({
    super.key,
    required this.routs,
    required this.itemName,
    required this.screen,
    required this.icon,
  });

  final String routs;
  final Widget screen;
  final String itemName;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SidebarController>();
    return InkWell(
      onTap: () => controller.menuOnTap(routs, screen),
      onHover: (value) {
        if (value && !controller.isHovering(routs)) {
          controller.changeHoverItem(routs);
        } else if (!value && controller.isHovering(routs)) {
          controller.changeHoverItem("");
        }
      },
      child: Obx(
        () => Padding(
          padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
          child: Container(
            decoration: BoxDecoration(
              color: controller.isHovering(routs) || controller.isActive(routs)
                  ? TColors.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: TSizes.lg,
                    bottom: TSizes.md,
                    right: TSizes.md,
                    top: TSizes.md,
                  ),
                  child: controller.isActive(routs)
                      ? Icon(icon, size: 22, color: TColors.white)
                      : Icon(
                          icon,
                          size: 22,
                          color: controller.isHovering(routs)
                              ? TColors.white
                              : TColors.darkGrey,
                        ),
                ),
                if (controller.isHovering(routs) || controller.isActive(routs))
                  Flexible(
                    child: Text(
                      itemName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.apply(color: TColors.white),
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      itemName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.apply(color: TColors.darkGrey),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
