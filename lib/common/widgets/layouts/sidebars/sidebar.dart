import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/images/t_circular_image.dart';
import 'package:stors_admin_panel/common/widgets/layouts/sidebars/menu/menu_item.dart';
import 'package:stors_admin_panel/common/widgets/layouts/sidebars/sidebar_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/MerchantPendingActions/merchant_pending_actions_screen.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/dashboard.dart';
import 'package:stors_admin_panel/data/stor/screens/orders/Orders/order_tap.dart';
import 'package:stors_admin_panel/data/stor/screens/products/all_products/product.dart';
import 'package:stors_admin_panel/data/stor/screens/wallet/wallet_screen.dart';
import 'package:stors_admin_panel/features/personalizatuon/screens/profile/profile.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SidebarController());

    return Drawer(
      shape: BeveledRectangleBorder(),
      child: Container(
        decoration: BoxDecoration(
          color: TColors.white,
          border: Border(right: BorderSide(color: TColors.grey, width: 1)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TCircularImage(
                width: 100,
                height: 100,
                image: TImages.darkAppLogo,
                backgroundColor: Colors.transparent,
              ),

              SizedBox(height: TSizes.spaceBtwSections),
              Padding(
                padding: const EdgeInsets.all(TSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "MENU",
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall!.apply(letterSpacingDelta: 1.2),
                    ),

                    TMenuItem(
                      routs: TRoutes.dashboard,
                      screen: Dashboard(),
                      icon: Iconsax.status,
                      itemName: "الرئيسية",
                    ),
                    TMenuItem(
                      routs: TRoutes.wallet,
                      screen: WalletScreen(),
                      icon: Iconsax.image,
                      itemName: "المحفظة",
                    ),
                    TMenuItem(
                      routs: TRoutes.products,
                      screen: AllProduct(),
                      icon: Iconsax.status,
                      itemName: "المنتجات",
                    ),
                    TMenuItem(
                      routs: TRoutes.ordersTap,
                      screen: OrderTap(),
                      icon: Iconsax.status5,
                      itemName: " الطلبات",
                    ),
                    TMenuItem(
                      routs: TRoutes.merchantPendingActions,
                      screen: MerchantPendingActionsScreen(),
                      icon: Iconsax.status5,
                      itemName: "المنتجات المعلقة",
                    ),
                    TMenuItem(
                      routs: TRoutes.profile,
                      screen: Profile(),
                      icon: Iconsax.status,
                      itemName: "الملف الشخصي",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
