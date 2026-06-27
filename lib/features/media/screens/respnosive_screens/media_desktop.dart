import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/breadcrumbs/breadcrumb_with_heading.dart';
import 'package:stors_admin_panel/features/media/controller/media_controller.dart';
import 'package:stors_admin_panel/features/media/screens/widgets/media_uploader.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class MediaDesktop extends StatelessWidget {
  const MediaDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MediaController());
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BreadcrumbWithHeading(
                    heading: "الوسائط",
                    breadcrumbItems: [],
                    resurnToPreviousScreen: true,
                  ),

                  SizedBox(
                    width: TSizes.buttonWidth * 1.5,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          controller.showImageUploaderSection.value =
                              !controller.showImageUploaderSection.value,
                      label: Text("رفع صور"),
                      icon: const Icon(Iconsax.cloud_add),
                    ),
                  ),
                ],
              ),
              SizedBox(height: TSizes.spaceBtwSections),

              const MediaUploader(),
            ],
          ),
        ),
      ),
    );
  }
}
