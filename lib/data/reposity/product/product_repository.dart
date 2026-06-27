import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_image_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_variation_image_controller.dart';
import 'package:stors_admin_panel/data/stor/models/brand_model.dart';
import 'package:stors_admin_panel/data/stor/models/category_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_category_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/exceptions/firebase_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/format_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/platform_exceptions.dart';
import 'package:stors_admin_panel/utils/helpers/cloud_helper_functions.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';
import 'package:stors_admin_panel/utils/helpers/network_manager.dart';
import 'package:stors_admin_panel/utils/popups/full_screen_loader.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class ProductRepository extends GetxController {
  static ProductRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final snapShot = await _db
          .collection("Products")
          // .where("IsFeatured", isEqualTo: true)
          //.limit(4)
          .get();
      return snapShot.docs.map((e) => ProductModel.fromSnapshot(e)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  // دالة البحث في Firestore
  Future<List<ProductModel>> searchProductsInFirestore(String query) async {
    try {
      // ملاحظة: \uf8ff هي حرف برمجي في اليونيكود يستخدم لإنهاء المدى في بحث Firestore
      final snapshot = await _db
          .collection('Products')
          .where('Title', isGreaterThanOrEqualTo: query)
          .where('Title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<List<ProductModel>> getAllFeaturedProducts() async {
    try {
      final snapShot = await _db
          .collection("Products")
          .where("IsFeatured", isEqualTo: true)
          .get();
      return snapShot.docs.map((e) => ProductModel.fromSnapshot(e)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<List<ProductModel>> getAllProductsByQuery(Query query) async {
    try {
      final querySnapshot = await query.get();
      final List<ProductModel> productList = querySnapshot.docs
          .map((e) => ProductModel.fromQuerySnapshot(e))
          .toList();
      return productList;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<List<ProductModel>> getFavouriteProducts(
    List<String> productsIds,
  ) async {
    try {
      final snapshot = await _db
          .collection("Products")
          .where(FieldPath.documentId, whereIn: productsIds)
          .get();
      final List<ProductModel> productList = snapshot.docs
          .map((e) => ProductModel.fromSnapshot(e))
          .toList();
      return productList;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<void> uploadDummyData(ProductModel product) async {
    // 1. تصفير النسبة المئوية عند بدء عملية جديدة
    // افترضنا أن uploadProgress معرف في ProductAdditionController
    final additionController = Get.find<ProductAdditionController>();
    additionController.uploadProgress.value = 0.0;

    // 2. تعيين معرف المنتج إذا كان جديداً
    if (product.id.isEmpty) {
      product.id = DateTime.now().millisecondsSinceEpoch.toString();
    }

    // تعيين رقم عشوائي للمنتج
    final random = Random();

    product.sortId = random.nextInt(1000000);
    //: random.nextInt(1000000), // رقم عشوائي كبير لتقليل فرص التكرار
    // تكوين قائمة للكلمات مفتاحية لعملية البحث
    List<String> keywords = ProductModel.generateKeywords(
      product.title,
      product.description,
      product.tags,
    );
    product.searchKeywords = keywords;
    product.titleLowercase = product.title.toLowerCase();

    try {
      // 3. التحقق من الاتصال
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoaders.errorSnackBar(
          title: "لا يوجد اتصال",
          message: "يرجى التحقق من الإنترنت",
        );
        return;
      }

      // 4. إظهار واجهة التحميل (التي تحتوي على Obx لمراقبة النسبة)
      TFullScreenLoader.openLoadingDialogForProduct(
        "جاري معالجة الصور ورفع البيانات...",
        TImages.docerAnimation,
      );

      // 5. جلب وحدات التحكم
      final imageController = ProductImageController.instance;
      final variationImageController =
          Get.find<ProductVariationImageController>();

      // --- [حساب إجمالي المهام لضبط النسبة المئوية] ---
      final mainImageBytes = imageController.getMainImageBytes();
      final additionalBytes = imageController.getAdditionalImageBytes();
      final variations = product.productVariation ?? [];

      int totalTasks = 0;
      if (mainImageBytes != null) totalTasks++;
      totalTasks += additionalBytes.length;
      totalTasks += variations.length;
      totalTasks += 1; // مهمة حفظ Firestore النهائية

      int completedTasks = 0;

      // دالة داخلية لتحديث التقدم
      void updateProgress() {
        completedTasks++;
        additionController.uploadProgress.value = completedTasks / totalTasks;
      }

      // خريطة كاش الرفع الإقليمية (تمنع رفع نفس الصورة مرتين للمنتج الحالي)
      // المفتاح: بصمة الصورة (Hash) | القيمة: الرابط السحابي المرفوع (Firebase URL)
      Map<String, String> uploadedProductImagesUrlsMap = {};

      // ==================== --- المرحلة الأولى: رفع الصورة الرئيسية --- ====================
      final String mainHash = imageController.mainImageHash.value;

      if (imageController.mainImageBytes.value != null &&
          imageController.mainImageBytes.value!.isNotEmpty) {
        final Future<Uint8List>? mainCompressionFuture =
            imageController.compressionTasks[mainHash];

        // انتظام الوعد بذكاء (إما انتهى سابقاً فيُجلب بلمح البصر، أو ينتظره الكود بلطف لحين اكتماله)
        final Uint8List compressedMainBytes = mainCompressionFuture != null
            ? await mainCompressionFuture
            : imageController.mainImageBytes.value!;

        debugPrint(
          "🚀 جاري رفع الصورة الرئيسية المضغوطة بحجم: ${(compressedMainBytes.length / 1024).toStringAsFixed(1)} KB",
        );

        final mainUrl = await TCloudHelperFunctions.uploadImageData(
          path: "Products/Images",
          imageData: compressedMainBytes,
          imageName: "${product.id}_main.jpg",
        );

        product.thumbnail = mainUrl;
        uploadedProductImagesUrlsMap[mainHash] =
            mainUrl; // تخزين الرابط في كاش الدورة الحالية
        updateProgress();
      } else if (product.thumbnail.isEmpty) {
        throw 'يجب تحديد صورة رئيسية للمنتج';
      }

      // ==================== --- المرحلة الثانية: رفع الصور الإضافية (بشكل متوازي ومحمي) --- ====================
      if (imageController.additionalImageBytes.isNotEmpty) {
        final List<Future<String>>
        additionalUploadTasks = imageController.additionalImageBytes.asMap().entries.map((
          entry,
        ) async {
          final int index = entry.key;
          final Uint8List rawBytes = entry.value;
          final String imgHash = imageController.additionalImageHashes[index];

          // 🌟 [حماية فائقة الفعالية]: إذا كانت الصورة هي نفسها الصورة الرئيسية أو مكررة في القائمة
          if (uploadedProductImagesUrlsMap.containsKey(imgHash)) {
            debugPrint(
              "🎯 [تخطي مكرر]: الصورة عند المؤشر $index متطابقة مع صورة مرفوعة مسبقاً، تم ربط الرابط تلقائياً.",
            );
            updateProgress();
            return uploadedProductImagesUrlsMap[imgHash]!;
          }

          // جلب وعد الضغط من الـ Controller
          final Future<Uint8List>? compressionFuture =
              imageController.compressionTasks[imgHash];
          final Uint8List compressedBytes = compressionFuture != null
              ? await compressionFuture
              : rawBytes;

          debugPrint(
            "🚀 جاري رفع الصورة الإضافية ($index) المضغوطة بحجم: ${(compressedBytes.length / 1024).toStringAsFixed(1)} KB",
          );

          final url = await TCloudHelperFunctions.uploadImageData(
            path: "Products/Images",
            imageData: compressedBytes,
            imageName:
                "${product.id}_additional_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg",
          );

          // حفظ الرابط في خريطة منع التكرار
          uploadedProductImagesUrlsMap[imgHash] = url;
          updateProgress();
          return url;
        }).toList();

        // تشغيل المهام بالتوازي للحصول على أعلى سرعة رفع ممكنة للشبكة
        product.images = await Future.wait(additionalUploadTasks);
      }

      /*
      // --- المرحلة الأولى: رفع الصورة الرئيسية ---
      if (mainImageBytes != null && mainImageBytes.isNotEmpty) {
        // الضغط يحدث في Isolate (خلفية) تلقائياً بناءً على تعديلنا السابق
        final compressedMain = await THelperFunctions.compressImageData(
          mainImageBytes,
        );
        product.thumbnail = await TCloudHelperFunctions.uploadImageData(
          path: "Products/Images",
          imageData: compressedMain,
          imageName: "${product.id}_main.jpg",
        );
        updateProgress(); // تحديث النسبة
      } else if (product.thumbnail.isEmpty) {
        throw 'يجب تحديد صورة رئيسية للمنتج';
      }

      // --- المرحلة الثانية: رفع الصور الإضافية (بشكل متوازي) ---
      if (additionalBytes.isNotEmpty) {
        final List<Future<String>> additionalUploadTasks = additionalBytes
            .asMap()
            .entries
            .map((entry) async {
              final compressed = await THelperFunctions.compressImageData(
                entry.value,
              );
              final url = await TCloudHelperFunctions.uploadImageData(
                path: "Products/Images",
                imageData: compressed,
                imageName: "${product.id}_additional_${entry.key}.jpg",
              );
              updateProgress(); // تحديث النسبة فور انتهاء كل صورة
              return url;
            })
            .toList();

        product.images = await Future.wait(additionalUploadTasks);
      }
      */

      // --- المرحلة الثالثة: رفع صور التنوعات (هندسة خالية من الأخطاء ومانعة للتكرار) ---
      // خريطة محلية لعملية الرفع الحالية: مفتاحها (بصمة الصورة) وقيمتها (رابط الرفع في الفايربيس)
      Map<String, String> uploadedFirebaseUrlsMap = {};

      if (product.productType == ProductType.variable.name &&
          variations.isNotEmpty) {
        for (var variation in variations) {
          final String vId = variation.id.trim();
          final String? imageHash =
              variationImageController.variationImageHashes[vId];

          // الحالة أ: المستخدم قام باختيار صورة جديدة لهذا الفاريشن ولها بصمة مسجلة
          if (imageHash != null && imageHash.isNotEmpty) {
            // 1. التحقق من كاش الرفع المحلي (إذا رُفعت نفس الصورة لفاريشن سابق في نفس الثواني الحالية)
            if (uploadedFirebaseUrlsMap.containsKey(imageHash)) {
              variation.image = uploadedFirebaseUrlsMap[imageHash]!;
              variationImageController.variationImageUrls[vId] =
                  uploadedFirebaseUrlsMap[imageHash]!;
              debugPrint(
                "🎯 [منع تكرار الرفع]: الفاريشن $vId أخذ نفس رابط الصورة المتطابقة مسبقاً.",
              );
              updateProgress();
              continue; // تخطي الرفع والذهاب للفاريشن التالي فوراً بسرعة فائقة!
            }

            // 2. جلب وعاء الضغط المجدول (الـ Future) من الـ Controller
            final Future<Uint8List>? compressionFuture =
                variationImageController.compressionTasks[imageHash];

            if (compressionFuture != null) {
              debugPrint(
                "⏳ جاري استدعاء الوعد (Future)... إذا انتهى الضغط سيمر فوراً، وإذا لم ينتهِ سينتظره بثبات.",
              );

              // هنا السحر: ننتظر الـ Future مباشرة، لا وجود لحلقات while البدائية!
              final Uint8List compressedBytes = await compressionFuture;

              debugPrint(
                "🚀 بدء رفع الصورة المضغوطة الموحدة للفاريشن ($vId) بحجم: ${(compressedBytes.length / 1024).toStringAsFixed(1)} KB",
              );

              // الرفع الفعلي للبايتات المضغوطة بشكل سليم ومؤكد
              final imageUrl = await TCloudHelperFunctions.uploadImageData(
                path: "Products/Variations",
                imageData: compressedBytes,
                imageName: "Var_${product.id}_$vId.jpg",
              );

              // حفظ الرابط في كاش الرفع وكاش الواجهة
              uploadedFirebaseUrlsMap[imageHash] = imageUrl;
              variation.image = imageUrl;
              variationImageController.variationImageUrls[vId] = imageUrl;
            }
          }
          // الحالة ب: المستخدم لم يغير الصورة، أو المنتج يتم تعديله ولديه رابط مسبق بالسيرفر
          else {
            final existingUrl =
                variationImageController.variationImageUrls[vId];
            if (existingUrl != null && existingUrl.isNotEmpty) {
              variation.image = existingUrl;
              debugPrint(
                "🔗 الاحتفاظ بالرابط السحابي القديم للفاريشن: $vId دون إهدار بيانات.",
              );
            }
          }

          updateProgress();
        }
      }

      /*
      // --- المرحلة الثالثة: رفع صور التنوعات (مؤمنة ومحمية من الفشل) ---
      Map<String, String> uploadedImagesMap = {};

      if (product.productType == ProductType.variable.name &&
          variations.isNotEmpty) {
        for (var variation in variations) {
          final String vId = variation.id.trim();

          // 1. التحقق من انتهاء الضغط في الخلفية (لحماية الصور التي ما زالت تحت المعالجة)
          int retryCount = 0;
          while (variationImageController.variationImageLoading[vId] == true &&
              retryCount < 10) {
            debugPrint(
              "⏳ الانتظار ثانية لانتهاء ضغط الصورة في الخلفية لمتغير: $vId",
            );
            await Future.delayed(const Duration(seconds: 1));
            retryCount++;
          }

          // 2. جلب البايتات من الكاش
          Uint8List? compressedBytes =
              variationImageController.variationImageBytes[vId];

          // 💡 حزام أمان إضافي: إذا لم يجد البايتات بالـ ID المباشر، نجرب الدالة الذكية المكتوبة مسبقاً لديك
          if (compressedBytes == null || compressedBytes.isEmpty) {
            compressedBytes = variationImageController.getImageBytes(vId);
          }

          // 3. التحقق المعالج والآمن للبايتات قبل اتخاذ قرار الرفع
          if (compressedBytes != null && compressedBytes.isNotEmpty) {
            // 🔥 [تأمين الضغط الإجباري]: إذا كانت البايتات المسترجعة لا تزال بحجمها الكبير (أكبر من 300 كيلوبايت)
            // فهذا يعني أن الكاش يحتوي على الصورة الخام، ونقوم بضغطها فوراً هنا لحل المشكلة نهائياً.
            if (compressedBytes.length > 300 * 1024) {
              debugPrint(
                "⚡ تنبيه: كاش الفاريشن $vId غير مضغوط، جاري الضغط المباشر الآن...",
              );
              compressedBytes = await THelperFunctions.compressImageDirectly(
                compressedBytes,
              );
              // تحديث الكاش لكي لا تتكرر العملية
              variationImageController.variationImageBytes[vId] =
                  compressedBytes;
            }

            // حساب بصمة حقيقية للملف لمنع تكرار رفع نفس الصورة لفاريشنز مختلفة
            final String imageHash =
                "${compressedBytes.length}_${compressedBytes.first}_${compressedBytes.last}";

            // فحص كاش الروابط الحالي
            if (uploadedImagesMap.containsKey(imageHash)) {
              variation.image = uploadedImagesMap[imageHash]!;
              debugPrint(
                "🎯 تم تعيين الرابط من كاش العملية الحالية للفاريشن: $vId",
              );
            } else if (variationImageController.variationImageUrls[vId] !=
                    null &&
                variationImageController.variationImageUrls[vId]!.isNotEmpty) {
              variation.image =
                  variationImageController.variationImageUrls[vId]!;
              debugPrint(
                "🎯 تم تعيين الرابط الجاهز المسترجع من كاش الخلفية للفاريشن: $vId",
              );
            } else {
              // الرفع الفعلي للبايتات المضغوطة والمؤكدة بنسبة 100%
              debugPrint(
                "🚀 جاري رفع صورة الفاريشن ($vId) المضغوطة بنجاح (${(compressedBytes.length / 1024).toStringAsFixed(1)} KB)...",
              );

              final imageUrl = await TCloudHelperFunctions.uploadImageData(
                path: "Products/Variations",
                imageData: compressedBytes,
                imageName: "Var_${product.id}_$vId.jpg",
              );

              uploadedImagesMap[imageHash] = imageUrl;
              variation.image = imageUrl;

              // تحديث كاش الواجهة العام بالرابط الجديد
              variationImageController.variationImageUrls[vId] = imageUrl;
            }
          } else {
            // في حال لم يجد بايتات مطلقاً (تعديل منتج بدون تغيير الصورة مثلاً)، نستخدم الرابط القديم المتوفر
            final existingUrl =
                variationImageController.variationImageUrls[vId];
            if (existingUrl != null && existingUrl.isNotEmpty) {
              variation.image = existingUrl;
            }
          }

          updateProgress();
        }
      }
      */

      /*
      // --- المرحلة الثالثة: رفع صور التنوعات (مؤمنة ومربوطة بكاش الخلفية) ---
      Map<String, String> uploadedImagesMap = {};

      if (product.productType == ProductType.variable.name &&
          variations.isNotEmpty) {
        for (var variation in variations) {
          final String vId = variation.id.trim();

          // 🌟 أولاً: التحقق من انتهاء الضغط في الخلفية. إذا كانت الصورة لا تزال تضغط، ننتظرها!
          int retryCount = 0;
          while (variationImageController.variationImageLoading[vId] == true &&
              retryCount < 10) {
            debugPrint(
              "⏳ الانتظار ثانية لانتهاء ضغط الصورة في الخلفية لمتغير: $vId",
            );
            await Future.delayed(const Duration(seconds: 1));
            retryCount++;
          }

          // 🌟 ثانياً: جلب البايتات المضغوطة مباشرة من الخريطة المحدثة بالخلفية
          final Uint8List? compressedBytes =
              variationImageController.variationImageBytes[vId];

          if (compressedBytes != null && compressedBytes.isNotEmpty) {
            // حساب بصمة حقيقية سريعة للملف المضغوط
            final String imageHash =
                "${compressedBytes.length}_${compressedBytes.first}_${compressedBytes.last}";

            // 1. التحقق من كاش الروابط لمنع التكرار (سواء كاش الدورة الحالية أو كاش الدالة الخلفية)
            if (uploadedImagesMap.containsKey(imageHash)) {
              variation.image = uploadedImagesMap[imageHash]!;
              debugPrint("🎯 تم تعيين الرابط من كاش العملية الحالية");
            } else if (variationImageController.variationImageUrls[vId] !=
                    null &&
                variationImageController.variationImageUrls[vId]!.isNotEmpty) {
              // إذا كانت دالة الخلفية قد وجدت الرابط مسبقاً ووفرت علينا الرفع
              variation.image =
                  variationImageController.variationImageUrls[vId]!;
              debugPrint(
                "🎯 تم تعيين الرابط الجاهز المسترجع من كاش الخلفية المسبق",
              );
            } else {
              // 2. إذا لم تكن مرفوعة مسبقاً، نرفع البايتات المضغوطة (التي تأكدنا أنها مستخرجة من الخريطة)
              debugPrint(
                "🚀 جاري رفع الصورة المضغوطة المستخرجة من الكاش (${(compressedBytes.length / 1024).toStringAsFixed(1)} KB)...",
              );

              final imageUrl = await TCloudHelperFunctions.uploadImageData(
                path: "Products/Variations",
                imageData:
                    compressedBytes, // <--- البايتات المضغوطة الحقيقية هنا
                imageName: "Var_${product.id}_$vId.jpg",
              );

              uploadedImagesMap[imageHash] = imageUrl;
              variation.image = imageUrl;

              // تحديث كاش الواجهة العام بالرابط الجديد لاستخدامه مستقبلاً
              variationImageController.variationImageUrls[vId] = imageUrl;
            }
          } else {
            // التعامل مع الروابط النصية الموجودة مسبقاً في حال لم يختر صورة جديدة
            final existingUrl =
                variationImageController.variationImageUrls[vId];
            if (existingUrl != null) variation.image = existingUrl;
          }

          updateProgress();
        }
      }
      */

      // --- المرحلة الثالثة: رفع صور التنوعات (بشكل متوازي) ---
      //*/ --- المرحلة الثالثة: رفع صور التنوعات (بشكل ذكي) ---
      /*
      Map<String, String> uploadedImagesMap =
          {}; // مفتاحها بصمة الصورة وقيمتها الرابط

      if (product.productType == ProductType.variable.name &&
          variations.isNotEmpty) {
        // نستخدم حلقة عادية أو Future.forEach للتحكم في الـ Map بشكل آمن
        for (var variation in variations) {
          final bytes = variationImageController.getImageBytes(
            variation.id.trim(),
          );

          if (bytes != null && bytes.isNotEmpty) {
            // 1. توليد بصمة فريدة لمحتوى الصورة (MD5 أو SHA256)
            // هذا يضمن أن الصور المتطابقة محتوياً سيكون لها نفس الـ Key
            final String imageHash = bytes.hashCode
                .toString(); // أو استخدم حزمة crypto لعمل md5(bytes)

            // 2. التحقق مما إذا كانت هذه الصورة قد رُفعت بالفعل في هذه العملية
            if (uploadedImagesMap.containsKey(imageHash)) {
              // إذا كانت موجودة، نأخذ الرابط فوراً دون رفع
              variation.image = uploadedImagesMap[imageHash]!;
            } else {
              // إذا لم تكن موجودة، نقوم بضغطها ورفعها
              /*final compressedVar = await THelperFunctions.compressImageData(
                bytes,
              );*/

              final imageUrl = await TCloudHelperFunctions.uploadImageData(
                path: "Products/Variations",
                imageData: bytes,
                imageName: "Var_${product.id}_${variation.id}.jpg",
              );

              // تخزين الرابط في الـ Map لاستخدامه مع المتغيرات القادمة المتشابهة
              uploadedImagesMap[imageHash] = imageUrl;
              variation.image = imageUrl;
            }
          } else {
            // التعامل مع الروابط الموجودة مسبقاً
            final existingUrl =
                variationImageController.variationImageUrls[variation.id];
            if (existingUrl != null) variation.image = existingUrl;
          }

          updateProgress();
        }
      }*/
      /*Map<Uint8List?, String> varImaUrl = {};
      if (product.productType == ProductType.variable.name &&
          variations.isNotEmpty) {
        final List<Future<void>> variationTasks = variations.map((
          variation,
        ) async {
          final bytes = variationImageController.getImageBytes(
            variation.id.trim(),
          );

          if (bytes != null && bytes.isNotEmpty) {
            final compressedVar = await THelperFunctions.compressImageData(
              bytes,
            );
            if (varImaUrl.containsKey(bytes)) {
              variation.image =
                  varImaUrl[bytes] ??
                  await TCloudHelperFunctions.uploadImageData(
                    path: "Products/Variations",
                    imageData: compressedVar,
                    imageName: "Var_${product.id}_${variation.id}.jpg",
                  );
            } else {
              final imageUrl = await TCloudHelperFunctions.uploadImageData(
                path: "Products/Variations",
                imageData: compressedVar,
                imageName: "Var_${product.id}_${variation.id}.jpg",
              );
              varImaUrl[bytes] = imageUrl;
              variation.image = imageUrl;
            }
          } else {
            final existingUrl =
                variationImageController.variationImageUrls[variation.id];
            if (existingUrl != null) variation.image = existingUrl;
          }
          updateProgress(); // تحديث النسبة فور انتهاء كل متغير
        }).toList();

        await Future.wait(variationTasks);
      }*/

      // --- المرحلة الرابعة: حفظ بيانات المنتج في Firestore ---
      product.date = DateTime.now();
      product.storId = AuthenticationRepository.instance.authUser!.uid;
      await _db.collection("Products").doc(product.id).set(product.toJson());
      updateProgress(); // المهمة الأخيرة اكتملت

      // 6. الإغلاق والنجاح
      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
        title: "تم بنجاح",
        message: "تم رفع المنتج وبياناته بنجاح",
      );
    } catch (e) {
      TFullScreenLoader.stopLoading();
      debugPrint("Upload Error: $e");
      TLoaders.errorSnackBar(title: "خطأ", message: e.toString());
    }
  }

  /*
  Future<void> uploadDummyData(ProductModel product) async {
    // 1. تعيين معرف المنتج إذا كان جديداً لضمان ثبات أسماء الملفات
    if (product.id.isEmpty) {
      product.id = DateTime.now().millisecondsSinceEpoch.toString();
    }

    try {
      // 2. إظهار واجهة التحميل للمستخدم
      TFullScreenLoader.openLoadingDialog(
        "جاري رفع البيانات... قد يستغرق هذا وقتاً حسب حجم الصور",
        TImages.docerAnimation,
      );

      // 3. التحقق من وجود اتصال بالإنترنت
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: "لا يوجد اتصال",
          message: "يرجى التحقق من شبكة الإنترنت",
        );
        return;
      }

      // 4. جلب وحدات التحكم (Controllers) الخاصة بالصور
      final imageController = ProductImageController.instance;
      final variationImageController =
          Get.find<ProductVariationImageController>();

      // --- المرحلة الأولى: رفع الصورة الرئيسية ---
      final mainImageBytes = imageController.getMainImageBytes();
      if (mainImageBytes != null && mainImageBytes.isNotEmpty) {
        final compressedMain = await THelperFunctions.compressImageData(
          mainImageBytes,
        );
        product.thumbnail = await TCloudHelperFunctions.uploadImageData(
          path: "Products/Images",
          imageData: compressedMain,
          imageName: "${product.id}_main.jpg",
        );
      } else if (product.thumbnail.isEmpty) {
        throw 'يجب تحديد صورة رئيسية للمنتج';
      }

      // --- المرحلة الثانية: رفع الصور الإضافية (بشكل متوازي) ---
      final additionalBytes = imageController.getAdditionalImageBytes();
      if (additionalBytes.isNotEmpty) {
        // إنشاء قائمة من المهام (Tasks) لرفع الصور دون انتظار كل واحدة على حدة
        final List<Future<String>> additionalUploadTasks = additionalBytes
            .asMap()
            .entries
            .map((entry) async {
              final compressed = await THelperFunctions.compressImageData(
                entry.value,
              );
              return TCloudHelperFunctions.uploadImageData(
                path: "Products/Images",
                imageData: compressed,
                imageName: "${product.id}_additional_${entry.key}.jpg",
              );
            })
            .toList();

        // تشغيل جميع مهام الرفع معاً وانتظار النتائج
        final additionalUrls = await Future.wait(additionalUploadTasks);
        product.images = additionalUrls;
      }

      // --- المرحلة الثالثة: رفع صور التنوعات (Variations) بشكل متوازي ---
      if (product.productType == ProductType.variable.name &&
          product.productVariation != null) {
        // تصفية التنوعات التي تحتوي على صور محلية جديدة فقط للرفع
        final List<Future<void>>
        variationTasks = product.productVariation!.map((variation) async {
          final bytes = variationImageController.getImageBytes(
            variation.id.trim(),
          );

          if (bytes != null && bytes.isNotEmpty) {
            // ضغط ورفع صورة التنوع
            final compressedVar = await THelperFunctions.compressImageData(
              bytes,
            );
            final url = await TCloudHelperFunctions.uploadImageData(
              path: "Products/Variations",
              imageData: compressedVar,
              imageName: "Var_${product.id}_${variation.id}.jpg",
            );
            variation.image = url; // تحديث رابط الصورة في كائن التنوع
          } else {
            // إذا لم توجد صورة جديدة، استخدم الرابط الموجود مسبقاً (في حالة التعديل)
            final existingUrl =
                variationImageController.variationImageUrls[variation.id];
            if (existingUrl != null) variation.image = existingUrl;
          }
        }).toList();

        // تنفيذ رفع صور التنوعات بالكامل في وقت واحد
        await Future.wait(variationTasks);
      }

      // --- المرحلة الرابعة: حفظ بيانات المنتج النهائية في Firestore ---
      product.storId = AuthenticationRepository.instance.authUser!.uid;

      await _db.collection("Products").doc(product.id).set(product.toJson());

      // 5. إغلاق واجهة التحميل وإظهار رسالة نجاح
      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
        title: "تم بنجاح",
        message: "تم حفظ المنتج وبياناته بنجاح",
      );
    } on FirebaseException catch (e) {
      TFullScreenLoader.stopLoading();
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      TFullScreenLoader.stopLoading();
      throw TPlatformException(e.code).message;
    } catch (e) {
      TFullScreenLoader.stopLoading();
      debugPrint("Error: $e");
      throw "حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى";
    }
  }
*/
  /*
  Future<void> uploadDummyData(ProductModel product) async {
    // تعيين معرف المنتج إذا لم يكن موجوداً حتى تكون أسماء الصور ثابتة
    if (product.id.isEmpty) {
      product.id = DateTime.now().millisecondsSinceEpoch.toString();
    }
    debugPrint("DEBUG: uploadDummyData called with product ID: ${product.id}");
    try {
      // final storage = Get.put(TfirebaseStorageService());
      TFullScreenLoader.openLoadingDialog(
        "We are Load your Data...",
        TImages.docerAnimation,
      );

      final isConected = await NetworkManager.instance.isConnected();
      if (!isConected) {
        TFullScreenLoader.stopLoading();
        debugPrint("DEBUG: No network connection");
        return;
      }

      debugPrint("DEBUG: Product JSON generated");
      debugPrint("product:${product.toJson()}");
      debugPrint("product:${product.productAttribute!.map((e) => e.toJson())}");
      debugPrint("product:${product.productVariation!.map((e) => e.toJson())}");

      // رفع صور المنتج الرئيسية والإضافية
      try {
        final imageController = ProductImageController.instance;
        final mainImageBytes = imageController.getMainImageBytes();
        final additionalImageBytes = imageController.getAdditionalImageBytes();

        // رفع الصورة الرئيسية
        if (mainImageBytes != null && mainImageBytes.isNotEmpty) {
          try {
            // ضغط الصورة قبل الرفع
            final compressedMainImage =
                await THelperFunctions.compressImageData(mainImageBytes);
            final url = await TCloudHelperFunctions.uploadImageData(
              path: "Products/Images",
              imageData: compressedMainImage,
              imageName: "${product.id}_main.jpg",
            );
            product.thumbnail = url;
          } catch (e) {
            debugPrint('Error uploading main image: $e');
            throw 'فشل في رفع الصورة الرئيسية: $e';
          }
        } else if (product.thumbnail.isEmpty) {
          throw 'يجب تحديد صورة رئيسية للمنتج';
        }

        // رفع الصور الإضافية
        if (additionalImageBytes.isNotEmpty) {
          List<String> imageUrls = [];
          for (int i = 0; i < additionalImageBytes.length; i++) {
            final bytes = additionalImageBytes[i];
            if (bytes.isNotEmpty) {
              try {
                // ضغط صورة الفارياشن
                final compressedVarImage =
                    await THelperFunctions.compressImageData(bytes);
                final url = await TCloudHelperFunctions.uploadImageData(
                  path: "Products/Images",
                  imageData: compressedVarImage,
                  imageName: "${product.id}_additional_$i.jpg",
                );
                imageUrls.add(url);
              } catch (e) {
                debugPrint('Error uploading additional image $i: $e');
                // متابعة مع الصور الأخرى
              }
            }
          }
          if (imageUrls.isNotEmpty) {
            product.images = imageUrls;
          }
        }
      } catch (e) {
        debugPrint('Error in image upload process: $e');
        // لا تتوقف عن الحفظ، الصور اختيارية
      }

      // --- قسم رفع صور الفارياشن المحسن ---
      if (product.productType == ProductType.variable.name &&
          product.productVariation != null) {
        debugPrint("DEBUG: Starting variation image upload...");
        try {
          // التأكد من الوصول للكنترولر
          ProductVariationImageController variationImageController;
          try {
            variationImageController =
                Get.find<ProductVariationImageController>();
          } catch (e) {
            variationImageController = Get.put(
              ProductVariationImageController(),
            );
          }

          // طباعة حالة الـ Controller
          variationImageController.debugPrintImageData();

          // سطر للفحص: طباعة عدد الصور الموجودة في الذاكرة حالياً
          debugPrint(
            "Debug: Total Images in Controller: ${variationImageController.variationImageBytes.length}",
          );

          for (var variation in product.productVariation!) {
            debugPrint("DEBUG: Checking variation ${variation.id}");
            // جلب البيانات الثنائية باستخدام معرف الاختيار
            final cleanId = variation.id.trim();
            final imageBytes = variationImageController.getImageBytes(cleanId);

            if (imageBytes != null && imageBytes.isNotEmpty) {
              debugPrint(
                "DEBUG: Found ${imageBytes.length} bytes for variation ${variation.id}",
              );
              // إنشاء اسم فريد
              final imageName = "Var_${product.id}_${variation.id}.jpg";

              try {
                // 👈 السطر المفقود: ضغط الصورة أولاً!
                final compressedVarImage =
                    await THelperFunctions.compressImageData(imageBytes);
                final url = await TCloudHelperFunctions.uploadImageData(
                  path: "Products/Variations",
                  imageData: compressedVarImage,
                  imageName: imageName,
                );

                variation.image = url;
                debugPrint(
                  '✅ Successfully uploaded variation image for ID: ${variation.id} -> $url',
                );
              } catch (e) {
                debugPrint(
                  '❌ Failed to upload image for variation ${variation.id}: $e',
                );
              }
            } else {
              debugPrint("DEBUG: No local bytes for variation ${variation.id}");
              // إذا لم توجد صورة جديدة، تحقق إذا كان هناك رابط قديم (في حالة التعديل)
              final existingUrl =
                  variationImageController.variationImageUrls[variation.id];
              if (existingUrl != null) {
                variation.image = existingUrl;
                debugPrint(
                  "DEBUG: Using existing URL for variation ${variation.id}: $existingUrl",
                );
              } else {
                debugPrint(
                  '⚠️ No image data found for variation: ${variation.id}',
                );
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error in variation image upload process: $e');
        }
      }

      // رفع صور الفارياشن إذا كانت موجودة
      /* if (product.productType == ProductType.variable.toString() &&
          product.productVariation != null) {
        try {
          // استخدم findOrPut أو تأكد من أن الكنترولر محقون بالفعل
          final variationImageController =
              Get.find<ProductVariationImageController>();

          for (var variation in product.productVariation!) {
            // 1. جلب البيانات الثنائية للصورة باستخدام معرف الاختيار (Variation ID)
            final imageBytes = variationImageController.getImageBytes(
              variation.id,
            );

            if (imageBytes != null && imageBytes.isNotEmpty) {
              // 2. إنشاء اسم فريد للصورة لتجنب التداخل
              final imageName =
                  "Var_${product.id}_${variation.id}_${DateTime.now().millisecondsSinceEpoch}.jpg";

              try {
                // 3. رفع الصورة
                final url = await TCloudHelperFunctions.uploadImageData(
                  path: "Products/Variations",
                  imageData: imageBytes,
                  imageName: imageName,
                );

                // 4. تحديث رابط الصورة في كائن الـ variation
                variation.image = url;
                debugPrint('Successfully uploaded variation image: $url');
              } catch (e) {
                debugPrint(
                  'Failed to upload image for variation ${variation.id}: $e',
                );
              }
            } else {
              debugPrint(
                'No local image bytes found for variation: ${variation.id}',
              );
            }
          }
        } catch (e) {
          debugPrint('Error accessing ProductVariationImageController: $e');
        }
      }*/
      /*
      // رفع صور الفارياشن إذا كانت موجودة
      if (product.productType == ProductType.variable.toString() &&
          product.productVariation != null) {
        try {
          final imageController = Get.find<ProductVariationImageController>();

          for (var variation in product.productVariation!) {
            // التحقق من وجود صورة محلية (bytes) في المراقب
            final imageBytes = imageController.getImageBytes(variation.id);

            if (imageBytes != null && imageBytes.isNotEmpty) {
              try {
                // رفع الصورة إلى Firebase Storage
                final url = await TCloudHelperFunctions.uploadImageData(
                  path: "Products/Variations",
                  imageData: imageBytes,
                  imageName: "${product.id}_${variation.id}.jpg",
                );
                variation.image = url;
              } catch (e) {
                debugPrint(
                  'Error uploading variation image for ${variation.id}: $e',
                );
                // متابعة مع الفارياشن الأخرى
              }
            }
          }
        } catch (e) {
          debugPrint('Error in variation image upload: $e');
          // صور الفارياشن اختيارية
        }
      }*/
      product.storId = AuthenticationRepository.instance.authUser!.uid;
      try {
        final docRef = _db
            .collection("Products")
            .doc(product.id); // إنشاء مرجع مستند للحصول على ID
        await docRef.set(product.toJson()); // الحفظ النهائي
        debugPrint("DEBUG: Product document saved with ID: ${docRef.id}");
        //await _db.collection("Products").doc().set(product.toJson());

        TFullScreenLoader.stopLoading();
        debugPrint("DEBUG: uploadDummyData completed successfully");
      } catch (e) {
        debugPrint("DEBUG ERROR: Firestore Save Failed: $e");
        throw "فشل حفظ بيانات المنتج في قاعدة البيانات: $e";
      }
      // إغلاق اللودر فقط بعد النجاح التام
      TFullScreenLoader.stopLoading();
      debugPrint("DEBUG: uploadDummyData completed successfully");
    } on FirebaseException catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: "Oh Snap!", message: e);
      throw TFirebaseException(e.code).message;
    } on FormatException catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: "Oh Snap!", message: e);
      throw TFormatException();
    } on PlatformException catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: "Oh Snap!", message: e);
      throw TPlatformException(e.code).message;
    } catch (e) {
      TFullScreenLoader.stopLoading();
      throw "somthing went wrong, pleas try agin";
    }
  }
