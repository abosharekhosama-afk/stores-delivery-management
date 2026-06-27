import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_attributes_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_variation_image_controller.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';
import 'package:stors_admin_panel/utils/popups/dialogs.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart'; // تأكد من استيراد كونتولر الإضافة

class ProductVariationController extends GetxController {
  static ProductVariationController get instance => Get.find();
  final isLoading = false.obs;
  final RxList<ProductVariationModel> productVariation =
      <ProductVariationModel>[].obs;

  List<Map<ProductVariationModel, TextEditingController>> stockControllerList =
      [];
  List<Map<ProductVariationModel, TextEditingController>> priceControllerList =
      [];
  List<Map<ProductVariationModel, TextEditingController>>
  salePriceControllerList = [];
  List<Map<ProductVariationModel, TextEditingController>>
  descriptionControllerList = [];
  List<Map<ProductVariationModel, TextEditingController>> skuControllerList =
      [];

  final attributesController = ProductAttributesController.instance;

  // دالة تهيئة الكنترولر (مسح البيانات القديمة)
  void intializaVariationControllers(List<ProductVariationModel> variation) {
    stockControllerList.clear();
    skuControllerList.clear();
    priceControllerList.clear();
    salePriceControllerList.clear();
    descriptionControllerList.clear();
  }

  void removeVariations(BuildContext context) {
    TDialogs.defaultDialog(
      context: context,
      title: "تاكيد الحذف",
      content: "هل انت متاكد من حذف جميع المتغيرات؟",
      onConfirm: () {
        productVariation.value = [];
        resetsAllValues();
        Navigator.of(context).pop();
      },
    );
  }

  void resetsAllValues() {
    productVariation.clear();
    stockControllerList.clear();
    skuControllerList.clear();
    priceControllerList.clear();
    salePriceControllerList.clear();
    descriptionControllerList.clear();
  }

  void generateVariationConfirmation(BuildContext context) {
    TDialogs.defaultDialog(
      context: context,
      confirmText: "توليد",
      cancelText: "إلغاء",
      title: "توليد خاصية",
      content:
          "بمجرد توليد الخاصية لا يمكن اضافة المزيد من الخيارات وسوف تحتاج حذف جميع الخيارات.",
      onConfirm: () => generateVariationFromAttributes(),
    );
  }

