import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/anim/TDelayedSlideIn.dart';
import 'package:stors_admin_panel/common/widgets/breadcrumbs/breadcrumb_with_heading.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/TProductCardShimmer.dart';
import 'package:stors_admin_panel/data/stor/controller/product/all_products_controller.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/data/stor/screens/products/all_products/widgets/TableHeader.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/device/device_utility.dart';

class ProductTablit extends StatelessWidget {
  const ProductTablit({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AllProductsController>();

    return Scaffold(
      body: SingleChildScrollView(
        controller: controller.scrollController, // للتحكم في الـ Pagination
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. العنوان والمسار
              const BreadcrumbWithHeading(
                heading: "إدارة المنتجات",
                breadcrumbItems: ["المنتجات", "قائمة المنتجات"],
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              // 2. الهيدر (البحث + زر الإضافة) - متجاوب بالفعل كما أرسلت كوده
              Obx(
                () => Tableheader(
                  buttonText: "منتج جديد",
                  onPressed: () => Get.toNamed(TRoutes.createProduct),
                  searchController: controller.searchTextController,
                  focusNode: controller.searchFocusNode,
                  showClear: controller.showClearButton.value,
                  onSearchSubmit: () => controller.triggerSearch(),
                  onClearPressed: () => controller.clearSearch(),
                  //searchOnChanged: (val) => controller.searchOnChanged(val),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              // 3. شبكة المنتجات
              Obx(() {
                // حالة التحميل الأولية
                if (controller.isLoading.value &&
                    controller.filteredProducts.isEmpty) {
                  return GridView.builder(
                    shrinkWrap: true,
                    itemCount: 8,
                    gridDelegate: _buildGridDelegate(context),
                    itemBuilder: (_, __) => const TProductCardShimmer(),
                  );
                }

                // حالة القائمة فارغة
                if (controller.filteredProducts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 100),
                      child: Text("لم يتم العثور على أي منتجات."),
                    ),
                  );
                }

                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // لأننا نستخدم SingleChildScrollView
                      itemCount: controller.filteredProducts.length,
                      gridDelegate: _buildGridDelegate(context),
                      itemBuilder: (context, index) {
                        final product = controller.filteredProducts[index];
                        return TDelayedSlideIn(
                          delayInMilliseconds: (index % 10) * 50,
                          child: _TProductCardDesktop(product: product),
                        );
                      },
                    ),

                    // مؤشر تحميل المزيد في الأسفل (Pagination)
                    if (controller.isMoreLoading.value)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: TSizes.spaceBtwSections,
                        ),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لبناء تخطيط الشبكة بناءً على حجم الشاشة
  SliverGridDelegateWithFixedCrossAxisCount _buildGridDelegate(
    BuildContext context,
  ) {
    bool isDesktop = TDeviceUtils.isDesktopScreen(context);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: isDesktop ? 4 : 2, // 4 للدسكتوب و 2 للتابلت
      mainAxisExtent: 320, // ارتفاع البطاقة
      mainAxisSpacing: TSizes.spaceBtwItems,
      crossAxisSpacing: TSizes.spaceBtwItems,
    );
  }
}

// --- ويدجت البطاقة الخاصة بالديسكتوب ---
class _TProductCardDesktop extends StatelessWidget {
  const _TProductCardDesktop({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = product.stock == 0;
    final controller = Get.find<AllProductsController>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(color: TColors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الجزء العلوي: الصورة والتاجات
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                TRoundedImage(
                  image: product.thumbnail,
                  imageType: ImageType.network,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  applyImageRadius: true,
                  borderRadius: TSizes.borderRadiusLg,
                ),

                // حالة المخزون
                if (isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(
                          TSizes.borderRadiusLg,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "نفذت الكمية",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                // أزرار سريعة (تعديل/حذف) تظهر فوق الصورة
                Positioned(
                  top: 10,
                  right: 10,
                  child: Column(
                    children: [
                      _QuickActionButton(
                        icon: Iconsax.edit,
                        color: Colors.blue,
                        onPressed: () => Get.toNamed(
                          TRoutes.editProduct,
                          arguments: product,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _QuickActionButton(
                        icon: Iconsax.trash,
                        color: TColors.error,
                        onPressed: () =>
                            controller.confirmAndDeleteProduct(product),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // الجزء السفلي: البيانات
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(TSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: TSizes.sm),

                  Text(
                    "المخزون: ${product.stock}",
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: isOutOfStock ? TColors.error : TColors.darkGrey,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${product.price}",
                        style: Theme.of(context).textTheme.headlineSmall!
                            .copyWith(
                              color: TColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Icon(
                        Iconsax.arrow_right_3,
                        size: 18,
                        color: TColors.darkGrey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// زر تفاعلي صغير للديسكتوب
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 18),
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}



/*
class ProductTablit extends StatelessWidget {
  const ProductTablit({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AllProductsController>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BreadcrumbWithHeading(
                heading: "المنتجات",
                breadcrumbItems: ["المنتجات"],
              ),
              //  Text("المنتجات", style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: TSizes.spaceBtwSections),

              TRoundedContainer(
                child: Column(
                  children: [
                    Tableheader(
                      buttonText: "اضف منتج",
                      onPressed: () => Get.toNamed(TRoutes.createProduct),
                      searchController: controller
                          .searchTextController, // تمرير الكنترولر هنا
                      searchOnChanged: (query) =>
                          controller.searchProduct(query),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),
                    ProductTable(),
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
*/