import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stors_admin_panel/features/media/models/image_model.dart';
import 'package:stors_admin_panel/utils/device/device_utility.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

// افتراضاً لأسماء الموديلات والحزم لديك
// import 'package:your_app/models/image_model.dart';

class ProductImageController extends GetxController {
  static ProductImageController get instance => Get.find();

  final ImagePicker imagePicker = ImagePicker();

  // 🌟 الصورة الرئيسية
  final Rx<Uint8List?> mainImageBytes = Rx<Uint8List?>(null);
  final Rx<String?> mainImageUrl = Rx<String?>(null);
  final RxBool mainImageLoading = false.obs;
  final RxString mainImageHash =
      "".obs; // 🌟 حفظ بصمة الصورة الرئيسية لمنع التكرار

  // 🌟 الصور الإضافية
  final RxList<Uint8List> additionalImageBytes = <Uint8List>[].obs;
  final RxList<String> additionalImageUrls = <String>[].obs;
  final RxList<bool> additionalImageLoading = <bool>[].obs;
  final RxList<String> additionalImageHashes =
      <String>[].obs; // 🌟 مصفوفة البصمات للصور الإضافية

  // 🌟 مستودع الوعود الموحد (يمنع تكرار ضغط نفس الصورة في التطبيق بالكامل)
  final Map<String, Future<Uint8List>> compressionTasks = {};

  // Dropzone controllers للويب
  final Rx<DropzoneViewController?> mainImageDropzoneController =
      Rx<DropzoneViewController?>(null);
  final RxList<DropzoneViewController?> additionalImageDropzoneControllers =
      <DropzoneViewController?>[].obs;

  /// 🌟 دالة توليد بصمة فريدة وسريعة لمحتوى بايتات الصورة لمنع التكرار
  String _generateImageHash(Uint8List bytes) {
    if (bytes.isEmpty) return "";
    final int endRange = bytes.length > 20 ? 20 : bytes.length;
    final List<int> sampleBytes = bytes.sublist(0, endRange);
    return "${bytes.length}_${bytes.hashCode}_$sampleBytes";
  }

  // ==================== MAIN IMAGE METHODS ====================

