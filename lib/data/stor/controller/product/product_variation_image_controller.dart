import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class ProductVariationImageController extends GetxController {
  static ProductVariationImageController get instance => Get.find();

  // خريطة لتخزين الروابط المرفوعة مسبقاً: المفتاح هو الـ Hash والقيمة هي الـ URL لمنع التكرار
  final Map<String, String> _uploadedImagesCache = {};

  final RxMap<String, Uint8List> variationImageBytes =
      <String, Uint8List>{}.obs;
  final RxMap<String, DropzoneViewController?> dropzoneControllers =
      <String, DropzoneViewController?>{}.obs;

  final ImagePicker imagePicker = ImagePicker();

  // 🌟 الخرائط الاحترافية الجديدة لإدارة الحالة
  // خريطة تربط معرف الفاريشن ببصمة الصورة الفريدة (الحشوة)
  final RxMap<String, String> variationImageHashes = <String, String>{}.obs;

  // خريطة تحمل وعود الضغط في الخلفية مفهرسة ببصمة الصورة (لتجنب تكرار ضغط نفس الصورة)
  final Map<String, Future<Uint8List>> compressionTasks = {};

  // خريطة الروابط النهائية المسترجعة من الفايربيس
  final RxMap<String, String> variationImageUrls = <String, String>{}.obs;
  final RxMap<String, bool> variationImageLoading = <String, bool>{}.obs;

  // --- دالة حساب البصمة (Hash) ---
  String _calculateImageHash(Uint8List bytes) {
    return md5.convert(bytes).toString();
  }

  /// دالة توليد بصمة فريدة وسريعة جداً لمحتوى الصورة الخام لمنع التكرار
  String _generateImageHash(Uint8List bytes) {
    if (bytes.isEmpty) return "";

    // تحديد طول الجزء المراد استقطاعه (أول 20 بايت أو أقل إذا كانت الصورة أصغر)
    final int endRange = bytes.length > 20 ? 20 : bytes.length;

    // استخدام sublist بدلاً من substring لاستخراج البايتات
    final List<int> sampleBytes = bytes.sublist(0, endRange);

    // دمج الطول مع الـ hashCode ومحتوى العينة يعطي بصمة فريدة ومستقرة جداً
    return "${bytes.length}_${bytes.hashCode}_$sampleBytes";
  }

  /*
  Uint8List? getImageBytes(String variationId) {
    if (variationImageBytes.containsKey(variationId)) {
      return variationImageBytes[variationId];
    }
    final trimmedId = variationId.trim();
    if (variationImageBytes.containsKey(trimmedId)) {
      return variationImageBytes[trimmedId];
    }
    try {
      return variationImageBytes.entries
          .firstWhere((entry) => entry.key.trim() == trimmedId)
          .value;
    } catch (_) {
      return null;
    }
  }
*/
  String? getImageUrl(String variationId) {
    return variationImageUrls[variationId];
  }

  Uint8List? getImageBytes(String variationId) {
    final trimmedId = variationId.trim();

    // جلب البايتات (الخام أو المضغوطة، أيهما متوفر حالياً في الكاش)
    if (variationImageBytes.containsKey(trimmedId)) {
      return variationImageBytes[trimmedId];
    }
    return null;
  }

  /// --- دالة اختيار وتجهيز صورة الفاريشن الموحدة (موبايل وديسكطوب) ---
  Future<void> selectVariationImage(
    BuildContext
    context, // تم الإبقاء عليه إذا كانت هناك حاجة إليه في الـ UI لديك
    ProductVariationModel variation,
  ) async {
    final String vId = variation.id.trim();

    try {
      // 1. تفعيل مؤشر التحميل الخاص بهذا الفاريشن بالذات
      variationImageLoading[vId] = true;
      update(); // تحديث الواجهة لإظهار الـ Shimmer أو دالة التحميل

      // 2. اختيار الصورة من المعرض (تطبيق موحد للموبايل والديسكطوب)
      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // جلب الصورة الأصلية الخام بدون تلاعب خارجي
      );

      // إذا تراجع المستخدم عن الاختيار، نغلق التحميل ونخرج برفق
      if (pickedFile == null) {
        variationImageLoading[vId] = false;
        update();
        return;
      }

      // 3. قراءة بايتات الصورة المختارة
      final Uint8List rawBytes = await pickedFile.readAsBytes();

      if (rawBytes.isEmpty) throw "الملف المختار فارغ أو تالف.";

      // 4. توليد البصمة الفريدة لمحتوى الصورة لمنع التكرار
      final String imageHash = _generateImageHash(rawBytes);
      variationImageHashes[vId] = imageHash;

      // 5. جدولة عملية الضغط في الخلفية (Isolate) إذا لم تكن الصورة مضغوطة مسبقاً
      if (!compressionTasks.containsKey(imageHash)) {
        debugPrint(
          "📸 [Isolate المجدول]: صورة جديدة للفاريشن $vId، جاري بدء الضغط...",
        );

        // حفظ الـ Future مباشرة في الخريطة دون انتظار (Non-blocking) لراحة المستخدم
        compressionTasks[imageHash] = THelperFunctions.compressImageDirectly(
          rawBytes,
        );
      } else {
        debugPrint(
          "🎯 [كاش متاح]: الصورة متطابقة مع فاريشن آخر، تم ربط الوعد (Future) تلقائياً.",
        );
      }

      // 6. نجاح العملية: حفظ البايتات الخام مؤقتاً في كاش الواجهة لعرضها للمستخدم فوراً دون انتظار انتهاء الضغط
      variationImageBytes[vId] = rawBytes;
    } catch (e) {
      debugPrint("🚨 خطأ أثناء اختيار صورة المتغير ($vId): $e");
      TLoaders.errorSnackBar(
        title: "فشل اختيار الصورة",
        message: "حدث خطأ أثناء معالجة الصورة المحددة، يرجى المحاولة مجدداً.",
      );
    } finally {
      // إغلاق مؤشر التحميل وتحديث الواجهة في كل الحالات
      variationImageLoading[vId] = false;
      update();
    }
  }

  // --- اختيار الصور للموبايل والديسكطوب ---
  /*
  Future<void> selectVariationImage(
    BuildContext context,
    ProductVariationModel variation,
  ) async {
    if (TDeviceUtils.isDesktopScreen(context)) {
      await selectDesktopVariationImage(variation);
    } else {
      await selectMobileVariationImage(context, variation);
    }
  }
*/
  Future<void> selectMobileVariationImage(
    BuildContext context,
    ProductVariationModel variation,
  ) async {
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // جلب الصورة الأصلية الخام بنسبة 100%
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      await processAndCacheImage(bytes, variation); // استخدام المعالجة الذكية
    }
  }

  Future<void> selectDesktopVariationImage(
    ProductVariationModel variation,
  ) async {
    try {
      variationImageLoading[variation.id] = true;
      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // جلب الصورة الأصلية الخام بنسبة 100%
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        await processAndCacheImage(bytes, variation); // استخدام المعالجة الذكية
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: "خطأ", message: e.toString());
    } finally {
      variationImageLoading[variation.id] = false;
    }
  }

  // --- معالجة السحب والإفلات ---
  Future<void> handleDroppedFile(
    dynamic event,
    ProductVariationModel variation,
  ) async {
    try {
      variationImageLoading[variation.id] = true;
      final dropzoneController = dropzoneControllers[variation.id];

      if (dropzoneController == null) return;

      final bytes = await dropzoneController.getFileData(event);
      if (bytes.isNotEmpty) {
        await processAndCacheImage(Uint8List.fromList(bytes), variation);
        TLoaders.successSnackBar(title: "نجح", message: "تم اختيار الصورة");
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: "خطأ", message: e.toString());
    } finally {
      variationImageLoading[variation.id] = false;
    }
  }

  // --- الدالة الجوهرية الجديدة: المعالجة والتحقق من التكرار ---
  Future<void> processAndCacheImage(
    Uint8List originalBytes,
    ProductVariationModel variation,
  ) async {
    final String vId = variation.id.trim();

    // 1️⃣ أولاً: عرض الصورة الأصلية فوراً في الواجهة بدون أي تأخير لكي يشعر المستخدم بالسرعة
    variationImageBytes[vId] = originalBytes;
    variationImageLoading[vId] =
        true; // نضع مؤشر تحميل صغير على مستوى الكارد إذا أردت

    try {
      // 2️⃣ ثانياً: الضغط في الخلفية (Isolate) دون التأثير على سلاسة التطبيق
      final Uint8List compressedBytes =
          await THelperFunctions.compressImageDirectly(originalBytes);

      // استبدال البايتات الخام بالبايتات المضغوطة الممتازة في الذاكرة
      variationImageBytes[vId] = compressedBytes;

      // 3️⃣ ثالثاً: حساب البصمة (Hash) بناءً على الصورة المضغوطة لتخزينها بالـ Cache
      final String imageHash = _calculateImageHash(compressedBytes);

      if (_uploadedImagesCache.containsKey(imageHash)) {
        String existingUrl = _uploadedImagesCache[imageHash]!;
        variation.image = existingUrl;
        variationImageUrls[vId] = existingUrl;
        debugPrint("DEBUG: Compressed image matches cache. URL assigned.");
      } else {
        variation.image = '';
        variationImageUrls.remove(vId);
        debugPrint("DEBUG: Image compressed in background & ready for upload.");
      }
    } catch (e) {
      debugPrint("Error in background compression processing: $e");
    } finally {
      variationImageLoading[vId] = false;
    }

    debugPrintImageData();
  }

  /*
  Future<void> processAndCacheImage(
    Uint8List bytes,
    ProductVariationModel variation,
  ) async {
    final String imageHash = _calculateImageHash(bytes);
    final String vId = variation.id.trim();

    // 1. تحديث الـ Bytes للعرض الفوري في الواجهة
    variationImageBytes[vId] = bytes;

    // 2. التحقق إذا كانت هذه الصورة (نفس المحتوى) قد رفعت سابقاً
    if (_uploadedImagesCache.containsKey(imageHash)) {
      String existingUrl = _uploadedImagesCache[imageHash]!;
      variation.image = existingUrl;
      variationImageUrls[vId] = existingUrl;
      debugPrint(
        "DEBUG: Image content recognized (Hash match). Using cached URL.",
      );
    } else {
      // 3. إذا كانت صورة جديدة، نقوم بتصفير الرابط القديم لحين الرفع الفعلي لاحقاً
      variation.image = '';
      variationImageUrls.remove(vId);
      debugPrint(
        "DEBUG: New image content. Ready for upload. Hash: $imageHash",
      );
    }

    debugPrintImageData();
  }
*/

  void clearAllImages() {
    variationImageBytes.clear();
    variationImageUrls.clear();
    variationImageLoading.clear();
    dropzoneControllers.clear();
    _uploadedImagesCache.clear();
  }

  void debugPrintImageData() {
    debugPrint("=== DEBUG: Variation Images ===");
    debugPrint("Bytes in memory: ${variationImageBytes.length}");
    debugPrint("Cached URLs (Unique Images): ${_uploadedImagesCache.length}");
    debugPrint("===============================");
  }

  void resetController() {
    variationImageBytes.clear();
    variationImageUrls.clear();
    variationImageLoading.clear();
    // لا تقم بتصفير الـ dropzoneControllers لأنها مرتبطة بالـ Views الحية
    _uploadedImagesCache.clear();
    debugPrint("DEBUG: Variation Image Controller Has Been Reset.");
  }
}

