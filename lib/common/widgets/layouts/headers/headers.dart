import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/shimmer.dart';
import 'package:stors_admin_panel/features/personalizatuon/controllers/store_controller.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/constants/text_strings.dart';
import 'package:stors_admin_panel/utils/device/device_utility.dart';

class Headers extends StatelessWidget implements PreferredSizeWidget {
  const Headers({super.key, this.scaffoldKey});
  final GlobalKey<ScaffoldState>? scaffoldKey;

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
      child: Container(
        decoration: BoxDecoration(
          color: TColors.white,
          border: Border(bottom: BorderSide(color: TColors.grey, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: TSizes.md,
          vertical: TSizes.sm,
        ),
        child: SafeArea(
          bottom: false, // لا نحتاج مساحة آمنة من الأسفل هنا
          child: AppBar(
            leading: !TDeviceUtils.isDesktopScreen(context)
                ? IconButton(
                    onPressed: () => scaffoldKey?.currentState?.openDrawer(),
                    icon: const Icon(Iconsax.menu),
                  )
                : null,
            title: TDeviceUtils.isDesktopScreen(context)
                ? SizedBox(
                    width: 400,
                    child: TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Iconsax.search_normal),
                        hintText: "البحث...",
                      ),
                    ),
                  )
                : null,
            actions: [
              /*if (!TDeviceUtils.isDesktopScreen(context))
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Iconsax.search_normal),
                ),*/
              IconButton(
                onPressed: () => Get.toNamed(TRoutes.notifications),
                icon: const Icon(Iconsax.notification),
              ),
              const SizedBox(width: TSizes.spaceBtwItems / 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(() {
                    final controller = StoreController.instance;
                    final profileImage = controller.store.value.profilePicture;

                    // إذا كانت البيانات قيد التحميل، اعرض الشيمر
                    if (controller.profileLoading.value) {
                      return const TShimmerEffect(
                        width: 40,
                        height: 40,
                        radius: 40,
                      );
                    }

                    return InkWell(
                      onTap: () => Get.toNamed(TRoutes.storeProfileScreen),
                      child: TRoundedImage(
                        // إذا كان الرابط موجود نستخدم network، وإلا نستخدم الصورة الافتراضية (user)
                        imageType: profileImage.isNotEmpty
                            ? ImageType.network
                            : ImageType.asset,
                        image: profileImage.isNotEmpty
                            ? profileImage
                            : TImages.user,
                        fit: BoxFit.cover,
                        padding: 0,
                        width: 40,
                        height: 40,
                        applyImageRadius: true,
                        borderRadius: 40, // لجعلها دائرية تماماً
                        // إضافة Shimmer أثناء تحميل صورة الشبكة نفسها (اختياري حسب تصميم TRoundedImage)
                      ),
                    );
                  }),
                  const SizedBox(width: TSizes.sm),

                  if (!TDeviceUtils.isMobileScreen(context))
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "اسامة احمد ابو شرخ",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          TTexts.adminEmail,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize =>
      Size.fromHeight(TDeviceUtils.getAppBarHeight() + 15);
}
