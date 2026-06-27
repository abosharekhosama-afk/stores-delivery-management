import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/breadcrumbs/breadcrumb_with_heading.dart';
import 'package:stors_admin_panel/features/personalizatuon/screens/profile/widgets/profile_screen.dart';
import 'package:stors_admin_panel/features/personalizatuon/screens/store_profile_screen.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class ProfileDesktop extends StatelessWidget {
  const ProfileDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BreadcrumbWithHeading(
              heading: "الملف الشخصي",
              breadcrumbItems: ["البروفايل"],
            ),
            SizedBox(height: TSizes.spaceBtwSections),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: StoreProfileScreen()),
                SizedBox(width: TSizes.spaceBtwSections),
                Expanded(child: FormProfileScrren()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
