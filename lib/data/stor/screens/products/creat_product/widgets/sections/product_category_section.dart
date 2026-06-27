import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/data/stor/models/category_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

/// ProductCategorySection - قسم الفئة والعلامة التجارية والعلامات
/// يتيح اختيار الفئة والعلامة التجارية وإضافة علامات للمنتج
class ProductCategorySection extends StatelessWidget {
  const ProductCategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProductAdditionController.instance;

    return TRoundedContainer(
      child: Form(
        key: controller.categoryFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TColors.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                  ),
                  child: Icon(
                    Iconsax.category_2,
                    color: TColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Text(
                  "الفئة والعلامات",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: TColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwItems),
            const Divider(),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Category Selection
            _buildCategorySelection(context),
            const SizedBox(height: TSizes.spaceBtwInputFields),

            // Brand Selection
            //_buildBrandSelection(),
            //const SizedBox(height: TSizes.spaceBtwInputFields),

            // Tags Section
            _buildTagsSection(),

            // Category Tips
            const SizedBox(height: TSizes.spaceBtwItems),
            _buildCategoryTips(),

            // Validation Status
            const SizedBox(height: TSizes.spaceBtwItems),
            Obx(() => _buildValidationStatus()),
          ],
        ),
      ),
    );
  }

  /// بناء اختيار الفئة
  Widget _buildCategorySelection(BuildContext context) {
    final controller = ProductAdditionController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان مع النجمة للمجالات المطلوبة
        Row(
          children: [
            Text("الفئة", style: Theme.of(context).textTheme.bodyLarge),
            const Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 12),

        Obx(() {
          // 1. فصل التصنيفات الرئيسية عن الفرعية
          final parentCategories = controller.categories
              .where((cat) => cat.parentId.isEmpty)
              .toList();
          final allCategories = controller.categories;

          // 2. بناء قائمة مرتبة: "رئيسي" يتبعه "فرعي"
          List<CategoryModel> dropdownList = [];
          for (var parent in parentCategories) {
            dropdownList.add(parent); // إضافة الرئيسي أولاً
            // إضافة الفرعي الذي ينتمي لهذا الرئيسي
            dropdownList.addAll(
              allCategories.where((cat) => cat.parentId == parent.id),
            );
          }

          return DropdownButtonFormField<String>(
            value: controller.selectedCategory.value?.id,
            isExpanded: true, // لضمان عدم خروج النص عن الإطار
            decoration: InputDecoration(
              hintText: "اختر الفئة الفرعية",
              prefixIcon: const Icon(Iconsax.category),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            // 3. بناء العناصر مع التمييز البصري
            items: dropdownList.map((category) {
              final isParent = category.parentId.isEmpty;

              return DropdownMenuItem<String>(
                value: isParent
                    ? null
                    : category
                          .id, // إذا كان رئيساً، نجعل القيمة null لمنع اختياره
                enabled: !isParent, // تعطيل الضغط على التصنيف الرئيسي
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isParent ? 8 : 4,
                    horizontal: isParent
                        ? 0
                        : 12, // إزاحة للداخل للفرعي (Indentation)
                  ),
                  decoration: BoxDecoration(
                    // تمييز التصنيف الرئيسي بخلفية خفيفة
                    color: isParent
                        ? TColors.primary.withAlpha((0.05 * 255).round())
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isParent ? Iconsax.folder_open : Iconsax.arrow_right_3,
                        size: isParent ? 18 : 14,
                        color: isParent ? TColors.primary : TColors.grey,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: isParent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isParent
                              ? TColors.primary
                              : TColors.textPrimary,
                          fontSize: isParent ? 14 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            onChanged: (value) {
              if (value != null) {
                final category = controller.categories.firstWhere(
                  (cat) => cat.id == value,
                );
                controller.updateCategory(category);
              }
            },

            // منع ظهور خطأ عند وجود عناصر Enabled: false
            validator: (value) =>
                value == null ? "يرجى اختيار فئة فرعية" : null,
          );
        }),
      ],
    );
  }

  /*Widget _buildCategorySelection() {
    final controller = ProductAdditionController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "الفئة",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: TColors.textPrimary,
              ),
            ),
            Text(
              " *",
              style: TextStyle(
                color: TColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        Obx(() {
          final categories = controller.categories;
          final selectedCategory = controller.selectedCategory.value;

          return DropdownButtonFormField<String>(
            value: selectedCategory?.id,
            decoration: InputDecoration(
              hintText: "اختر الفئة",
              prefixIcon: Icon(Iconsax.category, color: TColors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                borderSide: BorderSide(color: TColors.primary, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: categories.map((category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Row(
                  children: [
                    Icon(Iconsax.category, size: 16, color: TColors.grey),
                    const SizedBox(width: 8),
                    Text(category.name),
                    if (category.isFeatured)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: TColors.primary.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "مميز",
                          style: TextStyle(
                            fontSize: 10,
                            color: TColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final category = categories.firstWhere(
                  (cat) => cat.id == value,
                );
                controller.updateCategory(category);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "يرجى اختيار الفئة";
              }
              return null;
            },
          );
        }),
      ],
    );
  }
*/
  /// بناء اختيار العلامة التجارية
  Widget _buildBrandSelection() {
    final controller = ProductAdditionController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "العلامة التجارية",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: TColors.textPrimary,
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        Obx(() {
          final brands = controller.brands;
          final selectedBrand = controller.selectedBrand.value;

          return DropdownButtonFormField<String>(
            value: selectedBrand?.id,
            decoration: InputDecoration(
              hintText: "اختر العلامة التجارية (اختياري)",
              prefixIcon: Icon(Iconsax.shop, color: TColors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                borderSide: BorderSide(color: TColors.primary, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [
              // خيار عدم اختيار علامة تجارية
              const DropdownMenuItem<String>(
                value: null,
                child: Text("بدون علامة تجارية"),
              ),
              ...brands.map((brand) {
                return DropdownMenuItem<String>(
                  value: brand.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.shop, size: 16, color: TColors.grey),
                      const SizedBox(width: 8),
                      Text(brand.name),
                      if (brand.isFeatured == true)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: TColors.primary.withAlpha(
                              (0.1 * 255).round(),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "مميز",
                            style: TextStyle(
                              fontSize: 10,
                              color: TColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        "${brand.productsCount ?? 0} منتج",
                        style: TextStyle(fontSize: 10, color: TColors.grey),
                      ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) {
              if (value != null) {
                final brand = brands.firstWhere((b) => b.id == value);
                controller.updateBrand(brand);
              } else {
                controller.updateBrand(null);
              }
            },
          );
        }),
      ],
    );
  }

  /// بناء قسم العلامات
  Widget _buildTagsSection() {
    final controller = ProductAdditionController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "العلامات",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: TColors.textPrimary,
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        // Tags Input
        TextFormField(
          controller: controller.tagsController,
          decoration: InputDecoration(
            hintText: "أدخل العلامات (مفصولة بفواصل)",
            prefixIcon: Icon(Iconsax.tag, color: TColors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              borderSide: BorderSide(color: TColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: controller.updateTags,
        ),

        const SizedBox(height: TSizes.spaceBtwItems),

        // Tags Display
        Obx(() {
          final tags = controller.tags;

          if (tags.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TColors.grey.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                border: Border.all(
                  color: TColors.grey.withAlpha((0.3 * 255).round()),
                ),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.tag, color: TColors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "لا توجد علامات محددة",
                    style: TextStyle(color: TColors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: Icon(Iconsax.close_circle, size: 16),
                onDeleted: () {
                  controller.removeTag(tag);
                },
                backgroundColor: TColors.primary.withAlpha((0.1 * 255).round()),
                labelStyle: TextStyle(color: TColors.primary, fontSize: 12),
              );
            }).toList(),
          );
        }),

        // Add Tag Button
        const SizedBox(height: TSizes.spaceBtwItems),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _showAddTagDialog(),
            icon: Icon(Iconsax.add, size: 14),
            label: const Text("إضافة علامة جديدة"),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  /// بناء نصائح الفئة
  Widget _buildCategoryTips() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TColors.info.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
        border: Border.all(color: TColors.info.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.info_circle, color: TColors.info, size: 16),
              const SizedBox(width: 8),
              Text(
                "نصائح التصنيف",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "• اختر الفئة المناسبة لتسهيل عثور العملاء على منتجك\n"
            // "• العلامة التجارية تساعد في بناء الثقة والتعرف على منتجاتك\n"
            "• العلامات تساعد في تحسين ظهور منتجك في نتائج البحث\n"
            "• استخدم كلمات مفتاحية دقيقة ومفهومة",
            style: TextStyle(
              fontSize: 12,
              color: TColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء حالة التحقق
  Widget _buildValidationStatus() {
    final controller = ProductAdditionController.instance;
    final isValid = controller.isCategoryComplete.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isValid
            ? TColors.success.withAlpha((0.1 * 255).round())
            : TColors.warning.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
        border: Border.all(
          color: isValid ? TColors.success : TColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Iconsax.tick_circle : Iconsax.warning_2,
            color: isValid ? TColors.success : TColors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isValid ? "بيانات التصنيف صحيحة" : "يرجى مراجعة بيانات التصنيف",
            style: TextStyle(
              fontSize: 12,
              color: isValid ? TColors.success : TColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// عرض حوار إضافة علامة جديدة
  void _showAddTagDialog() {
    final controller = ProductAdditionController.instance;
    final tagController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text("إضافة علامة جديدة"),
        content: TextFormField(
          controller: tagController,
          decoration: const InputDecoration(
            hintText: "أدخل اسم العلامة",
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'اسم العلامة مطلوب';
            }
            if (value.length > 20) {
              return 'اسم العلامة يجب أن يكون أقل من 20 حرف';
            }
            return null;
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              final tag = tagController.text.trim();
              if (tag.isNotEmpty && tag.length <= 20) {
                controller.addTag(tag);
                Get.back();
              }
            },
            child: const Text("إضافة"),
          ),
        ],
      ),
    );
  }
}
