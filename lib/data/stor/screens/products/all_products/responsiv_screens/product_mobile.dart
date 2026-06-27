import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/anim/TDelayedSlideIn.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/TProductCardShimmer.dart';
import 'package:stors_admin_panel/data/stor/controller/product/all_products_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/products/all_products/widgets/TableHeader.dart';
import 'package:stors_admin_panel/data/stor/screens/products/all_products/widgets/product_card_mobile.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class ProductMobile extends StatelessWidget {
  const ProductMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AllProductsController>();

    return GestureDetector(
      onTap: () {
        // عند لمس أي مكان خارج الحقل يتم إغلاق الكيبورد وتقليص الحقل
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* const BreadcrumbWithHeading(
                heading: "المنتجات",
                breadcrumbItems: ["المنتجات"],
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
*/
              // الهيدر يحتوي على البحث وزر الإضافة
              Obx(
                () => Tableheader(
                  buttonText: "منتج جديد",
                  onPressed: () {
                    Get.find<ProductAdditionController>()
                        .clearAllControllersData();
                    Get.toNamed(TRoutes.createProduct);
                  },
                  searchController: controller.searchTextController,
                  focusNode: controller.searchFocusNode,
                  showClear: controller.showClearButton.value,
                  onSearchSubmit: () => controller.triggerSearch(),
                  onClearPressed: () => controller.clearSearch(),
                  //searchOnChanged: (val) => controller.searchOnChanged(val), // اختياري للفلترة التفاعلية
                ),
              ),
              /*Obx(
                () => Tableheader(
                  buttonText: "إضافة منتج جديد",
                  onPressed: () => Get.toNamed(TRoutes.createProduct),
                  searchController: controller.searchTextController,
                  focusNode: controller.searchFocusNode,
                  isExpanded: controller.isSearchExpanded.value,
                  showClear: controller.showClearButton.value,
                  onSearchSubmit: () => controller.triggerSearch(),
                  onClearPressed: () => controller.clearSearch(),
                ),
              ),*/

              /* Tableheader(
                buttonText: "اضف منتج",
                onPressed: () => Get.toNamed(TRoutes.createProduct),
                searchController: controller.searchTextController,
                searchOnChanged: (query) => controller.searchOnChanged(query),
              ),*/
              const SizedBox(height: TSizes.spaceBtwItems),

              // عرض المنتجات
              Expanded(
                child: Obx(() {
                  // حالة التحميل الأولية (إذا كانت القائمة فارغة والتحميل شغال)
                  if (controller.isLoading.value &&
                      controller.filteredProducts.isEmpty) {
                    return ListView.separated(
                      itemCount: 6,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: TSizes.spaceBtwItems),
                      itemBuilder: (_, __) => const TProductCardShimmer(),
                    );
                  }

                  // حالة عدم وجود بيانات
                  if (controller.filteredProducts.isEmpty) {
                    return const Center(child: Text("لا توجد منتجات"));
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.refreshProducts(),
                    child: ListView.separated(
                      controller: controller.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      // itemCount يعتمد على القائمة المفلترة + مؤشر التحميل السفلي
                      itemCount:
                          controller.filteredProducts.length +
                          (controller.isMoreLoading.value ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
                      itemBuilder: (_, index) {
                        // مؤشر التحميل السفلي عند الـ Pagination
                        if (index == controller.filteredProducts.length) {
                          return const Padding(
                            padding: EdgeInsets.only(
                              bottom: TSizes.defaultSpace,
                            ),
                            child: TProductCardShimmer(),
                          );
                        }

                        final product = controller.filteredProducts[index];

                        return TDelayedSlideIn(
                          // استخدام مودولو 20 يجعل الأنيميشن سريعاً وسلساً حتى في القوائم الطويلة
                          delayInMilliseconds: (index % 20) * 50,
                          direction: SlideDirection.bottomToTop,
                          isScrollingDown: controller.isScrollingDown.value,
                          child: TProductCardMobile(product: product),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