/*
class ProductVariationImageController extends GetxController {
  static ProductVariationImageController get instance => Get.find();

  final ImagePicker imagePicker = ImagePicker();
  // خريطة لتخزين الروابط المرفوعة مسبقاً: المفتاح هو الـ Hash والقيمة هي الـ URL
  final Map<String, String> _uploadedImagesCache = {};
  final RxMap<String, Uint8List> variationImageBytes =
      <String, Uint8List>{}.obs;
  final RxMap<String, String> variationImageUrls = <String, String>{}.obs;
  final RxMap<String, bool> variationImageLoading = <String, bool>{}.obs;
  final RxMap<String, DropzoneViewController?> dropzoneControllers =
      <String, DropzoneViewController?>{}.obs;

  Uint8List? getImageBytes(String variationId) {
    // 1. جرب البحث بالـ ID كما هو
    if (variationImageBytes.containsKey(variationId)) {
      return variationImageBytes[variationId];
    }

    // 2. إذا لم يجد، جرب البحث بالـ ID بعد إزالة المسافات (trim)
    final trimmedId = variationId.trim();
    if (variationImageBytes.containsKey(trimmedId)) {
      return variationImageBytes[trimmedId];
    }

    // 3. (إضافة قوية) ابحث في كل المفاتيح لترى إذا كان أحدها يشبه الـ ID المطلوب بعد التنظيف
    try {
      return variationImageBytes.entries
          .firstWhere((entry) => entry.key.trim() == trimmedId)
          .value;
    } catch (_) {
      debugPrint("Debug: No bytes found for ID: '$variationId'");
      return null;
    }
  }

  String? getImageUrl(String variationId) {
    return variationImageUrls[variationId];
  }

  // دالة لحساب بصمة الصورة (Unique Hash)
  String _calculateImageHash(Uint8List bytes) {
    return md5.convert(bytes).toString();
  }

  Future<void> selectVariationImage(
    BuildContext context,
    ProductVariationModel variation,
  ) async {
    if (TDeviceUtils.isDesktopScreen(context)) {
      await selectDesktopVariationImage(variation);
    } else {
      await selectMobileVariationImage(context, variation);
    }
  }

  Future<void> selectMobileVariationImage(
    BuildContext context,
    ProductVariationModel variation,
  ) async {
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      await _processImageFile(variation, pickedFile);
    }
    /*final selectedImages = await _showImageGallery(
      allowMultiple: false,
      category: MediaCategory.products,
    );*/

    /*if (selectedImages != null && selectedImages.isNotEmpty) {
      variation.image = selectedImages.first.url;
      variationImageUrls[variation.id] = variation.image;
      variationImageBytes.remove(variation.id);
    }*/
  }

  Future<void> selectDesktopVariationImage(
    ProductVariationModel variation,
  ) async {
    try {
      variationImageLoading[variation.id] = true;

      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (pickedFile != null) {
        await _processImageFile(variation, pickedFile);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "خطأ",
        message: "فشل تحميل الصورة: ${e.toString()}",
      );
    } finally {
      variationImageLoading[variation.id] = false;
    }
  }

  Future<void> handleDroppedFile(
    dynamic event,
    ProductVariationModel variation,
  ) async {
    try {
      variationImageLoading[variation.id] = true;
      final dropzoneController = dropzoneControllers[variation.id];

      if (dropzoneController == null) {
        TLoaders.errorSnackBar(
          title: "خطأ",
          message: "لم يتم تهيئة منطقة السحب والإفلات",
        );
        return;
      }

      final bytes = await dropzoneController.getFileData(event);
      if (bytes.isNotEmpty) {
        variation.image = '';
        variationImageUrls.remove(variation.id);
        variationImageBytes[variation.id.trim()] = Uint8List.fromList(bytes);

        TLoaders.successSnackBar(
          title: "نجح",
          message: "تم تحميل الصورة بنجاح",
        );
        debugPrint(
          "DEBUG: Dropped ${bytes.length} bytes for variation ID: ${variation.id}",
        );
        debugPrintImageData();
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "خطأ",
        message: "فشل تحميل الصورة: ${e.toString()}",
      );
    } finally {
      variationImageLoading[variation.id] = false;
    }
  }

  Future<void> _processImageFile(
    ProductVariationModel variation,
    XFile file,
  ) async {
    final bytes = await file.readAsBytes();
    if (bytes.isNotEmpty) {
      variation.image = '';
      variationImageUrls.remove(variation.id);
      variationImageBytes[variation.id.trim()] = bytes;
      debugPrint(
        "DEBUG: Stored ${bytes.length} bytes for variation ID: ${variation.id}",
      );
      debugPrintImageData();
    }
  }

  Future<List<ImageModel>?> _showImageGallery({
    required bool allowMultiple,
    required MediaCategory category,
  }) async {
    final selectedImages = <ImageModel>[].obs;

    return await Get.dialog<List<ImageModel>>(
      AlertDialog(
        title: const Text("اختر الصور"),
        content: SizedBox(
          width: 800,
          height: 600,
          child: ImageGalleryWidget(
            onImageSelected: (images) {
              selectedImages.assignAll(images);
            },
            allowMultipleSelection: allowMultiple,
            selectedImages: selectedImages,
            category: category,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () => Get.back(result: selectedImages.toList()),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  // الدالة المعدلة لمعالجة الصورة قبل الرفع
  Future<void> processAndUploadImage(
    Uint8List bytes,
    ProductVariationModel variation,
  ) async {
    final String imageHash = _calculateImageHash(bytes);

    variationImageLoading[variation.id] = true;

    try {
      if (_uploadedImagesCache.containsKey(imageHash)) {
        // حالة 1: الصورة رفعت مسبقاً في هذه الجلسة
        String existingUrl = _uploadedImagesCache[imageHash]!;
        variation.image = existingUrl;
        variationImageUrls[variation.id] = existingUrl;
        debugPrint("تم استخدام رابط موجود مسبقاً لنفس الصورة");
      } else {
        // حالة 2: صورة جديدة، يجب رفعها
        // هنا تضع كود الرفع الخاص بك (Firebase Storage مثلاً)
        String uploadedUrl = await uploadToFirebase(
          bytes,
          "products/variations/${variation.id}",
        );

        // تخزين الرابط في الكاش لاستخدامه لاحقاً إذا تكررت الصورة
        _uploadedImagesCache[imageHash] = uploadedUrl;

        variation.image = uploadedUrl;
        variationImageUrls[variation.id] = uploadedUrl;
      }

      // تحديث واجهة المستخدم بالبيانات المحلية (Bytes) للعرض الفوري
      variationImageBytes[variation.id] = bytes;
    } finally {
      variationImageLoading[variation.id] = false;
    }
  }

  // استبدل استدعاء الرفع المباشر في handleDroppedFile و selectMobileVariationImage
  // بـ processAndUploadImage(bytes, variation);

  /// تنظيف جميع الصور
  void clearAllImages() {
    variationImageBytes.clear();
    variationImageUrls.clear();
    variationImageLoading.clear();
    dropzoneControllers.clear();
  }

  /// دالة للتحقق من محتويات الـ Maps (للـ Debug)
  void debugPrintImageData() {
    debugPrint("=== DEBUG: ProductVariationImageController ===");
    debugPrint(
      "variationImageBytes keys: ${variationImageBytes.keys.toList()}",
    );
    debugPrint("variationImageBytes length: ${variationImageBytes.length}");
    debugPrint("variationImageUrls keys: ${variationImageUrls.keys.toList()}");
    debugPrint("variationImageUrls length: ${variationImageUrls.length}");
    debugPrint(
      "variationImageLoading keys: ${variationImageLoading.keys.toList()}",
    );
    debugPrint("variationImageLoading length: ${variationImageLoading.length}");
    debugPrint("===============================================");
  }
}
*/
/*
class ProductVariationImageController extends GetxController {
  static ProductVariationImageController get instance => Get.find();

  final ImagePicker imagePicker = ImagePicker();

  final RxMap<String, Uint8List> variationImageBytes =
      <String, Uint8List>{}.obs;
  final RxMap<String, String> variationImageUrls = <String, String>{}.obs;
  final RxMap<String, bool> variationImageLoading = <String, bool>{}.obs;
  final RxMap<String, DropzoneViewController?> dropzoneControllers =
      <String, DropzoneViewController?>{}.obs;

  Uint8List? getImageBytes(String variationId) {
    if (variationImageBytes.containsKey(variationId)) {
      return variationImageBytes[variationId];
    }
    return null;
  }

  Future<void> selectVariationImage(
    BuildContext context,
    ProductVariationModel variation,
  ) async {
    if (TDeviceUtils.isDesktopScreen(context)) {
      await selectDesktopVariationImage(variation);
    } else {
      await selectMobileVariationImage(context, variation);
    }
  }

  Future<void> selectMobileVariationImage(
    BuildContext context,
    ProductVariationModel variation,
  ) async {
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      await _processImageFile(variation, pickedFile);
    }
  }

  Future<void> selectDesktopVariationImage(
    ProductVariationModel variation,
  ) async {
    try {
      variationImageLoading[variation.id] = true;

      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (pickedFile != null) {
        await _processImageFile(variation, pickedFile);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "خطأ",
        message: "فشل تحميل الصورة: ${e.toString()}",
      );
    } finally {
      variationImageLoading[variation.id] = false;
    }
  }

  Future<void> handleDroppedFile(
    dynamic event,
    ProductVariationModel variation,
  ) async {
    try {
      variationImageLoading[variation.id] = true;
      final dropzoneController = dropzoneControllers[variation.id];

      if (dropzoneController == null) {
        TLoaders.errorSnackBar(
          title: "خطأ",
          message: "لم يتم تهيئة منطقة السحب والإفلات",
        );
        return;
      }

      final bytes = await dropzoneController.getFileData(event);
      if (bytes.isNotEmpty) {
        variation.image = '';
        variationImageUrls.remove(variation.id);
        variationImageBytes[variation.id] = Uint8List.fromList(bytes);
        TLoaders.successSnackBar(
          title: "نجح",
          message: "تم اختيار الصورة بنجاح",
        );
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "خطأ",
        message: "فشل تحميل الصورة: ${e.toString()}",
      );
    } finally {
      variationImageLoading[variation.id] = false;
    }
  }

  Future<void> _processImageFile(
    ProductVariationModel variation,
    XFile file,
  ) async {
    final bytes = await file.readAsBytes();
    if (bytes.isNotEmpty) {
      variation.image = '';
      variationImageUrls.remove(variation.id);

      // هنا السر: نخزن البايتات باستخدام الـ ID الثابت
      variationImageBytes[variation.id] = bytes;
    }
  }
}

*/