  /// الدالة المعدلة والمصححة بالكامل لتوليد المتغيرات ووراثة القيم والصور
  void generateVariationFromAttributes() {
    Get.back(); // إغلاق الديالوج

    // 1. جلب القيم الأساسية من كونتولر الإضافة (ProductAdditionController)
    final additionController = ProductAdditionController.instance;
    final String basePrice = additionController.priceController.text.trim();
    final String baseStock = additionController.stockController.text.trim();
    final String baseSku = additionController.skuController.text.trim();
    final String baseSalePrice = additionController.salePriceController.text
        .trim();

    // جلب خريطة صور الخصائص المصغرة
    final attImageValue = attributesController.attributeValueImages;

    // مسح البيانات الحالية قبل التوليد الجديد لضمان عدم التكرار
    resetsAllValues();

    final variationImageController =
        Get.find<ProductVariationImageController>();
    final List<ProductVariationModel> variations = [];

    if (attributesController.productAttributes.isNotEmpty) {
      // توليد كافة الاحتمالات الممكنة (Combinations)
      final List<List<String>> attributCombination = getCombinations(
        attributesController.productAttributes
            .map((element) => element.values ?? <String>[])
            .toList(),
      );

      for (final combintion in attributCombination) {
        final Map<String, String> attributeValue = Map.fromIterables(
          attributesController.productAttributes.map(
            (element) => element.name ?? "",
          ),
          combintion,
        );

        // إنشاء المعرف الفريد للمتغير مدمجاً بـ '-'
        final String variationId = combintion.map((e) => e.trim()).join('-');

        // 2. إنشاء الموديل مع القيم الأساسية الموروثة
        final variation = ProductVariationModel(
          id: variationId,
          attributeValues: attributeValue,
          sku: baseSku,
          price: double.tryParse(basePrice) ?? 0.0,
          stock: int.tryParse(baseStock) ?? 0,
          salePrice: double.tryParse(baseSalePrice) ?? 0.0,
        );

        // 🔥 الحل الحاسم لمزامنة الصور عند التوليد:
        // نمر على القيم الفردية للمتغير الحالي (مثل: "أحمر"، "XL")
        // ونرى إن كانت إحداها تمتلك صورة مرفوعة في صفحة الخصائص
        for (var val in combintion) {
          final trimVal = val.trim();
          if (attImageValue.containsKey(trimVal)) {
            // ربط الصورة بـ ID المتغير المدمج في كونتولر صور المتغيرات
            variationImageController.variationImageBytes[variationId] =
                attImageValue[trimVal];
            break; // نكتفي بصورة واحدة للمتغير في حال وجود أكثر من خاصية مصورة
          }
        }

        variations.add(variation);

        // 3. تعبئة الـ TextControllers بالقيم الموروثة لتظهر في الواجهة فوراً
        stockControllerList.add({
          variation: TextEditingController(text: baseStock),
        });
        skuControllerList.add({
          variation: TextEditingController(text: baseSku),
        });
        priceControllerList.add({
          variation: TextEditingController(text: basePrice),
        });
        salePriceControllerList.add({
          variation: TextEditingController(text: baseSalePrice),
        });
        descriptionControllerList.add({variation: TextEditingController()});
      }
    }

    // تحديث القائمة المرصودة لإعادة بناء واجهة العرض فوراً
    productVariation.assignAll(variations);
  }

  /// الدالة المعدلة لتوليد المتغيرات مع وراثة القيم
  /*
  void generateVariationFromAttributes() {
    Get.back(); // إغلاق الديالوج

    // 1. جلب القيم الأساسية من كونتولر الإضافة (ProductAdditionController)
    final additionController = ProductAdditionController.instance;
    final String basePrice = additionController.priceController.text.trim();
    final String baseStock = additionController.stockController.text.trim();
    final String baseSku = additionController.skuController.text.trim();
    final String baseSalePrice = additionController.salePriceController.text
        .trim();
    final attImageValue = attributesController.attributeValueImages;
    // مسح البيانات الحالية قبل التوليد الجديد لضمان عدم التكرار
    resetsAllValues();
    final variationImageController =
        Get.find<ProductVariationImageController>();
    final List<ProductVariationModel> variations = [];

    if (attributesController.productAttributes.isNotEmpty) {
      final List<List<String>> attributCombination = getCombinations(
        attributesController.productAttributes
            .map((element) => element.values ?? <String>[])
            .toList(),
      );

      for (final combintion in attributCombination) {
        final Map<String, String> attributeValue = Map.fromIterables(
          attributesController.productAttributes.map(
            (element) => element.name ?? "",
          ),
          combintion,
        );

        // 2. إنشاء الموديل مع القيم الأساسية الموروثة
        final variation = ProductVariationModel(
          id: attributeValue.values.join('-'),
          attributeValues: attributeValue,
          sku: baseSku,
          price: double.tryParse(basePrice) ?? 0.0,
          stock: int.tryParse(baseStock) ?? 0,
          salePrice: double.tryParse(baseSalePrice) ?? 0.0,
        );

        if (variation.attributeValues.values.contains(variation.id)) {
          variationImageController.variationImageBytes[variation.id] =
              attImageValue[variation.id];
        }

        variations.add(variation);

        // 3. تعبئة الـ TextEditingControllers بالقيم الموروثة لتظهر في الواجهة فوراً
        stockControllerList.add({
          variation: TextEditingController(text: baseStock),
        });
        skuControllerList.add({
          variation: TextEditingController(text: baseSku),
        });
        priceControllerList.add({
          variation: TextEditingController(text: basePrice),
        });
        salePriceControllerList.add({
          variation: TextEditingController(text: baseSalePrice),
        });
        descriptionControllerList.add({variation: TextEditingController()});
      }
    }

    productVariation.assignAll(variations);
  }
*/
  List<List<String>> getCombinations(List<List<String>> lists) {
    final List<List<String>> result = [];
    combine(lists, 0, <String>[], result);
    return result;
  }

