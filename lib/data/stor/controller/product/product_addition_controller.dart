import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_attributes_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_image_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_variation_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_variation_image_controller.dart';
import 'package:stors_admin_panel/data/stor/models/brand_model.dart';
import 'package:stors_admin_panel/data/stor/models/category_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_attribute_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';
import 'package:stors_admin_panel/data/reposity/product/product_repository.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

/// ProductAdditionController - Controller لإدارة عملية إضافة المنتج
/// يدير جميع بيانات المنتج ويوفر validation شامل وتتبع التغييرات
class ProductAdditionController extends GetxController {
  static ProductAdditionController get instance => Get.find();

  final productRepository = Get.put(ProductRepository());
  final productImage = Get.put(ProductImageController());
  final p = Get.put(() => ProductAttributesController());
  final pv = Get.put(() => ProductVariationController());
  final pvi = Get.put(() => ProductVariationImageController());

  Rx<ProductType> productType = ProductType.single.obs;
  RxBool isEditing = false.obs; // لمعرفة حالة الصفحة
  RxDouble uploadProgress = 0.0.obs;

  // ==================== FORM KEYS ====================
  /// مفاتيح النماذج للتحقق من صحة البيانات في كل قسم
  final GlobalKey<FormState> basicInfoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> pricingFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> attributesFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> variationsFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> categoryFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> imagesFormKey = GlobalKey<FormState>();

  // ==================== REACTIVE STATE ====================
  /// النموذج الرئيسي للمنتج - يتم تحديثه reactively
  final Rx<ProductModel> product = ProductModel.empty().obs;
  String? editingProductId; // لتخزين ID المنتج أثناء التعديل

  /// حالة التحميل للعمليات المختلفة
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  final productVisibility = ProductVisibility.published.obs;

  /// تتبع اكتمال الأقسام المختلفة
  final RxBool isBasicInfoComplete = false.obs;
  final RxBool isPricingComplete = false.obs;
  final RxBool isAttributesComplete = false.obs;
  final RxBool isVariationsComplete = false.obs;
  final RxBool isCategoryComplete = false.obs;
  final RxBool isImagesComplete = false.obs;

  // ==================== TEXT CONTROLLERS ====================
  /// Controllers للحقول النصية لتسهيل التحديث والتحقق
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController salePriceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();

  // ==================== DATA LISTS ====================
  /// قوائم البيانات المساعدة (في التطبيق الحقيقي ستأتي من API)
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<BrandModel> brands = <BrandModel>[].obs;
  final RxList<String> tags = <String>[].obs;

  // ==================== SELECTION STATE ====================
  /// حالة الاختيار للفئات والعلامات التجارية
  final Rx<CategoryModel?> selectedCategory = Rx<CategoryModel?>(null);
  final Rx<BrandModel?> selectedBrand = Rx<BrandModel?>(null);

  // ==================== IMAGES STATE ====================
  /// إدارة الصور عبر ProductImageController
  ProductImageController get imageController => ProductImageController.instance;

  // Getters للوصول إلى بيانات الصور
  Rx<String?> get mainImageUrl => imageController.mainImageUrl;
  RxList<String> get productImages => imageController.additionalImageUrls;
  RxBool get mainImageLoading => imageController.mainImageLoading;
  RxList<bool> get additionalImageLoading =>
      imageController.additionalImageLoading;

  void printData() {
    debugPrint(
      "المعلومات الاساسية "
      "${product.value.toJson()}"
      "الأتربيوت "
      "${product.value.productAttribute![0].toJson()}:"
      "المتغيرات "
      "${product.value.productVariation![0].toJson()}"
      "المتغيرات "
      "${product.value.images.toString()}",
    );
  }

  @override
  void onInit() {
    super.onInit();
    // فحص ما إذا كان هناك منتج ممرر عبر الـ Arguments (من صفحة العرض مثلاً)
    if (Get.arguments is ProductModel) {
      isEditing.value = true;
      final ProductModel existingProduct = Get.arguments;
      _loadExistingProductData(existingProduct);
    } else {
      _initializeData();
    }
    _setupReactiveListeners();
  }

