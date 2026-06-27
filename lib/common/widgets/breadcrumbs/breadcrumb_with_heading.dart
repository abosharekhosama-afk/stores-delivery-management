import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/features/media/screens/widgets/page_heading.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/device/device_utility.dart';

class BreadcrumbWithHeading extends StatelessWidget {
  const BreadcrumbWithHeading({
    super.key,
    required this.heading,
    required this.breadcrumbItems,
    this.resurnToPreviousScreen = false,
  });

  final String heading;

  final List<String> breadcrumbItems;
  final bool resurnToPreviousScreen;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // جعل الخلفية شفافة
        statusBarIconBrightness: Brightness.dark, // للأندرويد: أيقونات سوداء
        statusBarBrightness: Brightness.light, // للـ iOS: أيقونات سوداء
      ),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // للأندرويد
        statusBarBrightness: Brightness.light, // للـ iOS
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (TDeviceUtils.isDesktopScreen(context))
            InkWell(
              onTap: () => Get.offAllNamed(TRoutes.dashboard),
              child: Padding(
                padding: const EdgeInsets.all(TSizes.xs),
                child: Text(
                  "الرئيسية",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.apply(fontWeightDelta: -1),
                ),
              ),
            ),
          if (TDeviceUtils.isDesktopScreen(context))
            for (int i = 0; i < breadcrumbItems.length; i++)
              Row(
                children: [
                  const Text("/"),
                  InkWell(
                    onTap: () => i == breadcrumbItems.length - 1
                        ? null
                        : Get.toNamed(breadcrumbItems[i]),
                    child: Padding(
                      padding: const EdgeInsets.all(TSizes.xs),
                      child: Text(
                        i == breadcrumbItems.length - 1
                            ? breadcrumbItems[i].capitalize.toString()
                            : capitalize(breadcrumbItems[i]).substring(1),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall!.apply(fontWeightDelta: -1),
                      ),
                    ),
                  ),
                ],
              ),
          if (TDeviceUtils.isDesktopScreen(context))
            SizedBox(height: TSizes.sm),

          Row(
            children: [
              if (resurnToPreviousScreen)
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                ),
              if (resurnToPreviousScreen)
                const SizedBox(width: TSizes.spaceBtwItems),
              PageHeading(heading: heading),
            ],
          ),
        ],
      ),
    );
  }

  String capitalize(String name) {
    return name.isEmpty ? "" : name[0].toUpperCase() + name.substring(1);
  }
}
