import 'package:get/get.dart';
import '../../../../data/stor/models/product_model.dart';
import '../../../../data/stor/models/product_variation_model.dart';

class ProductDetailController extends GetxController {
  final ProductModel product;
  ProductDetailController(this.product);

  // تخزين القيم المختارة حالياً (مثلاً: {اللون: أحمر, المقاس: كبير})
  RxMap<String, String> selectedAttributes = <String, String>{}.obs;
  late RxString selectedImage;
  // المتغير المختار بناءً على القيم أعلاه
  Rx<ProductVariationModel?> selectedVariation = Rx<ProductVariationModel?>(
    null,
  );

  @override
  void onInit() {
    super.onInit();
    selectedImage = product.thumbnail.obs; // تهيئة الصورة الأولى
    // تهيئة الاختيارات الافتراضية إذا كان المنتج متغير
    if (product.productType == 'variable' && product.productAttribute != null) {
      for (var attr in product.productAttribute!) {
        if (attr.values != null && attr.values!.isNotEmpty) {
          selectedAttributes[attr.name ?? ''] = attr.values!.first;
        }
      }
      _updateSelectedVariation();
    }
  }

  // تحديث القيمة المختارة (مثلاً عند النقر على لون جديد)
  void onAttributeSelected(String attributeName, String value) {
    selectedAttributes[attributeName] = value;
    _updateSelectedVariation();
  }

  // البحث عن المتغير المطابق في قائمة Variations
  void _updateSelectedVariation() {
    if (product.productVariation == null) return;

    final match = product.productVariation!.firstWhere(
      (variation) {
        // نتحقق من أن كل القيم المختارة تطابق ما هو موجود في attributeValues للفاريشن
        return selectedAttributes.entries.every(
          (entry) =>
              variation.attributeValues[entry.key]?.trim() ==
              entry.value.trim(),
        );
      },
      orElse: () =>
          product.productVariation!.first, // إذا لم يجد، يعود لأول واحد
    );
    selectedVariation.value = match;
  }
}