*/
  // أضف هذا المتغير في ProductRepository
  DocumentSnapshot? lastDocument;

  Future<List<ProductModel>> getProducts({int limit = 20}) async {
    try {
      Query query = _db
          .collection("Products")
          .where(
            'StorId',
            isEqualTo: AuthenticationRepository.instance.authUser!.uid,
          )
          .orderBy('Title') // الترتيب ضروري لعمل Pagination بشكل صحيح
          .limit(limit);

      // إذا لم تكن هذه المرة الأولى، ابدأ من بعد آخر وثيقة جلبناها
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final querySnapshot = await query.get();

      // حفظ آخر وثيقة للعملية القادمة
      if (querySnapshot.docs.isNotEmpty) {
        lastDocument = querySnapshot.docs.last;
      }

      return querySnapshot.docs
          .map((doc) => ProductModel.fromQuerySnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  /// دالة حذف المنتج وصورته
  Future<void> deleteProduct(String productId, String imageUrl) async {
    try {
      // 1. حذف الصورة من Firebase Storage أولاً
      if (imageUrl.isNotEmpty) {
        // نستخدم المرجع (Reference) من الرابط مباشرة
        final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete();
      }

      // 2. حذف وثيقة المنتج من Firestore
      await _db.collection("Products").doc(productId).delete();
    } on FirebaseException catch (e) {
      throw 'خطأ في Firebase: ${e.message}';
    } on FormatException catch (_) {
      throw 'تنسيق الرابط غير صحيح';
    } catch (e) {
      throw 'حدث خطأ غير متوقع: $e';
    }
  }

  /// تحديث حالة ظهور المنتج (إظهار/إخفاء)
  Future<void> updateProductVisibility(
    String productId,
    ProductVisibility visibility,
  ) async {
    try {
      await _db.collection('Products').doc(productId).update({
        'ProductVisibility': visibility.name,
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  /// تحديث سعر المنتج لجميع الأنواع (بسيط أو متغير)
  Future<void> updateProductPrice(
    String productId,
    double newPrice, {
    List<ProductVariationModel>? variations,
  }) async {
    try {
      final Map<String, dynamic> data = {'Price': newPrice};

      // إذا كان المنتج يحتوي على متغيرات، نقوم بتحديث السعر في كل متغير أيضاً
      if (variations != null && variations.isNotEmpty) {
        for (var variation in variations) {
          variation.price = newPrice;
        }
        data['ProductVariation'] = variations.map((e) => e.toJson()).toList();
      }

      await _db.collection('Products').doc(productId).update(data);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final snapshot = await _db.collection("Categories").get();
      final list = snapshot.docs
          .map((e) => CategoryModel.fromSnapshot(e))
          .toList();
      return list;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<List<ProductModel>> getProductForBrand({
    required String brandId,
    int limit = -1,
  }) async {
    try {
      final snapShot = limit == -1
          ? await _db
                .collection("Products")
                .where("Brande.Id", isEqualTo: brandId)
                .get()
          : await _db
                .collection("Products")
                .where("Brande.Id", isEqualTo: brandId)
                .limit(limit)
                .get();
      return snapShot.docs.map((e) => ProductModel.fromSnapshot(e)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<List<ProductModel>> getProductForCategory({
    required String categoryId,
    int limit = 4,
  }) async {
    try {
      List<ProductModel> products = [];
      final snapShot = limit == -1
          ? await _db
                .collection("ProductCategory")
                .where("categoryId", isEqualTo: categoryId)
                .get()
          : await _db
                .collection("ProductCategory")
                .where("categoryId", isEqualTo: categoryId)
                .limit(limit)
                .get();

      List<String> productIds = snapShot.docs
          .map((e) => e["productId"] as String)
          .toList();

      debugPrint("***************************************");
      productIds.map((e) => debugPrint("****$e****"));
      for (int i = 0; i < productIds.length; i++) {
        debugPrint("****${productIds[i]}****");
      }
      debugPrint(productIds.length.toString());
      debugPrint("***************************************");
      if (productIds.isNotEmpty && productIds != 0) {
        final productQuery = await _db
            .collection("Products")
            .where(FieldPath.documentId, whereIn: productIds)
            .get();
        products = productQuery.docs
            .map((e) => ProductModel.fromSnapshot(e))
            .toList();
      }

      return products;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<String> creatProduct(ProductModel product) async {
    try {
      // إنشاء معرف فريد للمنتج إذا لم يكن موجوداً
      if (product.id.isEmpty) {
        product.id = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // التحقق من الاتصال بالإنترنت
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        throw 'لا يوجد اتصال بالإنترنت';
      }

      // رفع صور المنتج الرئيسية والإضافية
      try {
        final imageController = ProductImageController.instance;
        final mainImageBytes = imageController.getMainImageBytes();
        final additionalImageBytes = imageController.getAdditionalImageBytes();

        // رفع الصورة الرئيسية
        if (mainImageBytes != null && mainImageBytes.isNotEmpty) {
          try {
            final url = await TCloudHelperFunctions.uploadImageData(
              path: "Products/Images",
              imageData: mainImageBytes,
              imageName: "${product.id.trim()}_main.jpg",
            );
            product.thumbnail = url;
          } catch (e) {
            debugPrint('Error uploading main image: $e');
            throw 'فشل في رفع الصورة الرئيسية: $e';
          }
        } else if (product.thumbnail.isEmpty) {
          throw 'يجب تحديد صورة رئيسية للمنتج';
        }

        // رفع الصور الإضافية
        if (additionalImageBytes.isNotEmpty) {
          List<String> imageUrls = [];
          for (int i = 0; i < additionalImageBytes.length; i++) {
            final bytes = additionalImageBytes[i];
            if (bytes.isNotEmpty) {
              try {
                final url = await TCloudHelperFunctions.uploadImageData(
                  path: "Products/Images",
                  imageData: bytes,
                  imageName: "${product.id}_additional_$i.jpg",
                );
                imageUrls.add(url);
              } catch (e) {
                debugPrint('Error uploading additional image $i: $e');
                // متابعة مع الصور الأخرى
              }
            }
          }
          if (imageUrls.isNotEmpty) {
            product.images = imageUrls;
          }
        }
      } catch (e) {
        debugPrint('Error in image upload process: $e');
        throw 'فشل في رفع الصور: $e';
      }

      // رفع صور المتغيرات إذا كانت موجودة
      if (product.productType == ProductType.variable.name &&
          product.productVariation != null) {
        try {
          ProductVariationImageController variationImageController;
          try {
            variationImageController =
                Get.find<ProductVariationImageController>();
          } catch (e) {
            variationImageController = Get.put(
              ProductVariationImageController(),
            );
          }

          debugPrint(
            "Debug: Total Images in Controller: ${variationImageController.variationImageBytes.length}",
          );

          // طباعة حالة الـ Controller
          variationImageController.debugPrintImageData();

          for (var variation in product.productVariation!) {
            final imageBytes = variationImageController.getImageBytes(
              variation.id,
            );

            if (imageBytes != null && imageBytes.isNotEmpty) {
              final imageName = "Var_${product.id}_${variation.id}.jpg";

              try {
                final url = await TCloudHelperFunctions.uploadImageData(
                  path: "Products/Variations",
                  imageData: imageBytes,
                  imageName: imageName,
                );

                variation.image = url;
                debugPrint(
                  '✅ Successfully uploaded variation image for ID: ${variation.id}',
                );
              } catch (e) {
                debugPrint(
                  '❌ Failed to upload image for variation ${variation.id}: $e',
                );
                throw 'فشل في رفع صورة المتغير ${variation.id}: $e';
              }
            } else {
              debugPrint(
                '⚠️ No image data found for variation: ${variation.id}',
              );
            }
          }
        } catch (e) {
          debugPrint('❌ Error in variation image upload process: $e');
          throw 'فشل في رفع صور المتغيرات: $e';
        }
      }

      // تعيين معرف المتجر
      product.storId = AuthenticationRepository.instance.authUser!.uid;

      // حفظ المنتج في Firestore
      final result = await _db.collection("Products").add(product.toJson());
      return result.id;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<String> creatProductCategory(
    ProductCategoryModel productCategory,
  ) async {
    try {
      final result = await _db
          .collection("ProductCategory")
          .add(productCategory.toJson());
      return result.id;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<List<BrandModel>> getAllBrands() async {
    try {
      final snapshot = await _db.collection("Brands").get();
      final result = snapshot.docs
          .map((e) => BrandModel.fromSnapshot(e))
          .toList();
      return result;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }
}