  void combine(
    List<List<String>> lists,
    int index,
    List<String> current,
    List<List<String>> result,
  ) {
    if (index == lists.length) {
      result.add(List.from(current));
      return;
    }
    for (final item in lists[index]) {
      final List<String> updated = List.from(current)..add(item);
      combine(lists, index + 1, updated, result);
    }
  }

  void initExistingVariations(List<ProductVariationModel> variations) {
    resetsAllValues();

    for (var variation in variations) {
      productVariation.add(variation);

      final stock = TextEditingController(text: variation.stock.toString());
      final sku = TextEditingController(text: variation.sku.toString());
      final price = TextEditingController(text: variation.price.toString());
      final salePrice = TextEditingController(
        text: variation.salePrice.toString(),
      );
      final description = TextEditingController(
        text: variation.description ?? '',
      );

      stockControllerList.add({variation: stock});
      skuControllerList.add({variation: sku});
      priceControllerList.add({variation: price});
      salePriceControllerList.add({variation: salePrice});
      descriptionControllerList.add({variation: description});

      if (variation.image.isNotEmpty) {
        Get.find<ProductVariationImageController>().variationImageUrls[variation
                .id] =
            variation.image;
      }
    }
  }

  // دوال التعديل الجماعي (تحديث الواجهة والموديل معاً)
  void applyPriceToAll(String price) {
    double? p = double.tryParse(price);
    if (p == null) return;
    for (var map in priceControllerList) {
      map.values.first.text = price;
      map.keys.first.price = p;
    }
    productVariation.refresh();
  }

  void applySalePriceToAll(String salePrice) {
    double? p = double.tryParse(salePrice);
    if (p == null) return;
    for (var map in salePriceControllerList) {
      map.values.first.text = salePrice;
      map.keys.first.salePrice = p;
    }
    productVariation.refresh();
  }

  void applyStockToAll(String stock) {
    int? s = int.tryParse(stock);
    if (s == null) return;
    for (var map in stockControllerList) {
      map.values.first.text = stock;
      map.keys.first.stock = s;
    }
    productVariation.refresh();
  }

  void applyDescriptionToAll(String description) {
    for (var map in descriptionControllerList) {
      map.values.first.text = description;
      map.keys.first.description = description;
    }
    productVariation.refresh();
  }

  void applySKUToAll(String sku) {
    for (var map in salePriceControllerList) {
      map.values.first.text = sku;
      map.keys.first.sku = sku;
    }
    productVariation.refresh();
  }

  /// دالة تهيئة المتغيرات عند تعديل منتج موجود
  void loadExistingVariations(List<ProductVariationModel> variations) {
    // 1. تنظيف البيانات الحالية
    resetsAllValues();

    // 2. تعبئة القائمة الأساسية
    productVariation.assignAll(variations);

    // 3. إنشاء الكنترولرز لكل متغير
    for (var variation in variations) {
      // السعر
      final priceController = TextEditingController(
        text: variation.price.toString(),
      );
      priceControllerList.add({variation: priceController});

      // السعر المخفض
      final salePriceController = TextEditingController(
        text: variation.salePrice.toString(),
      );
      salePriceControllerList.add({variation: salePriceController});

      // المخزون
      final stockController = TextEditingController(
        text: variation.stock.toString(),
      );
      stockControllerList.add({variation: stockController});

      // المخزون
      final skuController = TextEditingController(
        text: variation.sku.toString(),
      );
      skuControllerList.add({variation: skuController});

      // الوصف
      final descController = TextEditingController(
        text: variation.description ?? '',
      );
      descriptionControllerList.add({variation: descController});

      // إذا كانت هناك صور، نقوم بتهيئتها في كونتولر الصور
      if (variation.image.isNotEmpty) {
        ProductVariationImageController.instance.variationImageUrls[variation
                .id] =
            variation.image;
      }
    }
  }