  /// اختيار الصورة الرئيسية (موبايل وديسكطوب)
  Future<void> selectMainImage(BuildContext context) async {
    try {
      mainImageLoading.value = true;
      Uint8List? rawBytes;

      if (TDeviceUtils.isDesktopScreen(context)) {
        final controller = mainImageDropzoneController.value;
        if (controller == null) return;
        final events = await controller.pickFiles();
        if (events.isNotEmpty)
          rawBytes = await controller.getFileData(events.first);
      } else {
        final pickedFile = await imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
        );
        if (pickedFile != null) rawBytes = await pickedFile.readAsBytes();
      }

      if (rawBytes != null && rawBytes.isNotEmpty) {
        final String imageHash = _generateImageHash(rawBytes);
        mainImageHash.value = imageHash;

        // 1. العرض الفوري اللحظي للبايتات الخام على الواجهة
        mainImageBytes.value = rawBytes;
        mainImageUrl.value = null;

        // 2. جدولة الضغط في الخلفية (Isolate) دون تعطيل المستخدم
        if (!compressionTasks.containsKey(imageHash)) {
          compressionTasks[imageHash] = THelperFunctions.compressImageDirectly(
            rawBytes,
          );
        }
      }
    } catch (e) {
      debugPrint("🚨 خطأ في اختيار الصورة الرئيسية: $e");
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في اختيار الصورة');
    } finally {
      mainImageLoading.value = false;
    }
  }

  /// حذف الصورة الرئيسية
  void removeMainImage() {
    mainImageBytes.value = null;
    mainImageUrl.value = null;
    mainImageHash.value = "";
  }

  // ==================== ADDITIONAL IMAGES METHODS ====================

  /// إضافة صور إضافية
  Future<void> addAdditionalImages(BuildContext context) async {
    if (TDeviceUtils.isDesktopScreen(context)) {
      await addDesktopAdditionalImages();
    } else {
      await addMobileAdditionalImages(context);
    }
  }

  /// إضافة صور إضافية للهاتف المحمول (معالجة متوازية آمنة ومضمونة بنظام الـ Futures)
  Future<void> addMobileAdditionalImages(BuildContext context) async {
    try {
      final pickedFiles = await imagePicker.pickMultiImage(imageQuality: 100);
      if (pickedFiles.isEmpty) return;

      List<Uint8List> selectedRawBytesList = [];
      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        selectedRawBytesList.add(bytes);
      }

      // حجز الأماكن والعرض الفوري في الواجهة للبايتات الخام لسرعة الـ UX
      for (var rawBytes in selectedRawBytesList) {
        additionalImageBytes.add(rawBytes);
        additionalImageLoading.add(
          false,
        ); // تم جعلها false لأن الصورة تعرض فوراً كـ Bytes خام

        final String imageHash = _generateImageHash(rawBytes);
        additionalImageHashes.add(imageHash);

        // جدولة عمليات الضغط غير المتزامنة بذكاء دون تكرار
        if (!compressionTasks.containsKey(imageHash)) {
          compressionTasks[imageHash] = THelperFunctions.compressImageDirectly(
            rawBytes,
          );
        }
      }
    } catch (e) {
      debugPrint("🚨 خطأ في إضافة وضغط الصور الإضافية: $e");
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في إضافة الصور');
    }
  }

  /// إضافة صورة إضافية من المعرض الداخلي المخصص لديك
  Future<void> addAdditionalImageFromGallery() async {
    try {
      final selectedImages = await _showImageGallery(allowMultiple: true);
      for (var image in selectedImages) {
        additionalImageUrls.add(image.url);
        additionalImageBytes.add(Uint8List(0)); // placeholder للروابط السحابية
        additionalImageLoading.add(false);
        additionalImageHashes.add(""); // لا يوجد بايتات محلية لإنتاج البصمة
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في إضافة الصورة');
    }
  }

  /// اختيار الصورة الرئيسية من المعرض الداخلي المخصص لديك
  Future<void> selectMainImageFromGallery() async {
    try {
      final selectedImages = await _showImageGallery(allowMultiple: false);
      if (selectedImages.isNotEmpty) {
        final image = selectedImages.first;
        mainImageUrl.value = image.url;
        mainImageBytes.value = null;
        mainImageHash.value =
            ""; // تصفير البصمة المحلية لأنها قادمة من رابط جاهز
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في اختيار الصورة');
    }
  }

  /// إضافة صور إضافية للويب
  Future<void> addDesktopAdditionalImages() async {
    // TODO: Implement desktop multiple file selection
    TLoaders.warningSnackBar(
      title: 'تحذير',
      message: 'إضافة صور متعددة غير مدعومة بعد على سطح المكتب',
    );
  }

  /// حذف صورة إضافية بناءً على رقم عنصرها
  void removeAdditionalImage(int index) {
    if (index < additionalImageBytes.length) {
      additionalImageBytes.removeAt(index);
      additionalImageLoading.removeAt(index);
      additionalImageHashes.removeAt(index);
      // الحفاظ على التناسق مع مصفوفة الروابط النصية إذا كانت متطابقة الحجم
      if (index < additionalImageUrls.length) {
        additionalImageUrls.removeAt(index);
      }
    }
  }

  // ==================== HELPER METHODS ====================

  /// عرض معرض الصور الداخلي
  Future<List<ImageModel>> _showImageGallery({
    required bool allowMultiple,
  }) async {
    // ميثود مخصصة لديك في السيستم
    return [];
  }

  Uint8List? getMainImageBytes() => mainImageBytes.value;
  String? getMainImageUrl() => mainImageUrl.value;
  List<Uint8List> getAdditionalImageBytes() => additionalImageBytes;
  List<String> getAdditionalImageUrls() =>
      additionalImageUrls.where((url) => url.isNotEmpty).toList();

  /// تنظيف جميع الصور من الكنترولر
  void clearAllImages() {
    mainImageBytes.value = null;
    mainImageUrl.value = null;
    mainImageHash.value = "";
    additionalImageBytes.clear();
    additionalImageUrls.clear();
    additionalImageLoading.clear();
    additionalImageHashes.clear();
  }

  /// دالة لتهيئة البيانات في وضع التعديل (Edit Mode) للقادم من الـ Firebase
  void initProductImages(String mainUrl, List<String> secondaryUrls) {
    clearAllImages();
    mainImageUrl.value = mainUrl;
    additionalImageUrls.assignAll(secondaryUrls);
    additionalImageLoading.assignAll(
      List.generate(secondaryUrls.length, (_) => false),
    );
    // ملء البصمات والمصفوفات المحلية بـ قيم فارغة للحفاظ على طول متناسق مع الروابط الجاهزة
    additionalImageBytes.assignAll(
      List.generate(secondaryUrls.length, (_) => Uint8List(0)),
    );
    additionalImageHashes.assignAll(
      List.generate(secondaryUrls.length, (_) => ""),
    );
  }

  /// حذف صورة (سواء كانت رابط شبكة أو بايتات محلية) متوافقة مع الـ UI القديم لديك
  void removeProductImage(int index) {
    if (index < additionalImageUrls.length) {
      additionalImageUrls.removeAt(index);
    } else {
      int byteIndex = index - additionalImageUrls.length;
      if (byteIndex < additionalImageBytes.length) {
        additionalImageBytes.removeAt(byteIndex);
        additionalImageLoading.removeAt(index);
        additionalImageHashes.removeAt(byteIndex);
      }
    }
  }

  /// تبديل الصورة الرئيسية بجعل صورة إضافية مكانها وعكس العملية
  void setAsMainImage(int index) {
    String? oldMainUrl = mainImageUrl.value;
    Uint8List? oldMainBytes = mainImageBytes.value;
    String oldMainHash = mainImageHash.value;

    if (index < additionalImageUrls.length) {
      // إذا كانت الصورة المختارة عبارة عن رابط شبكة
      mainImageUrl.value = additionalImageUrls[index];
      mainImageBytes.value = null;
      mainImageHash.value = "";

      additionalImageUrls.removeAt(index);
    } else {
      // إذا كانت الصورة المختارة عبارة عن بايتات محلية
      int byteIndex = index - additionalImageUrls.length;
      mainImageBytes.value = additionalImageBytes[byteIndex];
      mainImageHash.value = additionalImageHashes[byteIndex];
      mainImageUrl.value = null;

      additionalImageBytes.removeAt(byteIndex);
      additionalImageHashes.removeAt(byteIndex);
    }

    // إرجاع الصورة الرئيسية القديمة المتنحية إلى مصفوفة الصور الإضافية لكي لا تضيع
    if (oldMainUrl != null) {
      additionalImageUrls.add(oldMainUrl);
      additionalImageBytes.add(Uint8List(0));
      additionalImageHashes.add("");
    } else if (oldMainBytes != null) {
      additionalImageBytes.add(oldMainBytes);
      additionalImageHashes.add(oldMainHash);
    }
  }

  @override
  void onClose() {
    clearAllImages();
    super.onClose();
  }
}






/*
class ProductImageController extends GetxController {
  static ProductImageController get instance => Get.find();

  final ImagePicker imagePicker = ImagePicker();

  // الصورة الرئيسية
  final Rx<Uint8List?> mainImageBytes = Rx<Uint8List?>(null);
  final Rx<String?> mainImageUrl = Rx<String?>(null);
  final RxBool mainImageLoading = false.obs;

  // الصور الإضافية
  final RxList<Uint8List> additionalImageBytes = <Uint8List>[].obs;
  final RxList<String> additionalImageUrls = <String>[].obs;
  final RxList<bool> additionalImageLoading = <bool>[].obs;

  // Dropzone controllers للويب
  final Rx<DropzoneViewController?> mainImageDropzoneController =
      Rx<DropzoneViewController?>(null);
  final RxList<DropzoneViewController?> additionalImageDropzoneControllers =
      <DropzoneViewController?>[].obs;

  // ==================== MAIN IMAGE METHODS ====================

  /// اختيار الصورة الرئيسية
  Future<void> selectMainImage(BuildContext context) async {
    if (TDeviceUtils.isDesktopScreen(context)) {
      await selectDesktopMainImage();
    } else {
      await selectMobileMainImage(context);
    }
  }

  /// اختيار الصورة الرئيسية للهاتف المحمول
  Future<void> selectMobileMainImage(BuildContext context) async {
    try {
      mainImageLoading.value = true;

      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // جلب الصورة الأصلية الخام بنسبة 100%
      );

      if (pickedFile != null) {
        final rawBytes = await pickedFile.readAsBytes();

        // 1. عرض الصورة الخام فوراً في الواجهة لتجربة مستخدم سريعة
        mainImageBytes.value = rawBytes;
        mainImageUrl.value = null;

        // 2. معالجة الضغط الذكي في الـ Isolate الخلفي دون تجميد الواجهة
        final compressedBytes = await THelperFunctions.compressImageDirectly(
          rawBytes,
        );

        // 3. استبدال الصورة بالنسخة المضغوطة الاحترافية في الذاكرة جاهزة للرفع
        mainImageBytes.value = compressedBytes;
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في اختيار الصورة');
    } finally {
      mainImageLoading.value = false;
    }
  }

  /// اختيار الصورة الرئيسية للويب (سحب وإفلات أو اختيار)
  Future<void> selectDesktopMainImage() async {
    final controller = mainImageDropzoneController.value;
    if (controller == null) return;

    try {
      mainImageLoading.value = true;

      final events = await controller.pickFiles();
      if (events.isNotEmpty) {
        final rawBytes = await controller.getFileData(events.first);

        // عرض فوري
        mainImageBytes.value = rawBytes;
        mainImageUrl.value = null;

        // ضغط خلفي
        final compressedBytes = await THelperFunctions.compressImageDirectly(
          rawBytes,
        );
        mainImageBytes.value = compressedBytes;
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في رفع الصورة');
    } finally {
      mainImageLoading.value = false;
    }
  }

  /*
  /// اختيار الصورة الرئيسية للهاتف المحمول
  Future<void> selectMobileMainImage(BuildContext context) async {
    try {
      mainImageLoading.value = true;

      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // جلب الصورة الأصلية الخام بنسبة 100%
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        mainImageBytes.value = bytes;
        mainImageUrl.value = null; // إزالة URL إذا كانت موجودة
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في اختيار الصورة');
    } finally {
      mainImageLoading.value = false;
    }
  }
*/

  /*
  /// اختيار الصورة الرئيسية للويب (سحب وإفلات)
  Future<void> selectDesktopMainImage() async {
    final controller = mainImageDropzoneController.value;
    if (controller == null) return;

    try {
      mainImageLoading.value = true;

      final events = await controller.pickFiles();
      if (events.isNotEmpty) {
        final bytes = await controller.getFileData(events.first);
        mainImageBytes.value = bytes;
        mainImageUrl.value = null; // إزالة URL إذا كانت موجودة
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في رفع الصورة');
    } finally {
      mainImageLoading.value = false;
    }
  }
*/
  /// اختيار الصورة الرئيسية من المعرض
  /*Future<void> selectMainImageFromGallery() async {
    try {
      final selectedImages = await _showImageGallery(allowMultiple: false);
      if (selectedImages.isNotEmpty) {
        final image = selectedImages.first;
        mainImageUrl.value = image.url;
        mainImageBytes.value = null; // إزالة البيانات المحلية
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في اختيار الصورة');
    }
  }*/

  /// حذف الصورة الرئيسية
  void removeMainImage() {
    mainImageBytes.value = null;
    mainImageUrl.value = null;
  }

  // ==================== ADDITIONAL IMAGES METHODS ====================

  /// إضافة صور إضافية
  Future<void> addAdditionalImages(BuildContext context) async {
    if (TDeviceUtils.isDesktopScreen(context)) {
      await addDesktopAdditionalImages();
    } else {
      await addMobileAdditionalImages(context);
    }
  }

  /// إضافة صور إضافية للهاتف المحمول (ضغط متوازي ذكي)
  /// إضافة صور إضافية للهاتف المحمول (معالجة متوازية آمنة ومضمونة)
  Future<void> addMobileAdditionalImages(BuildContext context) async {
    try {
      final pickedFiles = await imagePicker.pickMultiImage(
        imageQuality: 100, // جلب الصور الأصلية الخام
      );

      if (pickedFiles.isEmpty) return;

      // مصفوفة مؤقتة لحمل بايتات الصور التي تم اختيارها في هذه الضغطة
      List<Uint8List> selectedRawBytesList = [];

      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        selectedRawBytesList.add(bytes);
      }

      // 1. حجز أماكن في الواجهة فوراً وعرض مؤشرات التحميل للمستخدم لسرعة الاستجابة
      for (var _ in selectedRawBytesList) {
        // نستخدم بايتات فارغة مؤقتاً أو نضع الأصلية لحين انتهاء الضغط
        additionalImageBytes.add(Uint8List(0));
        additionalImageLoading.add(true);
      }

      // تحديد نقطة البداية (المؤشر) المخصص لهذه المجموعة الجديدة بداخل القائمة الأساسية
      final int startIndex =
          additionalImageBytes.length - selectedRawBytesList.length;

      // 2. إطلاق عمليات الضغط المتوازي في الخلفية بشكل آمن ومستقل تماماً
      for (int i = 0; i < selectedRawBytesList.length; i++) {
        final rawBytes = selectedRawBytesList[i];
        final targetIndex =
            startIndex + i; // المؤشر الثابت والمضمون لهذه الصورة بالذات

        // نعرض الصورة الأصلية مؤقتاً في مكانها الصحيح
        additionalImageBytes[targetIndex] = rawBytes;

        // استدعاء الضغط بدون عزل عشوائي للمؤشرات
        THelperFunctions.compressImageDirectly(rawBytes)
            .then((compressedBytes) {
              // 3. عند انتهاء الضغط بنجاح، يتم التحديث في نفس المكان المخصص لها تماماً
              if (targetIndex < additionalImageBytes.length) {
                additionalImageBytes[targetIndex] = compressedBytes;
                additionalImageLoading[targetIndex] = false;

                // إشعار GetX أو setState لتحديث الواجهة بناءً على إدارة الحالة لديك
                // update(); أو notifyListeners();
              }
            })
            .catchError((error) {
              debugPrint("❌ فشل ضغط الصورة عند المؤشر $targetIndex: $error");
              if (targetIndex < additionalImageLoading.length) {
                additionalImageLoading[targetIndex] = false;
              }
            });
      }
    } catch (e) {
      debugPrint("🚨 خطأ في إضافة وضغط الصور الإضافية: $e");
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في إضافة الصور');
    }
  }
  /*
  Future<void> addMobileAdditionalImages(BuildContext context) async {
    try {
      final pickedFiles = await imagePicker.pickMultiImage(
        imageQuality: 100, // جلب الصور الأصلية الخام بنسبة 100%
      );

      if (pickedFiles.isNotEmpty) {
        for (var pickedFile in pickedFiles) {
          final rawBytes = await pickedFile.readAsBytes();

          // 1. حجز مكان للصورة وعرضها فوري للمستخدم مع مؤشر تحميل خاص بها
          int index = additionalImageBytes.length;
          additionalImageBytes.add(rawBytes);
          additionalImageLoading.add(true);

          // 2. إطلاق عملية الضغط في الخلفية بشكل غير متزامن لكل صورة على حدة
          THelperFunctions.compressImageDirectly(rawBytes)
              .then((compressedBytes) {
                // 3. عند انتهاء الضغط، نقوم بتحديث البايتات وإغلاق مؤشر التحميل لهذه الصورة
                if (index < additionalImageBytes.length) {
                  additionalImageBytes[index] = compressedBytes;
                  additionalImageLoading[index] = false;
                }
              })
              .catchError((_) {
                if (index < additionalImageLoading.length) {
                  additionalImageLoading[index] = false;
                }
              });
        }
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في إضافة الصور');
    }
  }*/

  /// إضافة صورة إضافية من المعرض الداخلي (إذا كان يعطيك بايتات، يفضل ضغطها أيضاً بنفس الطريقة)
  Future<void> addAdditionalImageFromGallery() async {
    try {
      final selectedImages = await _showImageGallery(allowMultiple: true);
      for (var image in selectedImages) {
        additionalImageUrls.add(image.url);
        additionalImageBytes.add(Uint8List(0)); // placeholder للروابط السحابية
        additionalImageLoading.add(false);
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في إضافة الصورة');
    }
  }

  /// اختيار الصورة الرئيسية من المعرض الداخلي
  Future<void> selectMainImageFromGallery() async {
    try {
      final selectedImages = await _showImageGallery(allowMultiple: false);
      if (selectedImages.isNotEmpty) {
        final image = selectedImages.first;
        mainImageUrl.value = image.url;
        mainImageBytes.value = null;
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في اختيار الصورة');
    }
  }

  /// إضافة صور إضافية للهاتف المحمول
  /*
  Future<void> addMobileAdditionalImages(BuildContext context) async {
    try {
      final pickedFiles = await imagePicker.pickMultiImage(
        imageQuality: 100, // جلب الصورة الأصلية الخام بنسبة 100%
      );

      if (pickedFiles.isNotEmpty) {
        for (var pickedFile in pickedFiles) {
          final bytes = await pickedFile.readAsBytes();
          additionalImageBytes.add(bytes);
          // لا تضف أي شيء لـ additionalImageUrls هنا
          additionalImageLoading.add(false);
        }
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في إضافة الصور');
    }
  }
*/
  /* Future<void> addMobileAdditionalImages(BuildContext context) async {
    try {
      final pickedFiles = await imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFiles.isNotEmpty) {
        for (var pickedFile in pickedFiles) {
          final bytes = await pickedFile.readAsBytes();
          additionalImageBytes.add(bytes);
          additionalImageLoading.add(false);
          additionalImageUrls.add(''); // placeholder
        }
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في إضافة الصور');
    }
  }*/

  /// إضافة صور إضافية للويب

  Future<void> addDesktopAdditionalImages() async {
    // TODO: Implement desktop multiple file selection
    TLoaders.warningSnackBar(
      title: 'تحذير',
      message: 'إضافة صور متعددة غير مدعومة بعد على سطح المكتب',
    );
  }

  /// إضافة صورة إضافية من المعرض
  /*
  Future<void> addAdditionalImageFromGallery() async {
    try {
      final selectedImages = await _showImageGallery(allowMultiple: true);
      for (var image in selectedImages) {
        additionalImageUrls.add(image.url);
        additionalImageBytes.add(Uint8List(0)); // placeholder
        additionalImageLoading.add(false);
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: 'فشل في إضافة الصورة');
    }
  }
*/
  /// حذف صورة إضافية
  void removeAdditionalImage(int index) {
    if (index < additionalImageBytes.length) {
      additionalImageBytes.removeAt(index);
      additionalImageUrls.removeAt(index);
      additionalImageLoading.removeAt(index);
    }
  }

  /// جعل صورة إضافية رئيسية
  /*
  void setAsMainImage(int index) {
    // التعامل مع الصور القادمة من الروابط (Network URLs)
    if (index < additionalImageUrls.length) {
      mainImageUrl.value = additionalImageUrls[index];
      mainImageBytes.value = null;
      removeAdditionalImage(index);
    }
    // التعامل مع الصور المحلية (Bytes)
    else {
      int byteIndex = index - additionalImageUrls.length;
      if (byteIndex < additionalImageBytes.length) {
        mainImageBytes.value = additionalImageBytes[byteIndex];
        mainImageUrl.value = null;
        removeAdditionalImage(
          index,
        ); // تأكد أن removeAdditionalImage تعالج الـ index الكلي أيضاً
      }
    }
  }
*/
  /*void setAsMainImage(int index) {
    if (index < additionalImageUrls.length &&
        additionalImageUrls[index].isNotEmpty) {
      // نقل الصورة من الإضافية إلى الرئيسية
      mainImageUrl.value = additionalImageUrls[index];
      mainImageBytes.value = null;

      // حذفها من القائمة الإضافية
      removeAdditionalImage(index);
    } else if (index < additionalImageBytes.length &&
        additionalImageBytes[index].isNotEmpty) {
      // نقل البيانات المحلية
      mainImageBytes.value = additionalImageBytes[index];
      mainImageUrl.value = null;

      // حذفها من القائمة الإضافية
      removeAdditionalImage(index);
    }
  }*/

  // ==================== HELPER METHODS ====================

  /// عرض معرض الصور
  Future<List<ImageModel>> _showImageGallery({
    required bool allowMultiple,
  }) async {
    // TODO: Implement image gallery dialog
    // For now, return empty list
    return [];
  }

  /// الحصول على بيانات الصورة الرئيسية
  Uint8List? getMainImageBytes() {
    return mainImageBytes.value;
  }

  /// الحصول على URL الصورة الرئيسية
  String? getMainImageUrl() {
    return mainImageUrl.value;
  }

  /// الحصول على بيانات الصور الإضافية
  List<Uint8List> getAdditionalImageBytes() {
    return additionalImageBytes;
  }

  /// الحصول على URLs الصور الإضافية
  List<String> getAdditionalImageUrls() {
    return additionalImageUrls.where((url) => url.isNotEmpty).toList();
  }

  /// تنظيف جميع الصور
  void clearAllImages() {
    mainImageBytes.value = null;
    mainImageUrl.value = null;
    additionalImageBytes.clear();
    additionalImageUrls.clear();
    additionalImageLoading.clear();
  }

  /// دالة لتهيئة البيانات في وضع التعديل
  void initProductImages(String mainUrl, List<String> secondaryUrls) {
    clearAllImages();
    mainImageUrl.value = mainUrl;
    additionalImageUrls.assignAll(secondaryUrls);
    // نملأ قائمة الـ loading بنفس طول الروابط
    additionalImageLoading.assignAll(
      List.generate(secondaryUrls.length, (_) => false),
    );
  }

  /// حذف صورة (سواء رابط أو محلي)
  void removeProductImage(int index) {
    if (index < additionalImageUrls.length) {
      // حذف رابط من السيرفر
      additionalImageUrls.removeAt(index);
    } else {
      // حذف صورة محلية (Bytes)
      int byteIndex = index - additionalImageUrls.length;
      if (byteIndex < additionalImageBytes.length) {
        additionalImageBytes.removeAt(byteIndex);
        additionalImageLoading.removeAt(index); // الحفاظ على اتساق المؤشرات
      }
    }
  }

  /// تبديل الصورة الرئيسية
  void setAsMainImage(int index) {
    String? oldMainUrl = mainImageUrl.value;
    Uint8List? oldMainBytes = mainImageBytes.value;

    if (index < additionalImageUrls.length) {
      // الجديدة هي URL
      mainImageUrl.value = additionalImageUrls[index];
      mainImageBytes.value = null;

      additionalImageUrls.removeAt(index);
    } else {
      // الجديدة هي Bytes
      int byteIndex = index - additionalImageUrls.length;
      mainImageBytes.value = additionalImageBytes[byteIndex];
      mainImageUrl.value = null;

      additionalImageBytes.removeAt(byteIndex);
    }

    // إرجاع الرئيسية القديمة إلى القائمة الإضافية
    if (oldMainUrl != null) {
      additionalImageUrls.add(oldMainUrl);
    } else if (oldMainBytes != null) {
      additionalImageBytes.add(oldMainBytes);
    }
  }

  @override
  void onClose() {
    // تنظيف الموارد
    clearAllImages();
    super.onClose();
  }
}
*/