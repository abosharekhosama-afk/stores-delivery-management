import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/data/stor/controller/product/all_products_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/wallet_controller.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class TProductCardMobile extends StatelessWidget {
  const TProductCardMobile({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = product.stock == 0;
    final controller = Get.find<AllProductsController>();
    final dark = THelperFunctions.isDarkMode(context);

    /*return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      child: Slidable(
        key: ValueKey(product.id),

        // تحسين تصميم أزرار السحب (تصميم زجاجي عصري)
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.5,
          children: [
            CustomSlidableAction(
              onPressed: (context) {
                // 1. الوصول للكنترولر (تأكد أنه تم حقنه بالفعل أو استخدم Get.put)
                final controller = Get.put(ProductAdditionController());

                // 2. استدعاء دالة التحميل التي فحصناها سابقاً وتمرير المنتج
                controller.setProductForEditing(product);

                // 3. الانتقال لواجهة التعديل
                Get.toNamed(TRoutes.editProduct, arguments: product);
              },
              backgroundColor: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.edit, color: Colors.white),
                    Text(
                      "تعديل",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            CustomSlidableAction(
              onPressed: (context) =>
                  controller.confirmAndDeleteProduct(product),
              backgroundColor: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: TColors.error.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.trash, color: Colors.white),
                    Text(
                      "حذف",
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
*/

    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems / 2),
      child: Slidable(
        key: ValueKey(product.id),

        // تحسين تصميم أزرار السحب (تصميم عصري يملأ كامل المساحة المتاحة وبدون هوامش ميتة)
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio:
              0.5, // المساحة التي تأخذها الأزرار مجتمعة عند السحب الكامل
          children: [
            // --- زر التعديل العصري ---
            Expanded(
              child: CustomSlidableAction(
                onPressed: (context) {
                  final editController = Get.put(ProductAdditionController());
                  editController.clearAllControllersData();
                  editController.setProductForEditing(product);
                  Get.toNamed(TRoutes.editProduct, arguments: product);
                },
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero, // تصفير الحواف لملء المساحة
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 4,
                  ), // هامش بسيط جداً للفصل عن حواف الشاشة
                  decoration: BoxDecoration(
                    // تدرج لوني أزرق حديث وعميق بدلاً من اللون المصمت
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                    ),
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // أيقونة مكبرة قليلاً لتصميم أكثر حداثة
                      Icon(Iconsax.edit, color: Colors.white, size: 24),
                      SizedBox(height: 6),
                      Text(
                        "تعديل",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- زر الحذف العصري ---
            Expanded(
              child: CustomSlidableAction(
                onPressed: (context) =>
                    controller.confirmAndDeleteProduct(product),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero, // تصفير الحواف لملء المساحة
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    // تدرج ناري فخم للتحذير والحذف
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [TColors.error.withOpacity(0.8), TColors.error],
                    ),
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: TColors.error.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.trash, color: Colors.white, size: 24),
                      SizedBox(height: 6),
                      Text(
                        "حذف",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => Get.toNamed(TRoutes.productDetails, arguments: product),
          child: Container(
            decoration: BoxDecoration(
              color: dark ? TColors.dark : Colors.white,
              borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
              border: Border.all(
                color: dark ? TColors.darkGrey : TColors.grey.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // القسم الجانبي: الصورة والحالة
                  Stack(
                    children: [
                      TRoundedImage(
                        imageType: ImageType.network,
                        image: product.thumbnail,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        applyImageRadius: true,
                      ),
                      // أيقونة إخفاء/إظهار المنتج (سريعة)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () =>
                              controller.toggleProductVisibility(product),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  product.productVisibility ==
                                      ProductVisibility.published
                                  ? Colors.green.withOpacity(0.9)
                                  : Colors.orange.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              product.productVisibility ==
                                      ProductVisibility.published
                                  ? Iconsax.eye
                                  : Iconsax.eye_slash,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: TSizes.spaceBtwItems),

                  // قسم المعلومات
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                style: Theme.of(context).textTheme.titleMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _buildStockBadge(context, isOutOfStock),
                            ],
                          ),

                          // السعر مع زر التعديل السريع
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => _showQuickPriceEdit(
                                  context,
                                  controller,
                                  product,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "\$${product.price}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall!
                                          .copyWith(
                                            color: TColors.primary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Iconsax.edit_2,
                                      size: 14,
                                      color: TColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                              // مؤشر سحب
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: TColors.grey.withOpacity(0.1),
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(10),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.chevron_left,
                                  size: 18,
                                  color: TColors.darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ويدجت حالة المخزون
  Widget _buildStockBadge(BuildContext context, bool isOutOfStock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOutOfStock
            ? TColors.error.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isOutOfStock ? "نفذت الكمية" : "متاح: ${product.stock}",
        style: TextStyle(
          color: isOutOfStock ? TColors.error : Colors.green,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // بوتم شيت سريع لتعديل السعر
  void _showQuickPriceEdit(
    BuildContext context,
    AllProductsController controller,
    ProductModel product,
  ) {
    final priceController = TextEditingController(
      text: product.price.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text("تحديث السعر", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Iconsax.money),
                labelText: "السعر الجديد",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.updatePriceWithLogic(
                    product,
                    double.parse(priceController.text),
                  );
                  Get.back();
                },
                child: const Text("تحديث الآن"),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(
    BuildContext context,
    WalletController controller,
    double availableBalance,
  ) {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "طلب سحب رصيد",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "الرصيد المتاح حالياً: ₪ ${availableBalance.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "المبلغ المطلوب",
                prefixText: "₪ ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  double? requestedAmount = double.tryParse(
                    amountController.text,
                  );
                  if (requestedAmount != null &&
                      requestedAmount > 0 &&
                      requestedAmount <= availableBalance) {
                    controller.requestWithdrawal(requestedAmount);
                  } else {
                    TLoaders.errorSnackBar(
                      title: "خطأ",
                      message: "المبلغ المدخل غير صحيح أو يتجاوز رصيدك المتاح",
                    );
                  }
                },

                child: const Text(
                  "تأكيد طلب السحب",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