  @override
  void onReady() {
    super.onReady();
    _loadReferenceData(); // استدعاء البيانات هنا أضمن للـ Snackbars
  }

  @override
  void onClose() {
    // تنظيف Controllers عند إغلاق الـ Controller
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    salePriceController.dispose();
    stockController.dispose();
    skuController.dispose();
    tagsController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  /// تهيئة البيانات الأولية
  void _initializeData() {
    // إنشاء منتج فارغ مع القيم الافتراضية
    product.value = ProductModel(
      id: '',
      storId: '', // سيتم تعيينه من المتجر الحالي
      title: '',
      stock: 0,
      price: 0.0,
      thumbnail: '',
      productType: ProductType.single.name,
      salePrice: 0.0,
      description: '',
      images: [],
      productAttribute: [],
      productVariation: [],
    );

    // ربط Controllers بالقيم الأولية
    titleController.text = product.value.title;
    descriptionController.text = product.value.description ?? '';
    priceController.text = product.value.price.toString();
    salePriceController.text = product.value.salePrice.toString();
    stockController.text = product.value.stock.toString();
    skuController.text = product.value.sku ?? '';
  }

  /// إعداد المستمعين للتغييرات التفاعلية
  void _setupReactiveListeners() {
    // مراقبة تغييرات العنوان والوصف للتحقق من اكتمال البيانات الأساسية
    ever(product, (ProductModel prod) {
      isBasicInfoComplete.value = _validateBasicInfo();
      isPricingComplete.value = _validatePricing();
      isAttributesComplete.value = _validateAttributes();
      isVariationsComplete.value = _validateVariations();
      isCategoryComplete.value = _validateCategory();
      // isImagesComplete.value = _validateImages();
    });

    // مراقبة تغييرات Controllers لتحديث النموذج
    titleController.addListener(() => updateTitle(titleController.text));
    descriptionController.addListener(
      () => updateDescription(descriptionController.text),
    );
    priceController.addListener(
      () => updatePrice(double.tryParse(priceController.text) ?? 0.0),
    );
    salePriceController.addListener(
      () => updateSalePrice(double.tryParse(salePriceController.text) ?? 0.0),
    );
    stockController.addListener(
      () => updateStock(int.tryParse(stockController.text) ?? 0),
    );
    skuController.addListener(() => updateSku(skuController.text));
  }

  /// هذه الدالة تستدعيها عند فتح واجهة التعديل فقط
  void setProductForEditing(ProductModel existingProduct) {
    final proType = existingProduct.productType == ProductType.variable.name
        ? ProductType.variable
        : ProductType.single;
    isEditing.value = true;
    editingProductId = existingProduct.id;
    product.value = existingProduct;
    productType.value = proType;

    // تعبئة الكنترولرات بالبيانات الحالية
    titleController.text = existingProduct.title;
    descriptionController.text = existingProduct.description ?? '';
    priceController.text = existingProduct.price.toString();
    salePriceController.text = existingProduct.salePrice > 0
        ? existingProduct.salePrice.toString()
        : '';
    stockController.text = existingProduct.stock.toString();
    skuController.text = existingProduct.sku ?? '';

    // تعبئة الخصائص
    // إضافة استدعاء كونتولر الخصائص
    final attributesController = Get.put(ProductAttributesController());
    final variationsController = Get.put(ProductVariationController());

    // التعديل هنا: نمرر الخصائص والمتغيرات معاً ليستخرج منها الصور
    attributesController.loadExistingAttributes(
      existingProduct.productAttribute ?? [],
      existingProduct.productVariation ?? [], // تمرير المتغيرات هنا مهم جداً!
    );
    // تعبئة كونتولر المتغيرات
    variationsController.productVariation.assignAll(
      existingProduct.productVariation ?? [],
    );
    variationsController.loadExistingVariations(
      existingProduct.productVariation ?? [],
    );

    // 1. تهيئة التصنيف المختار
    if (existingProduct.categoryId != null &&
        existingProduct.categoryId!.isNotEmpty) {
      // البحث عن كائن التصنيف بالاعتماد على الـ ID المخزن في المنتج
      final category = categories.firstWhereOrNull(
        (cat) => cat.id == existingProduct.categoryId,
      );
      if (category != null) {
        selectedCategory.value = category;
      }
    }

    // 2. تهيئة التاغات (Tags)
    if (existingProduct.tags != null && existingProduct.tags!.isNotEmpty) {
      tags.assignAll(existingProduct.tags!);

      // تحديث نص الـ Controller ليظهر التاغات مفصولة بفاصلة في حقل الإدخال
      tagsController.text = existingProduct.tags!.join(', ');
    }

    productVisibility.value = existingProduct.productVisibility;
    // ملاحظة: Obx في الواجهة سيقوم بتحديث عداد الحروف والتحقق فوراً

    mainImageUrl.value = existingProduct.thumbnail;
    productImages.assignAll(existingProduct.images ?? []);
  }

  /// تحميل البيانات المرجعية (الفئات، العلامات التجارية)
  void _loadReferenceData() {
    // بيانات تجريبية - في التطبيق الحقيقي ستأتي من API

    //getFeaturedBrands();
    fetchCategories();
  }

  Future<void> getFeaturedBrands() async {
    try {
      isLoading.value = true;
      final brand = await productRepository.getAllBrands();
      brands.assignAll(brand);
    } catch (e) {
      TLoaders.errorSnackBar(title: "Oh Snap!", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;

      final categoris = await productRepository.getAllCategories();
      categories.assignAll(categoris);
    } catch (e) {
      TLoaders.errorSnackBar(title: "On Snap!", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== BASIC INFO MANAGEMENT ====================

  /// تحديث عنوان المنتج
  void updateTitle(String title) {
    product.update((val) => val?.title = title);
  }

  /// تحديث وصف المنتج
  void updateDescription(String description) {
    product.update((val) => val?.description = description);
  }

  /// التحقق من صحة البيانات الأساسية
  bool _validateBasicInfo() {
    return product.value.title.isNotEmpty &&
        product.value.title.length >= 3 &&
        (product.value.description?.isNotEmpty == true) &&
        (product.value.description?.length ?? 0) >= 10;
  }

  // ==================== PRODUCT TYPE MANAGEMENT ====================

  /// تحديث نوع المنتج (مفرد/متغير)
  void updateProductType(ProductType type) {
    product.update((val) {
      val?.productType = type.name;
      // مسح المتغيرات إذا تم التغيير إلى مفرد
      if (type == ProductType.single) {
        val?.productVariation = [];
      }
    });
  }

  /// الحصول على نوع المنتج الحالي
  ProductType get currentProductType {
    return ProductType.values.firstWhere(
      (type) => type.name == product.value.productType,
      orElse: () => ProductType.single,
    );
  }

  // ==================== PRICING MANAGEMENT ====================

  /// تحديث السعر الأساسي
  void updatePrice(double price) {
    product.update((val) => val?.price = price);
  }

  /// تحديث سعر البيع
  void updateSalePrice(double salePrice) {
    product.update((val) => val?.salePrice = salePrice);
  }

  /// تحديث المخزون
  void updateStock(int stock) {
    product.update((val) => val?.stock = stock);
  }

  /// تحديث SKU
  void updateSku(String sku) {
    product.update((val) => val?.sku = sku);
  }

  /// التحقق من صحة بيانات التسعير (للمنتجات المفردة فقط)
  bool _validatePricing() {
    if (currentProductType == ProductType.variable) return true;
    return product.value.price > 0 && product.value.stock >= 0;
  }

  // ==================== ATTRIBUTES MANAGEMENT ====================

  /// إضافة خاصية جديدة
  void addAttribute() {
    final attributes = List<ProductAttributeModel>.from(
      product.value.productAttribute ?? [],
    );
    attributes.add(ProductAttributeModel(name: '', values: []));
    product.update((val) => val?.productAttribute = attributes);
  }

  /// تحديث خاصية موجودة
  void updateAttribute(int index, {String? name, List<String>? values}) {
    final attributes = List<ProductAttributeModel>.from(
      product.value.productAttribute ?? [],
    );
    if (index >= 0 && index < attributes.length) {
      attributes[index] = ProductAttributeModel(
        name: name ?? attributes[index].name,
        values: values ?? attributes[index].values,
      );
      product.update((val) => val?.productAttribute = attributes);
    }
  }

  /// حذف خاصية
  void removeAttribute(int index) {
    final attributes = List<ProductAttributeModel>.from(
      product.value.productAttribute ?? [],
    );
    if (index >= 0 && index < attributes.length) {
      attributes.removeAt(index);
      product.update((val) => val?.productAttribute = attributes);
    }
  }

  /// إضافة قيمة لخاصية
  void addAttributeValue(int attributeIndex, String value) {
    final attributes = List<ProductAttributeModel>.from(
      product.value.productAttribute ?? [],
    );
    if (attributeIndex >= 0 && attributeIndex < attributes.length) {
      final currentValues = List<String>.from(
        attributes[attributeIndex].values ?? [],
      );
      currentValues.add(value);
      updateAttribute(attributeIndex, values: currentValues);
    }
  }

  /// حذف قيمة من خاصية
  void removeAttributeValue(int attributeIndex, String value) {
    final attributes = List<ProductAttributeModel>.from(
      product.value.productAttribute ?? [],
    );
    if (attributeIndex >= 0 && attributeIndex < attributes.length) {
      final currentValues = List<String>.from(
        attributes[attributeIndex].values ?? [],
      );
      currentValues.remove(value);
      updateAttribute(attributeIndex, values: currentValues);
    }
  }

  /// التحقق من صحة الخصائص
  bool _validateAttributes() {
    if (currentProductType == ProductType.variable) return true;
    final attributes = product.value.productAttribute ?? [];
    return attributes.isNotEmpty &&
        attributes.every(
          (attr) =>
              attr.name?.isNotEmpty == true &&
              (attr.values?.isNotEmpty == true),
        );
  }

  // ==================== VARIATIONS MANAGEMENT ====================

  /// إضافة متغير جديد
  void addVariation() {
    final variations = List<ProductVariationModel>.from(
      product.value.productVariation ?? [],
    );
    variations.add(
      ProductVariationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        attributeValues: {},
        sku: '',
        image: '',
        description: '',
        price: 0.0,
        salePrice: 0.0,
        stock: 0,
      ),
    );
    product.update((val) => val?.productVariation = variations);
  }

  /// تحديث متغير موجود
  void updateVariation(int index, ProductVariationModel variation) {
    final variations = List<ProductVariationModel>.from(
      product.value.productVariation ?? [],
    );
    if (index >= 0 && index < variations.length) {
      variations[index] = variation;
      product.update((val) => val?.productVariation = variations);
    }
  }

  /// حذف متغير
  void removeVariation(int index) {
    final variations = List<ProductVariationModel>.from(
      product.value.productVariation ?? [],
    );
    if (index >= 0 && index < variations.length) {
      variations.removeAt(index);
      product.update((val) => val?.productVariation = variations);
    }
  }

  /// التحقق من صحة المتغيرات
  bool _validateVariations() {
    if (currentProductType == ProductType.single) return true;
    final variations = product.value.productVariation ?? [];
    return variations.isNotEmpty &&
        variations.every(
          (variation) =>
              variation.price > 0 &&
              variation.stock >= 0 &&
              variation.attributeValues.isNotEmpty,
        );
  }

  // ==================== CATEGORY & BRAND MANAGEMENT ====================

  /// تحديث الفئة المحددة
  void updateCategory(CategoryModel category) {
    selectedCategory.value = category;
    product.update((val) => val?.categoryId = category.id);
  }

  /// تحديث العلامة التجارية المحددة
  void updateBrand(BrandModel? brand) {
    selectedBrand.value = brand;
    product.update((val) => val?.brande = brand);
  }

  /// تحديث العلامات
  void updateTags(String tagsString) {
    final tagList = tagsString
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    tags.assignAll(tagList);
    product.update((val) => val?.tags = tagList);
  }

  /// إضافة علامة
  void addTag(String tag) {
    if (tag.isNotEmpty && !tags.contains(tag)) {
      tags.add(tag);
    }
  }

  /// حذف علامة
  void removeTag(String tag) {
    tags.remove(tag);
  }

  /// التحقق من صحة الفئة والعلامة التجارية
  bool _validateCategory() {
    return selectedCategory.value != null;
  }

  // ==================== IMAGES MANAGEMENT ====================

  /// تعيين الصورة الرئيسية
  void setMainImage(String imageUrl) {
    mainImageUrl.value = imageUrl;
    product.update((val) => val?.thumbnail = imageUrl);
  }

  // ==================== IMAGE MANAGEMENT ====================

  /// اختيار الصورة الرئيسية
  Future<void> selectMainImage(BuildContext context) async {
    await imageController.selectMainImage(context);
    _updateImagesValidation();
  }

  /// اختيار الصورة الرئيسية من المعرض
  Future<void> selectMainImageFromGallery() async {
    await imageController.selectMainImageFromGallery();
    _updateImagesValidation();
  }

  /// حذف الصورة الرئيسية
  void removeMainImage() {
    imageController.removeMainImage();
    product.update((val) => val?.thumbnail = '');
    _updateImagesValidation();
  }

  /// إضافة صور إضافية
  Future<void> addAdditionalImages(BuildContext context) async {
    await imageController.addAdditionalImages(context);
    _updateImagesValidation();
  }

  /// إضافة صورة إضافية من المعرض
  Future<void> addAdditionalImageFromGallery() async {
    await imageController.addAdditionalImageFromGallery();
    _updateImagesValidation();
  }

  /// حذف صورة إضافية
  void removeProductImage(int index) {
    imageController.removeAdditionalImage(index);
    _updateImagesValidation();
  }

  /// تعيين صورة إضافية كرئيسية
  void setAsMainImage(int index) {
    imageController.setAsMainImage(index);
    _updateImagesValidation();
  }

  /// تحديث حالة صحة الصور
  void _updateImagesValidation() {
    final hasMainImage =
        imageController.getMainImageUrl() != null ||
        imageController.getMainImageBytes() != null;
    final hasAdditionalImages =
        imageController.getAdditionalImageUrls().isNotEmpty ||
        imageController.getAdditionalImageBytes().isNotEmpty;

    isImagesComplete.value = hasMainImage || hasAdditionalImages;
  }

  // ==================== FORM VALIDATION ====================

  /// التحقق من صحة النموذج بالكامل
  bool get isFormValid {
    // التحقق من البيانات الأساسية
    final hasBasicInfo =
        product.value.title.isNotEmpty &&
        (product.value.description?.isNotEmpty == true);

    // التحقق من الصور (يجب وجود صورة رئيسية على الأقل)
    final hasMainImage =
        imageController.getMainImageUrl() != null ||
        imageController.getMainImageBytes() != null;

    // التحقق من الفئة
    final hasCategory = product.value.categoryId?.isNotEmpty == true;

    // التحقق من التسعير
    final hasPricing = currentProductType == ProductType.single
        ? (product.value.price > 0 && product.value.stock >= 0)
        : true; // للمتغيرات، يتم التحقق من كل متغير على حدة

    return hasBasicInfo && hasMainImage && hasCategory && hasPricing;
  }

  /// التحقق من صحة العنوان
  String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'العنوان مطلوب';
    }
    if (value.length < 3) {
      return 'العنوان يجب أن يكون 3 أحرف على الأقل';
    }
    if (value.length > 100) {
      return 'العنوان يجب أن يكون أقل من 100 حرف';
    }
    return null;
  }

  /// التحقق من صحة الوصف
  String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'الوصف مطلوب';
    }
    if (value.length < 10) {
      return 'الوصف يجب أن يكون 10 أحرف على الأقل';
    }
    if (value.length > 1000) {
      return 'الوصف يجب أن يكون أقل من 1000 حرف';
    }
    return null;
  }

