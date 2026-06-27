import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_variation_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_variation_image_controller.dart';
import 'package:stors_admin_panel/data/stor/models/product_attribute_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';
import 'package:stors_admin_panel/utils/popups/dialogs.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class ProductAttributesController extends GetxController {
  static ProductAttributesController get instance => Get.find();
  final c = Get.put(ProductVariationImageController());
  final isLoding = false.obs;
  final attributesFormKey = GlobalKey<FormState>();
  TextEditingController attributeName = TextEditingController();
  TextEditingController attribute = TextEditingController();

  final RxList<ProductAttributeModel> productAttributes =
      <ProductAttributeModel>[].obs;

  // الخريطة التي ستخزن الصور
  final RxMap<String, dynamic> attributeValueImages = <String, dynamic>{}.obs;

  void addNewAttribute() {
    if (!attributesFormKey.currentState!.validate()) {
      return;
    }

    // 1. استخراج النص وتنظيفه من الفراغات في البداية والنهاية
    final String rawInput = attribute.text.trim();

    // 2. تقسيم النص باستخدام التعبيرات النمطية (RegExp)
    // النمط [,|\\.] يعني: قسّم عند وجود (فاصلة ,) أو (خط رأسي |) أو (نقطة .)
    // تم استخدام \\ قبل النقطة لأن النقطة لها معنى خاص في RegEx ونريدها كحرف نصي طبيعي
    List<String> parsedValues = rawInput
        .split(RegExp(r'[,|،\.]'))
        // 3. تنظيف كل كلمة ناتجة من الفراغات الزائدة (مثال: " أحمر " تصبح "أحمر")
        .map((value) => value.trim())
        // 4. استبعاد أي قيم فارغة الناتجة عن تكرار العلامات بالخطأ (مثل: أحمر,,أزرق)
        .where((value) => value.isNotEmpty)
        .toList();

    // 5. التحقق من أن المستخدم أدخل قيمًا صالحة بالفعل بعد التفكيك
    if (parsedValues.isEmpty) {
      TLoaders.warningSnackBar(
        title: "تنبيه",
        message: "يرجى إدخال قيم للخاصية مفصولة بـ (، أو | أو .)",
      );
      return;
    }

    // 6. إضافة الخاصية الجديدة للقائمة
    productAttributes.add(
      ProductAttributeModel(
        name: attributeName.text.trim(),
        values: parsedValues,
      ),
    );

    // 7. تصفير الحقول النصية بأمان
    attributeName.clear();
    attribute.clear();
  }

  /*void addNewAttribute() {
    if (!attributesFormKey.currentState!.validate()) {
      return;
    }

    productAttributes.add(
      ProductAttributeModel(
        name: attributeName.text.trim(),
        values: attribute.text.trim().split('|').toList(),
      ),
    );

    attributeName.text = "";
    attribute.text = "";
  }*/

  void removeAttribute(int index, BuildContext context) {
    TDialogs.defaultDialog(
      title: "تأكيد الحذف",
      content:
          "إزالة هذه الخاصية سوف يؤدي إلى حذف جميع المتغيرات المرتبطة بها. هل أنت متأكد؟",
      cancelText: "إلغاء",
      confirmText: "حذف",
      context: context,
      onConfirm: () {
        Navigator.of(context).pop();
        productAttributes.removeAt(index);
        ProductVariationController.instance.resetsAllValues();
      },
    );
  }

  void resetProductAttributes() {
    productAttributes.clear();
    attributeValueImages.clear();
  }

  /// دالة تهيئة الخصائص وشحن الصور المصغرة عند التعديل
  void loadExistingAttributes(
    List<ProductAttributeModel> attributes,
    List<ProductVariationModel>? variations,
  ) {
    try {
      // 1. شحن الخصائص الأساسية
      productAttributes.assignAll(attributes);

      // 2. تفريغ الخريطة القديمة لتجنب تداخل بيانات منتج آخر
      attributeValueImages.clear();

      // 3. التحقق الذكي: إذا لم تكن هناك متغيرات، نخرج بسلام
      if (variations == null || variations.isEmpty) return;

      // 4. الدوران الآمن حول كافة المتغيرات لاستخراج روابط الصور
      for (var variation in variations) {
        if (variation.image != null &&
            variation.image.isNotEmpty &&
            variation.attributeValues != null &&
            variation.attributeValues!.isNotEmpty) {
          // 🔥 الحل الحاسم: الدوران عبر entries مع تحويل القيم لنصوص بشكل صارم وآمن
          for (var entry in variation.attributeValues!.entries) {
            final String attributeValue = entry.value
                .toString(); // تحويل آمن لأي نوع قادم
            final String trimValue = attributeValue.trim();

            if (trimValue.isNotEmpty &&
                !attributeValueImages.containsKey(trimValue)) {
              attributeValueImages[trimValue] = variation.image;
            }
          }
        }
      }
    } catch (e) {
      // منع انهيار الشاشة وطباعة الخطأ في الـ Console لمعرفته
      print("🚨 خطأ أثناء استخراج صور المتغيرات: $e");
    }
  }

  void initExistingAttributes(List<ProductAttributeModel> attributes) {
    productAttributes.assignAll(attributes);
  }

  // التعديل الأساسي هنا: إضافة الحماية (try-catch) ورسائل التنبيه للمستخدم
  Future<void> pickImageForAttributeValue(String value) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();

        // 1. تخزين الصورة للون المحدد
        attributeValueImages[value] = imageBytes;

        // 2. تحديث المتغيرات (Variations) المرتبطة بهذا اللون فوراً
        _syncImageWithVariations(value, imageBytes);

        // 3. تنبيه التاجر بنجاح العملية (تأكد من استيراد TLoaders)
        TLoaders.successSnackBar(
          title: 'تمت العملية',
          message: 'تم إرفاق الصورة بـ $value بنجاح',
        );
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في اختيار الصورة: $e');
    }
  }

  void _syncImageWithVariations(String value, Uint8List imageBytes) {
    final variationController = ProductVariationController.instance;
    final variationImageController =
        Get.find<ProductVariationImageController>();

    for (var variation in variationController.productVariation) {
      // إذا كان هذا المتغير (مثلاً مقاس S) يحتوي على اللون الذي رفعنا صورته للتو
      if (variation.attributeValues.values.contains(value)) {
        // نضع الصورة في كونتولر الصور الخاص بالمتغيرات
        // استخدمنا variation.id! للتأكد من أنه ليس null
        print("dbg-------- ${variation.id}");
        variationImageController.variationImageBytes[variation.id] = imageBytes;
      }
    }
  }

  /*
  void loadExistingAttributes(
    List<ProductAttributeModel> attributes,
    List<ProductVariationModel>? variations,
  ) {
    // 1. تنظيف البيانات الحالية
    productAttributes.clear();
    attributeValueImages.clear();

    // 2. تعبئة الخصائص
    productAttributes.assignAll(attributes);

    // 3. تعبئة الصور المرتبطة بالقيم (الخريطة attributeValueImages)
    // هنا نقوم بالبحث في المتغيرات (Variations) لنرى أي قيمة تمتلك صورة URL حالياً
    if (variations != null) {
      for (var variation in variations) {
        if (variation.image.isNotEmpty) {
          // نأخذ القيم الموجودة في هذا المتغير ونربط الصورة بها في الخريطة
          variation.attributeValues.forEach((key, value) {
            // إذا كانت القيمة لم يتم تعيين رابط لها بعد، نضع رابط الصورة
            if (!attributeValueImages.containsKey(value)) {
              // نضع الرابط كـ String (لأن الخريطة تقبل dynamic)
              attributeValueImages[value] = variation.image;
            }
          });
        }
      }
    }
  }
*/
}













