import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive/hive.dart';
import 'package:stors_admin_panel/common/widgets/dialog/TPriceUpdateDialog.dart';
import 'package:stors_admin_panel/data/reposity/product/product_repository.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/popups/full_screen_loader%20copy.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class AllProductsController extends GetxController {
  static AllProductsController get instance => Get.find();

  final repository =
      ProductRepository.instance; // استخدام الـ instance الموجود أصلاً
  final searchTextController = TextEditingController();
  final storage = GetStorage();

  RxList<ProductModel> products = <ProductModel>[].obs;
  RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  RxList<ProductModel> allFetchedProducts = <ProductModel>[].obs;

  RxBool isLoading = false.obs;
  RxBool isMoreLoading = false.obs;
  RxBool hasMoreData = true.obs;

  final int rowsPerPage = 20;
  final scrollController = ScrollController();
  var isScrollingDown = true.obs;
  double _lastScrollPosition = 0.0;
  final FocusNode searchFocusNode = FocusNode();
  // حالة تمدد الحقل (true يعني ممتد، false يعني طبيعي)
  var isSearchExpanded = false.obs;
  // إظهار زر الإزالة فقط عند وجود نص
  var showClearButton = false.obs;
  final _productBox = Hive.box<ProductModel>('local_products');

  @override
  void onInit() {
    // ربط مستمع التمرير
    scrollController.addListener(_scrollListener);

    // 1. تحميل الكاش أولاً
    loadLocalProducts();

    // 2. جلب البيانات الحديثة
    fetchProducts();

    // مراقبة التركيز (Focus) للتمدد والتقلص
    searchFocusNode.addListener(() {
      isSearchExpanded.value = searchFocusNode.hasFocus;
    });

    // مراقبة النص لإظهار/إخفاء زر الإزالة (X)
    searchTextController.addListener(() {
      showClearButton.value = searchTextController.text.isNotEmpty;
    });
  }

  // الدالة التي يتم استدعاؤها من TextFormField
  void searchOnChanged(String query) {
    // تحديث قيمة النص (المراقب سيلتقط التغيير ويبدأ الـ debounce)
    searchTextController.text = query;

    // إذا أردت فلترة "لحظية" من الكاش قبل وصول نتائج السيرفر (اختياري)
    searchProduct(query);
  }

  void _scrollListener() {
    double currentPosition = scrollController.position.pixels;

    // --- أولاً: تحديد اتجاه التمرير لضبط الأنيميشن ---
    if (currentPosition > _lastScrollPosition && currentPosition > 0) {
      // التمرير لأسفل (يظهر محتوى جديد)
      if (!isScrollingDown.value) isScrollingDown.value = true;
    } else if (currentPosition < _lastScrollPosition) {
      // التمرير لأعلى (عودة للمحتوى السابق)
      if (isScrollingDown.value) isScrollingDown.value = false;
    }

    // تحديث الموضع الأخير ليتم المقارنة به في المرة القادمة
    _lastScrollPosition = currentPosition;

    // --- ثانياً: منطقك الحالي لجلب المزيد من البيانات عند الوصول للـ 90% ---
    if (currentPosition >= scrollController.position.maxScrollExtent * 0.9) {
      if (!isLoading.value && !isMoreLoading.value && hasMoreData.value) {
        loadMoreProducts();
      }
    }
  }

  /*void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent * 0.9) {
      if (!isLoading.value && !isMoreLoading.value && hasMoreData.value) {
        loadMoreProducts();
      }
    }
  }*/

  // --- التخزين المحلي ---
  void loadLocalProducts() {
    // جلب البيانات مباشرة كـ Objects من Hive
    if (_productBox.isNotEmpty) {
      // Hive يعيد البيانات كـ Iterable، نحولها إلى List
      final List<ProductModel> localData = _productBox.values.toList();

      products.assignAll(localData);
      filteredProducts.assignAll(localData); // عرض الكاش فوراً للمستخدم
    }
  }

  Future<void> saveProductsLocally() async {
    // 1. تنظيف الكاش القديم (اختياري، لضمان تحديث البيانات)
    await _productBox.clear();

    // 2. نحفظ أول 50 منتج فقط للكاش لضمان السرعة
    // في Hive، يفضل الحفظ باستخدام putAll لتحسين الأداء
    final Map<int, ProductModel> productsToCache = {
      for (int i = 0; i < products.take(50).length; i++) i: products[i],
    };

    await _productBox.putAll(productsToCache);
  }

  /// دالة تفعيل البحث عند الضغط على زر (تم) أو أيقونة البحث
  void triggerSearch() {
    final query = searchTextController.text.trim();
    // استدعاء الفايربيز فقط عند الضغط الفعلي
    searchProductFromFirebase(query);
    searchFocusNode.unfocus(); // إغلاق الكيبورد والتقلص بعد البحث
  }

  /// دالة مسح النص وإعادة البيانات الأصلية
  void clearSearch() {
    searchTextController.clear();
    searchProductFromFirebase(""); // سيعيد القائمة الأصلية حسب دالتك السابقة
    searchFocusNode.unfocus();
  }

  @override
  void onClose() {
    searchTextController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  // use GetStoreg
  /*
  void loadLocalProducts() {
    List<dynamic>? storedProducts = storage.read<List<dynamic>>(
      'local_products',
    );
    if (storedProducts != null) {
      final localData = storedProducts
          .map((e) => ProductModel.fromJsonLocal(e))
          .toList();
      products.assignAll(localData);
      filteredProducts.assignAll(localData); // عرض الكاش فوراً
    }
  }

  void saveProductsLocally() {
    // نحفظ أول 50 منتج فقط للكاش لضمان السرعة وعدم استهلاك الذاكرة
    List<Map<String, dynamic>> productJson = products
        .take(50)
        .map((e) => e.toJsonLocal())
        .toList();
    storage.write('local_products', productJson);
  }
*/
  // --- جلب البيانات ---
  Future<void> fetchProducts() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      // إعادة ضبط المؤشر عند جلب البيانات لأول مرة
      repository.lastDocument = null;

      final fetchedProducts = await repository.getProducts(limit: rowsPerPage);

      if (fetchedProducts.length < rowsPerPage) {
        hasMoreData.value = false;
      }

      products.assignAll(fetchedProducts);
      allFetchedProducts.assignAll(fetchedProducts);
      filteredProducts.assignAll(fetchedProducts);
      // تحديث الكاش
      saveProductsLocally();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreProducts() async {
    if (isMoreLoading.value || !hasMoreData.value) return;

    try {
      isMoreLoading.value = true;
      final newProducts = await repository.getProducts(limit: rowsPerPage);

      if (newProducts.length < rowsPerPage) {
        hasMoreData.value = false;
      }

      products.addAll(newProducts);
      allFetchedProducts.addAll(newProducts);
      filteredProducts.addAll(newProducts);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    } finally {
      isMoreLoading.value = false;
    }
  }

  // دالة البحث من Firebase (المعدلة)
  Future<void> searchProductFromFirebase(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      // إذا مسح المستخدم البحث، نعود للقائمة الأصلية
      products.assignAll(allFetchedProducts);
      filteredProducts.assignAll(allFetchedProducts);
      hasMoreData.value = true;
      return;
    }

    try {
      isLoading.value = true;
      hasMoreData.value = false; // تعطيل التحميل التلقائي أثناء البحث

      // استدعاء المستودع
      final searchResult = await repository.searchProductsInFirestore(
        trimmedQuery,
      );

      products.assignAll(searchResult);
      filteredProducts.assignAll(searchResult);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ في البحث', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // --- البحث ---
  void searchProduct(String query) {
    if (query.isEmpty) {
      filteredProducts.assignAll(products);
    } else {
      filteredProducts.assignAll(
        products
            .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    }
  }

  /// دالة لحذف المنتج مع تأكيد من المستخدم
  Future<void> confirmAndDeleteProduct(ProductModel product) async {
    try {
      // 1. إظهار نافذة تأكيد (Dialog)
      Get.defaultDialog(
        title: 'حذف المنتج',
        middleText:
            'هل أنت متأكد من حذف "${product.title}"؟ لا يمكن التراجع عن هذه العملية.',
        backgroundColor: Colors.white,
        onConfirm: () async {
          // إغلاق النافذة لبدء عملية الحذف
          Get.back();

          await performDelete(product);
        },
        onCancel: () => Get.back(),
        confirmTextColor: Colors.white,
        textConfirm: 'حذف',
        textCancel: 'إلغاء',
        buttonColor: Colors.red,
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'عذراً', message: e.toString());
    }
  }

  /// تنفيذ عملية الحذف الفعلي وتحديث الواجهة
  Future<void> performDelete(ProductModel product) async {
    try {
      // إظهار مؤشر تحميل (Loading)
      TFullScreenLoader.openLoadingDialog(
        'جاري حذف المنتج...',
        TImages.docerAnimation,
      );

      // استدعاء المستودع
      await repository.deleteProduct(product.id, product.thumbnail);

      // تحديث القوائم المحلية فوراً (لإخفاء المنتج من الشاشة)
      products.removeWhere((p) => p.id == product.id);
      filteredProducts.removeWhere((p) => p.id == product.id);

      // تحديث الكاش المحلي
      saveProductsLocally();

      // إغلاق مؤشر التحميل
      TFullScreenLoader.stopLoading();

      // رسالة نجاح
      TLoaders.successSnackBar(
        title: 'تم بنجاح',
        message: 'تم حذف المنتج وصورته نهائياً.',
      );
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    }
  }

  /// دالة تغيير حالة الظهور (إظهار/إخفاء)
  Future<void> toggleProductVisibility(ProductModel product) async {
    try {
      // تغيير الحالة محلياً فوراً لتجربة مستخدم سريعة
      product.productVisibility =
          product.productVisibility == ProductVisibility.published
          ? ProductVisibility.hidden
          : ProductVisibility.published;
      update();

      await repository.updateProductVisibility(
        product.id,
        product.productVisibility,
      );

      TLoaders.successSnackBar(
        title: 'تم بنجاح',
        message: product.productVisibility == product.productVisibility
            ? 'المنتج ظاهر الآن للعملاء'
            : 'تم إخفاء المنتج',
      );
    } catch (e) {
      // إرجاع الحالة للأصل في حال الفشل
      product.productVisibility =
          product.productVisibility == ProductVisibility.published
          ? ProductVisibility.hidden
          : ProductVisibility.published;
      update();
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    }
  }

  /// دالة تحديث السعر مع فحص نوع المنتج
  Future<void> updatePriceWithLogic(
    ProductModel product,
    double newPrice,
  ) async {
    try {
      // 1. فحص إذا كان المنتج يحتوي على متغيرات (Variable Product)
      if (product.productType == ProductType.variable.toString() ||
          (product.productVariation?.isNotEmpty ?? false)) {
        // إظهار تنبيه للمستخدم
        Get.dialog(
          TPriceUpdateDialog(
            title: 'تنبيه المنتج المتغير',
            content:
                'هذا المنتج يحتوي على متغيرات (مثل مقاسات أو ألوان). هل تريد تطبيق السعر الجديد ($newPrice) على جميع هذه المتغيرات؟',
            confirmText: 'تطبيق على الكل',
            onConfirm: () async {
              Get.back(); // إغلاق الدايالوج
              await _executePriceUpdate(
                product,
                newPrice,
                updateVariations: true,
              );
            },
          ),
          barrierDismissible:
              false, // يمنع إغلاق الدايلوج عند الضغط خارجه لضمان اتخاذ قرار
        );
      } else {
        // منتج بسيط (Simple Product)
        await _executePriceUpdate(product, newPrice, updateVariations: false);
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    }
  }

  /// التنفيذ الفعلي لتحديث السعر في قاعدة البيانات
  Future<void> _executePriceUpdate(
    ProductModel product,
    double newPrice, {
    required bool updateVariations,
  }) async {
    try {
      TFullScreenLoader.openLoadingDialog(
        'جاري تحديث السعر...',
        TImages.docerAnimation,
      );

      await repository.updateProductPrice(
        product.id,
        newPrice,
        variations: updateVariations ? product.productVariation : null,
      );

      // تحديث القائمة محلياً
      product.price = newPrice;
      if (updateVariations && product.productVariation != null) {
        for (var v in product.productVariation!) {
          v.price = newPrice;
        }
      }

      TFullScreenLoader.stopLoading();
      update(); // تحديث واجهة المستخدم
      TLoaders.successSnackBar(
        title: 'تم التحديث',
        message: 'تم تحديث سعر المنتج بنجاح',
      );
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'عذراً', message: e.toString());
    }
  }

  Future<void> refreshProducts() async {
    hasMoreData.value = true;
    products.clear();
    filteredProducts.clear();
    searchTextController.clear();
    await fetchProducts();
  }
}






/*
class AllProductsController extends GetxController {
  static AllProductsController get instance => Get.find();

  final repository = Get.put(ProductRepository());
  final searchTextController = TextEditingController();
  final storage = GetStorage();
  RxList<ProductModel> products = <ProductModel>[].obs;
  RxList<ProductModel> filteredProducts =
      <ProductModel>[].obs; // للقائمة المفلترة
  RxList<ProductModel> allFetchedProducts = <ProductModel>[].obs;
  RxBool isLoading = false.obs;
  final int rowsPerPage = 20;

  final scrollController = ScrollController();
  var isMoreLoading = false.obs; // لمؤشر التحميل السفلي
  var hasMoreData = true.obs; // للتوقف عند جلب كل البيانات
  int pageSize = 20; // حجم الدفعة

  @override
  void onInit() {
    // 1. تحميل الكاش أولاً (سرعة خارقة في العرض)
    loadLocalProducts();

    // 2. جلب البيانات الحديثة من Firebase في الخلفية
    fetchProducts();
    super.onInit();
  }

  /*@override
  void onInit() {
    scrollController.addListener(_scrollListener);
    fetchProducts();

    // تحسين: البحث التلقائي بعد توقف المستخدم عن الكتابة بـ 500ms
    // هذا يمنع إرسال طلبات للفيربيز مع كل حرف يكتبه المستخدم
    debounce(isLoading, (_) {}, time: const Duration(milliseconds: 500));
    super.onInit();
  }*/

  void _scrollListener() {
    // إذا وصل المستخدم إلى 90% من طول القائمة ولم يكن هناك تحميل حالي
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent * 0.9) {
      if (!isLoading.value && !isMoreLoading.value && hasMoreData.value) {
        loadMoreProducts();
      }
    }
  }

  Future<void> loadMoreProducts() async {
    try {
      isMoreLoading.value = true;

      // جلب الدفعة التالية من المستودع
      // ملاحظة: مرر آخر منتج تم جلبه للمستودع ليبدأ الجلب من بعده (StartAfter)
      final newProducts = await ProductRepository.instance.getProducts(
        limit: pageSize,
      );
      /*.getProductsWithPagination(
            limit: pageSize,
            lastDoc: products
                .last
                .documentSnapshot, // تأكد من تخزين السناب شوت في المودل
          );*/

      if (newProducts.length < pageSize) {
        hasMoreData.value = false; // لا توجد بيانات إضافية
      }

      products.addAll(newProducts);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    } finally {
      isMoreLoading.value = false;
    }
  }

  // قراءة المنتجات من الذاكرة المحلية
  void loadLocalProducts() {
    List<dynamic>? storedProducts = storage.read<List<dynamic>>(
      'local_products',
    );
    if (storedProducts != null) {
      products.assignAll(
        storedProducts.map((e) => ProductModel.fromJsonLocal(e)).toList(),
      );
    }
  }

  // حفظ المنتجات في الذاكرة المحلية
  void saveProductsLocally() {
    List<Map<String, dynamic>> productJson = products
        .map((e) => e.toJsonLocal())
        .toList();
    storage.write('local_products', productJson);
  }

  Future<void> fetchProducts() async {
    if (isLoading.value || !hasMoreData.value) return;
    try {
      isLoading.value = true;
      final fetchedProducts = await repository.getProducts(limit: rowsPerPage);

      if (fetchedProducts.length < rowsPerPage) {
        hasMoreData.value = false;
      }

      products.addAll(fetchedProducts);
      allFetchedProducts.addAll(
        fetchedProducts,
      ); // حفظ نسخة للعودة إليها بعد مسح البحث
      // تحديث الفلترة تلقائياً عند جلب بيانات جديدة
      if (fetchedProducts.isNotEmpty) {
        // تحديث الكاش المحلي بعد الجلب الناجح
        saveProductsLocally();
      }
      searchProduct(searchTextController.text);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // --- دالة البحث من Firebase ---
  Future<void> searchProductFromFirebase(String query) async {
    try {
      // إذا كان الاستعلام فارغاً، نعود لعرض المنتجات الأصلية
      if (query.isEmpty) {
        products.assignAll(allFetchedProducts);
        hasMoreData.value = true; // إعادة تفعيل جلب المزيد
        return;
      }

      isLoading.value = true;
      hasMoreData.value =
          false; // نعطل التحميل الإضافي أثناء البحث لعدم خلط البيانات

      // استدعاء المستودع للبحث (يجب إضافة هذه الدالة في ProductRepository)
      final searchResult = await repository.searchProductsInFirestore(query);

      products.assignAll(searchResult);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void searchProduct(String query) {
    if (query.isEmpty) {
      filteredProducts.assignAll(products);
    } else {
      filteredProducts.assignAll(
        products
            .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    }
  }

  Future<void> fetchPage(int pageIndex) async {
    int startIndex = pageIndex * rowsPerPage;
    // نجلب المزيد إذا اقتربنا من نهاية القائمة الحالية ولم نصل لنهاية السيرفر
    if (startIndex + rowsPerPage >= products.length && hasMoreData.value) {
      await fetchProducts();
    }
  }

  Future<void> refreshProducts() async {
    repository.lastDocument = null;
    hasMoreData.value = true;
    products.clear();
    filteredProducts.clear();
    searchTextController.clear();
    await fetchProducts();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
*/