  // ==================== SAVE OPERATIONS ====================

  /// مزامنة البيانات من الcontrollers الجديدة
  void _syncDataFromControllers() {
    try {
      // مزامنة الأتربيوت
      final attributesController = Get.find<ProductAttributesController>();
      product.update((val) {
        val?.productAttribute = attributesController.productAttributes.toList();
      });

      // مزامنة المتغيرات
      final variationsController = Get.find<ProductVariationController>();
      product.update((val) {
        val?.productVariation = variationsController.productVariation.toList();
      });
    } catch (e) {
      // في حالة عدم وجود الcontrollers، لا نفعل شيئاً
      debugPrint('Controllers not found: $e');
    }
  }

  /// الدالة الموحدة للحفظ
  Future<void> submitData() async {
    if (isEditing.value) {
      await updateProduct(); // دالة التعديل
    } else {
      await saveProduct(); // دالة الإضافة الحالية
    }
  }

  Future<bool> saveProduct() async {
    try {
      isSaving.value = true;
      if (!isFormValid) {
        _showErrorSnackbar('يرجى ملء الحقول');
        return false;
      }

      _syncDataFromControllers();
      if (!_validateProductData()) return false;

      if (product.value.id.isEmpty) {
        product.update(
          (val) => val?.id = DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }

      // لا تستدعي pviController.uploadAllVariationImages هنا
      // لأن دالة uploadDummyData تقوم بذلك بالفعل بالداخل (كما رأيت في الكود الذي أرفقته)

      // فقط استدعي الدالة الشاملة
      product.value.tags = tags;
      await productRepository.uploadDummyData(product.value);

      imageController.clearAllImages();
      resetForm();
      return true;
    } catch (e) {
      _showErrorSnackbar('خطأ: ${e.toString()}');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateProduct() async {
    try {
      isSaving.value = true;
      if (!isFormValid) {
        _showErrorSnackbar('يرجى ملء الحقول');
        return false;
      }

      _syncDataFromControllers();
      if (!_validateProductData()) return false;

      if (product.value.id.isEmpty) {
        product.update(
          (val) => val?.id = DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }

      // لا تستدعي pviController.uploadAllVariationImages هنا
      // لأن دالة uploadDummyData تقوم بذلك بالفعل بالداخل (كما رأيت في الكود الذي أرفقته)

      // فقط استدعي الدالة الشاملة
      //await productRepository.uploadDummyData(product.value);

      imageController.clearAllImages();
      resetForm();
      _showSuccessSnackbar('تم حفظ تعديل المنتج بنجاح');
      return true;
    } catch (e) {
      _showErrorSnackbar('خطأ: ${e.toString()}');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // دالة مساعدة للتحقق من البيانات (لتنظيف الكود)
  bool _validateProductData() {
    if (currentProductType == ProductType.single && product.value.price <= 0) {
      _showErrorSnackbar('السعر يجب أن يكون أكبر من 0');
      return false;
    }
    if (currentProductType == ProductType.variable) {
      final variations = product.value.productVariation ?? [];
      if (variations.isEmpty) {
        _showErrorSnackbar('يجب إضافة متغير واحد على الأقل');
        return false;
      }
      for (var v in variations) {
        if (v.price <= 0 || v.stock < 0) {
          _showErrorSnackbar('تحقق من السعر والمخزون في المتغيرات');
          return false;
        }
      }
    }
    return true;
  }

  // دالة لعرض رسائل الخطأ بشكل منسق
  void _showErrorSnackbar(String message) {
    TLoaders.errorSnackBar(title: "خطا", message: message);
  }

  // دالة لعرض رسائل النجاح
  void _showSuccessSnackbar(String message) {
    TLoaders.successSnackBar(title: "نجح", message: message);
  }

  /*
  /// حفظ المنتج
  Future<bool> saveProduct() async {
    debugPrint("DEBUG: Starting saveProduct...");
    try {
      isSaving.value = true;

      // 1. التحقق من الصحة الأساسية
      if (!isFormValid) {
        Get.snackbar(
          'خطأ',
          'يرجى ملء جميع الحقول المطلوبة',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // 2. تحديث البيانات من الcontrollers الأخرى
      _syncDataFromControllers();

      // 3. التحقق من أن product ID موجود
      /* if (product.value.id.isEmpty) {
        product.update(
          (val) => val?.id = DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }*/

      // 4. التحقق من التسعير للمنتجات المفردة
      if (currentProductType == ProductType.single) {
        if (product.value.price <= 0) {
          Get.snackbar(
            'خطأ',
            'السعر يجب أن يكون أكبر من 0',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
      }

      // 5. التحقق من المتغيرات (إذا كانت موجودة)
      if (currentProductType == ProductType.variable) {
        final variations = product.value.productVariation ?? [];
        if (variations.isEmpty) {
          Get.snackbar(
            'خطأ',
            'يجب إضافة متغير واحد على الأقل',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }

        for (var variation in variations) {
          if (variation.price <= 0 || variation.stock < 0) {
            Get.snackbar(
              'خطأ',
              'تحقق من السعر والمخزون في المتغيرات',
              snackPosition: SnackPosition.BOTTOM,
            );
            return false;
          }
        }
      }

      // 6. حفظ المنتج عبر ProductRepository
      if (product.value.id.isEmpty) {
        product.update(
          (val) => val?.id = DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }
      debugPrint("DEBUG: product.id before uploadDummyData = ${product.value.id}");
      debugPrint("DEBUG: Calling uploadDummyData...");
      await productRepository.uploadDummyData(product.value);

      // 7. تنظيف البيانات بعد النجاح
      imageController.clearAllImages();
      // pvi.clearAllImages(); // تنظيف صور المتغيرات
      resetForm();

      Get.snackbar(
        'نجح',
        'تم حفظ المنتج بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      debugPrint('Error saving product: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حفظ المنتج: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
*/
  // ==================== RESET OPERATIONS ====================

  /// إعادة تعيين جميع البيانات
  void resetForm() {
    // تنظيف صور الصور
    try {
      imageController.clearAllImages();
    } catch (e) {
      debugPrint('Error clearing images: $e');
    }

    // إعادة تعيين Controllers النصية
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    salePriceController.clear();
    stockController.clear();
    skuController.clear();
    tagsController.clear();

    // إعادة تعيين الحالة
    product.value = ProductModel.empty();
    selectedCategory.value = null;
    selectedBrand.value = null;
    tags.clear();

    // إعادة تعيين حالة الإكمال
    isBasicInfoComplete.value = false;
    isPricingComplete.value = false;
    isAttributesComplete.value = false;
    isVariationsComplete.value = false;
    isCategoryComplete.value = false;
    isImagesComplete.value = false;

    // إعادة تعيين مفاتيح النماذج
    try {
      basicInfoFormKey.currentState?.reset();
      pricingFormKey.currentState?.reset();
      attributesFormKey.currentState?.reset();
      variationsFormKey.currentState?.reset();
      categoryFormKey.currentState?.reset();
      imagesFormKey.currentState?.reset();
    } catch (e) {
      debugPrint('Error resetting form keys: $e');
    }

    _initializeData();
  }

  // ==================== UTILITY METHODS ====================

  /// الحصول على ملخص حالة الإكمال
  Map<String, bool> get completionStatus {
    return {
      'basicInfo': isBasicInfoComplete.value,
      'pricing': isPricingComplete.value,
      'attributes': isAttributesComplete.value,
      'variations': isVariationsComplete.value,
      'category': isCategoryComplete.value,
      'images': isImagesComplete.value,
    };
  }

  /// الحصول على عدد الأقسام المكتملة
  int getCompletedSectionsCount() {
    int count = 0;
    if (isBasicInfoComplete.value) count++;
    if (isPricingComplete.value) count++;
    if (isAttributesComplete.value) count++;
    if (isVariationsComplete.value) count++;
    if (isCategoryComplete.value) count++;
    if (isImagesComplete.value) count++;
    return count;
  }

  /// حفظ كمسودة
  Future<bool> saveDraft() async {
    try {
      isSaving.value = true;

      // محاكاة حفظ المسودة - في التطبيق الحقيقي سيتم الاتصال بـ API
      await Future.delayed(const Duration(seconds: 1));
      TLoaders.successSnackBar(
        title: 'تم الحفظ',
        message: 'تم حفظ المسودة بنجاح',
      );

      printData();

      return true;
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "خطأ",
        message: 'حدث خطأ أثناء حفظ المسودة: ${e.toString()}',
      );

      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// تعبئية الحقول في حال كان الوضع للتعديل
  void _loadExistingProductData(ProductModel existingProduct) {
    product.value = existingProduct;

    // تعبئة الحقول النصية
    titleController.text = existingProduct.title;
    descriptionController.text = existingProduct.description ?? '';
    priceController.text = existingProduct.price.toString();
    salePriceController.text = existingProduct.salePrice.toString();
    stockController.text = existingProduct.stock.toString();
    skuController.text = existingProduct.sku ?? '';

    // تعبئة الفئة والعلامة التجارية (تحتاج البحث عنها في القوائم المتاحة)
    // ملاحظة: قد تحتاج لانتظار تحميل القوائم أولاً في _loadReferenceData
    selectedBrand.value = existingProduct.brande;

    // تحديث الصور في الـ ImageController
    if (existingProduct.thumbnail.isNotEmpty) {
      imageController.mainImageUrl.value = existingProduct.thumbnail;
    }
    if (existingProduct.images != null) {
      imageController.additionalImageUrls.assignAll(existingProduct.images!);
    }

    // تهيئة الخصائص
    Get.find<ProductAttributesController>().initExistingAttributes(
      existingProduct.productAttribute ?? [],
    );

    // تهيئة المتغيرات والـ Controllers الخاصة بها
    Get.find<ProductVariationController>().initExistingVariations(
      existingProduct.productVariation ?? [],
    );
  }

  ////////////////////////////

  // ==================== CLEANUP & RESET METHOD ====================

  /// دالة مركزية لتصفير جميع الكنترولرز والبيانات للعودة لحالة الإضافة النظيفة
  void clearAllControllersData() {
    // 1. إعادة تعيين حالات التحكم الأساسية
    isEditing.value = false;
    editingProductId = null;
    uploadProgress.value = 0.0;
    productType.value = ProductType.single.obs.value; // العودة للنوع الافتراضي
    productVisibility.value = ProductVisibility.published;

    // 2. تصفير الحقول النصية (دون عمل dispose لها لتبقى صالحة للاستخدام)
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    salePriceController.clear();
    stockController.clear();
    skuController.clear();
    tagsController.clear();

    // 3. تصفير مؤشرات اكتمال الأقسام
    isBasicInfoComplete.value = false;
    isPricingComplete.value = false;
    isAttributesComplete.value = false;
    isVariationsComplete.value = false;
    isCategoryComplete.value = false;
    isImagesComplete.value = false;

    // 4. تصفير القوائم وحالات الاختيار (التاغات والتصنيفات)
    tags.clear();
    selectedCategory.value = null;
    selectedBrand.value = null;

    // 5. تهيئة كائن المنتج ببيانات فارغة جديدة تماماً
    _initializeData();

    // 6. تصفير الكنترولرز الفرعية التابعة والمحقونة بالكامل
    try {
      if (Get.isRegistered<ProductImageController>()) {
        ProductImageController.instance.clearAllImages();
      }
      if (Get.isRegistered<ProductAttributesController>()) {
        Get.find<ProductAttributesController>().resetProductAttributes();
      }
      if (Get.isRegistered<ProductVariationController>()) {
        Get.find<ProductVariationController>().resetsAllValues();
      }
      if (Get.isRegistered<ProductVariationImageController>()) {
        Get.find<ProductVariationImageController>().resetController();
      }
    } catch (e) {
      debugPrint("Error resetting sub-controllers: $e");
    }

    debugPrint(
      "💡 [SUCCESS]: All product building controllers have been securely reset.",
    );
  }
}