/*
class ProductAttributesController extends GetxController {
  static get instance => Get.find();

  final isLoding = false.obs;
  final attributesFormKey = GlobalKey<FormState>();
  TextEditingController attributeName = TextEditingController();
  TextEditingController attribute = TextEditingController();
  final RxList<ProductAttributeModel> productAttributes =
      <ProductAttributeModel>[].obs;
  final RxMap<String, dynamic> attributeValueImages = <String, dynamic>{}.obs;

  void addNewAttribute() {
    if (!attributesFormKey.currentState!.validate()) {
      return;
    }

    productAttributes.add(
      ProductAttributeModel(
        name: attributeName.text.trim(),
        values: attribute.text.trim().split('|').toList(),
      ),
    );

    attributeName.text = "";
    attribute.text = "";
  }

  void removeAttribute(int index, BuildContext context) {
    TDialogs.defaultDialog(
      context: context,
      onConfirm: () {
        Navigator.of(context).pop();
        productAttributes.removeAt(index);
        ProductVariationController.instance.resetsAllValues();
      },
    );
  }

  void resetProductAttributes() {
    productAttributes.clear();
  }

  // أضف هذه الدالة داخل ProductAttributesController
  void initExistingAttributes(List<ProductAttributeModel> attributes) {
    productAttributes.assignAll(attributes);
  }

  Future<void> pickImageForAttributeValue(String value) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List imageBytes = await image.readAsBytes();
      attributeValueImages[value] = imageBytes;
      // سنقوم بربطها بالمتغيرات في الخطوة التالية
      _syncImageWithVariations(value, imageBytes);
    }
  }

  void _syncImageWithVariations(String value, Uint8List imageBytes) {
    final variationController = ProductVariationController.instance;
    for (var variation in variationController.productVariation) {
      if (variation.attributeValues.values.contains(value)) {
        ProductVariationImageController.instance.variationImageBytes[variation
                .id] =
            imageBytes;
      }
    }
  }
}
*/