  /// حذف متغير وتحديث جميع القوائم المرتبطة به لضمان عدم حدوث تسريب في الذاكرة أو خطأ في البيانات
  void removeVariationAt(int index) {
    if (index >= 0 && index < productVariation.length) {
      final variation = productVariation[index];

      // 1. حذف الـ Controllers المرتبطة بهذا المتغير من القوائم
      // نستخدم removeWhere لضمان حذف الخريطة (Map) التي تحتوي على هذا الموديل
      priceControllerList.removeWhere((map) => map.containsKey(variation));
      stockControllerList.removeWhere((map) => map.containsKey(variation));
      skuControllerList.removeWhere((map) => map.containsKey(variation));
      salePriceControllerList.removeWhere((map) => map.containsKey(variation));
      descriptionControllerList.removeWhere(
        (map) => map.containsKey(variation),
      );

      // 2. حذف الموديل نفسه من قائمة المتغيرات
      productVariation.removeAt(index);

      // 3. تحديث الواجهة
      productVariation.refresh();
    }
  }
}















/*
class ProductVariationController extends GetxController {
  static ProductVariationController get instance => Get.find();

  final isLoading = false.obs;
  final RxList<ProductVariationModel> productVariation =
      <ProductVariationModel>[].obs;

  List<Map<ProductVariationModel, TextEditingController>> stockControllerList =
      [];
  List<Map<ProductVariationModel, TextEditingController>> priceControllerList =
      [];
  List<Map<ProductVariationModel, TextEditingController>>
  salePriceControllerList = [];
  List<Map<ProductVariationModel, TextEditingController>>
  descriptionControllerList = [];
  final attributesController = Get.put(ProductAttributesController());

  void intializaVariationControllers(List<ProductVariationModel> variation) {
    stockControllerList.clear();
    priceControllerList.clear();
    salePriceControllerList.clear();
    descriptionControllerList.clear();
  }

  void removeVariations(BuildContext context) {
    TDialogs.defaultDialog(
      context: context,
      title: "ازالة",
      onConfirm: () {
        productVariation.value = [];
        resetsAllValues();
        Navigator.of(context).pop();
      },
    );
  }

  void resetsAllValues() {
    productVariation.clear();
    stockControllerList.clear();
    priceControllerList.clear();
    salePriceControllerList.clear();
    descriptionControllerList.clear();
  }

  void generateVariationConfirmation(BuildContext context) {
    TDialogs.defaultDialog(
      context: context,
      confirmText: "توليد",
      title: "توليد خاصية",
      content:
          "بمجرد توليد الخاصية لا يمكن اضافة المزيد من الخيارات وسوف تحتاج حذف جميع الخيارات.",
      onConfirm: () => generateVariationFromAttributes(),
    );
  }

  void generateVariationFromAttributes() {
    Get.back();
    final List<ProductVariationModel> variations = [];

    if (attributesController.productAttributes.isNotEmpty) {
      final List<List<String>> attributCombination = getCombinations(
        attributesController.productAttributes
            .map((element) => element.values ?? <String>[])
            .toList(),
      );

      for (final combintion in attributCombination) {
        final Map<String, String> attributeValue = Map.fromIterables(
          attributesController.productAttributes.map(
            (element) => element.name ?? "",
          ),
          combintion,
        );

        final variation = ProductVariationModel(
          // المعرف سيكون عبارة عن دمج القيم المختارة (مثلاً: اصفر-معدن)
          id: attributeValue.values.join('-'),
          attributeValues: attributeValue,
        );

        variations.add(variation);

        final Map<ProductVariationModel, TextEditingController>
        stockControllers = {};
        final Map<ProductVariationModel, TextEditingController>
        priceControllers = {};
        final Map<ProductVariationModel, TextEditingController>
        salePriceControllers = {};
        final Map<ProductVariationModel, TextEditingController>
        sdescriptionControllers = {};

        stockControllers[variation] = TextEditingController();
        priceControllers[variation] = TextEditingController();
        salePriceControllers[variation] = TextEditingController();
        sdescriptionControllers[variation] = TextEditingController();

        stockControllerList.add(stockControllers);
        priceControllerList.add(priceControllers);
        salePriceControllerList.add(salePriceControllers);
        descriptionControllerList.add(sdescriptionControllers);
      }
    }

    productVariation.assignAll(variations);
  }

  List<List<String>> getCombinations(List<List<String>> lists) {
    final List<List<String>> result = [];
    combine(lists, 0, <String>[], result);
    return result;
  }

  void combine(
    List<List<String>> lists,
    int index,
    List<String> current,
    List<List<String>> result,
  ) {
    if (index == lists.length) {
      result.add(List.from(current));
      return;
    }

    for (final item in lists[index]) {
      final List<String> updated = List.from(current)..add(item);
      combine(lists, index + 1, updated, result);
    }
  }

  // أضف هذه الدالة داخل ProductVariationController
  void initExistingVariations(List<ProductVariationModel> variations) {
    resetsAllValues(); // تنظيف أي بيانات قديمة

    for (var variation in variations) {
      // إضافة المتغير للقائمة التفاعلية
      productVariation.add(variation);

      // إنشاء الـ Controllers وربطها بالقيم الحالية
      final stock = TextEditingController(text: variation.stock.toString());
      final price = TextEditingController(text: variation.price.toString());
      final salePrice = TextEditingController(
        text: variation.salePrice.toString(),
      );
      final description = TextEditingController(
        text: variation.description ?? '',
      );

      // إضافة الخرائط (Maps) للقوائم كما يتوقع الـ UI الخاص بك
      stockControllerList.add({variation: stock});
      priceControllerList.add({variation: price});
      salePriceControllerList.add({variation: salePrice});
      descriptionControllerList.add({variation: description});

      // إذا كان هناك صورة للمتغير، نحدث الـ ImageController الخاص بالمتغيرات
      if (variation.image != null && variation.image!.isNotEmpty) {
        Get.find<ProductVariationImageController>().variationImageUrls[variation
                .id!] =
            variation.image!;
      }
    }
  }

  void applyPriceToAll(String price) {
    double? p = double.tryParse(price);
    if (p == null) return;
    for (var map in priceControllerList) {
      map.values.first.text = price; // تحديث الحقل النصي في UI
      map.keys.first.price = p; // تحديث الموديل
    }
  }

  void applyStockToAll(String stock) {
    int? s = int.tryParse(stock);
    if (s == null) return;
    for (var map in stockControllerList) {
      map.values.first.text = stock;
      map.keys.first.stock = s;
    }
  }
}

*/














