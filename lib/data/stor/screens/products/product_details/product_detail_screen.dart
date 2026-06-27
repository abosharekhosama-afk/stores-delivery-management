import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_detail_controller.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/data/stor/screens/products/product_details/widgets/product_additional_details.dart';
import 'package:stors_admin_panel/data/stor/screens/products/product_details/widgets/product_attributs.dart';
import 'package:stors_admin_panel/data/stor/screens/products/product_details/widgets/product_image_header.dart';
import 'package:stors_admin_panel/data/stor/screens/products/product_details/widgets/product_title_price.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductModel product = Get.arguments;
    final controller = Get.put(ProductDetailController(product));
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
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              TProductImageHeader(product: product),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    30,
                    20,
                    100,
                  ), // مساحة إضافية في الأسفل
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. السعر والعنوان
                      Obx(
                        () => TProductTitlePrice(
                          product: product,
                          selectedVariation: controller.selectedVariation.value,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // 2. بطاقة البيانات التقنية (Grid)
                      TProductAdditionalDetails(product: product),

                      const SizedBox(height: 25),

                      // 3. الخيارات (Attributes) - تصميم ChoiceChips نظيف
                      if (product.isVariableProduct)
                        TProductAttributs(product: product),
                      const SizedBox(height: 20),

                      /*
                      if (product.productAttribute != null)
                        ...product.productAttribute!.map(
                          (attr) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attr.name ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Obx(
                                () => Wrap(
                                  spacing: 12,
                                  children: attr.values!.map((val) {
                                    final isSelected =
                                        controller.selectedAttributes[attr
                                            .name] ==
                                        val;
                                    return ChoiceChip(
                                      label: Text(val),
                                      selected: isSelected,
                                      onSelected: (s) => controller
                                          .onAttributeSelected(attr.name!, val),
                                      backgroundColor: Colors.white,
                                      selectedColor: TColors.primary,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
*/
                      // 4. وصف المنتج بتنسيق حديث
                      const Text(
                        "الوصف",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.description ?? "لا يوجد وصف.",
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          height: 1.6,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