/*
class ProductVariationController extends GetxController {
  static ProductVariationController get instance => Get.find();

  final isLoading = false.obs;
  final RxList<ProductVariationModel> productVariation =
      <ProductVariationModel>[].obs;

  List<Map<ProductVariationModel, TextEditingController>> stockControllerList =
      [];
  List<Map<ProductVariationModel, TextEditingController>> priceControllerList =
      [];
  List<Map<ProductVariationModel, TextEditingController>>
  salePriceControllerList = [];
  List<Map<ProductVariationModel, TextEditingController>>
  descriptionControllerList = [];

  final attributesController = Get.put(ProductAttributesController());

  void intializaVariationControllers(List<ProductVariationModel> variation) {
    stockControllerList.clear();
    priceControllerList.clear();
    salePriceControllerList.clear();
    descriptionControllerList.clear();
  }

  void removeVariations(BuildContext context) {
    TDialogs.defaultDialog(
      context: context,
      title: "إزالة",
      onConfirm: () {
        productVariation.value = [];
        resetsAllValues();
        Navigator.of(context).pop();
      },
    );
  }

  void resetsAllValues() {
    productVariation.clear();
    stockControllerList.clear();
    priceControllerList.clear();
    salePriceControllerList.clear();
    descriptionControllerList.clear();
  }

  void generateVariationConfirmation(BuildContext context) {
    TDialogs.defaultDialog(
      context: context,
      confirmText: "توليد",
      title: "توليد الخصائص",
      content:
          "بمجرد توليد الخصائص سيتم تهيئة القائمة بالكامل، تأكد من إضافة كل الخيارات المرغوبة أولاً.",
      onConfirm: () => generateVariationFromAttributes(),
    );
  }

  void generateVariationFromAttributes() {
    Get.back(); // إغلاق الديالوج
    resetsAllValues(); // مسح القديم لضمان عدم حدوث تداخل
    final List<ProductVariationModel> variations = [];

    if (attributesController.productAttributes.isNotEmpty) {
      final List<List<String>> attributCombination = getCombinations(
        attributesController.productAttributes
            .map((element) => element.values ?? <String>[])
            .toList(),
      );

      for (final combintion in attributCombination) {
        final Map<String, String> attributeValue = Map.fromIterables(
          attributesController.productAttributes.map(
            (element) => element.name ?? "",
          ),
          combintion,
        );

        // إنشاء المعرف الفريد والمستقر
        final variation = ProductVariationModel(
          id: attributeValue.values.join('-'),
          attributeValues: attributeValue,
        );

        variations.add(variation);

        // تجهيز وحدات التحكم للنصوص (Controllers)
        final Map<ProductVariationModel, TextEditingController>
        stockControllers = {};
        final Map<ProductVariationModel, TextEditingController>
        priceControllers = {};
        final Map<ProductVariationModel, TextEditingController>
        salePriceControllers = {};
        final Map<ProductVariationModel, TextEditingController>
        sdescriptionControllers = {};

        stockControllers[variation] = TextEditingController();
        priceControllers[variation] = TextEditingController();
        salePriceControllers[variation] = TextEditingController();
        sdescriptionControllers[variation] = TextEditingController();

        stockControllerList.add(stockControllers);
        priceControllerList.add(priceControllers);
        salePriceControllerList.add(salePriceControllers);
        descriptionControllerList.add(sdescriptionControllers);
      }
    }

    productVariation.assignAll(variations);
  }

  List<List<String>> getCombinations(List<List<String>> lists) {
    final List<List<String>> result = [];
    combine(lists, 0, <String>[], result);
    return result;
  }

  void combine(
    List<List<String>> lists,
    int index,
    List<String> current,
    List<List<String>> result,
  ) {
    if (index == lists.length) {
      result.add(List.from(current));
      return;
    }
    for (final item in lists[index]) {
      final List<String> updated = List.from(current)..add(item);
      combine(lists, index + 1, updated, result);
    }
  }

  void initExistingVariations(List<ProductVariationModel> variations) {
    resetsAllValues();

    for (var variation in variations) {
      productVariation.add(variation);

      final stock = TextEditingController(text: variation.stock.toString());
      final price = TextEditingController(text: variation.price.toString());
      final salePrice = TextEditingController(
        text: variation.salePrice.toString(),
      );
      final description = TextEditingController(
        text: variation.description ?? '',
      );

      stockControllerList.add({variation: stock});
      priceControllerList.add({variation: price});
      salePriceControllerList.add({variation: salePrice});
      descriptionControllerList.add({variation: description});

      if (variation.image != null && variation.image!.isNotEmpty) {
        Get.find<ProductVariationImageController>().variationImageUrls[variation
                .id] =
            variation.image!;
      }
    }
  }
}
*/















