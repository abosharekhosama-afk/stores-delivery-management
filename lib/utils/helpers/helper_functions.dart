import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart'
    as img; // استيراد مكتبة imageimport 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../constants/enums.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class THelperFunctions {
  static DateTime getStartOfWeek(DateTime date) {
    final int daysUntilMonday = date.weekday - 1;
    final DateTime startOfWeek = date.subtract(Duration(days: daysUntilMonday));
    return DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
      0,
      0,
      0,
      0,
      0,
    );
  }

  static Color getOrderStatusColor(OrderStatus value) {
    if (OrderStatus.pending == value) {
      return Colors.blue;
    } else if (OrderStatus.processing == value) {
      return Colors.orange;
    } else if (OrderStatus.shipped == value) {
      return Colors.purple;
    } else if (OrderStatus.delivered == value) {
      return Colors.green;
    } else if (OrderStatus.cancelled == value) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  static Color? getColor(String value) {
    /// Define your product specific colors here and it will match the attribute colors and show specific 🟠🟡🟢🔵🟣🟤

    if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Red') {
      return Colors.red;
    } else if (value == 'Blue') {
      return Colors.blue;
    } else if (value == 'Pink') {
      return Colors.pink;
    } else if (value == 'Grey') {
      return Colors.grey;
    } else if (value == 'Purple') {
      return Colors.purple;
    } else if (value == 'Black') {
      return Colors.black;
    } else if (value == 'White') {
      return Colors.white;
    } else if (value == 'Yellow') {
      return Colors.yellow;
    } else if (value == 'Orange') {
      return Colors.deepOrange;
    } else if (value == 'Brown') {
      return Colors.brown;
    } else if (value == 'Teal') {
      return Colors.teal;
    } else if (value == 'Indigo') {
      return Colors.indigo;
    } else {
      return null;
    }
  }

  static void showSnackBar(String message) {
    ScaffoldMessenger.of(
      Get.context!,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static void showAlert(String title, String message) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '${text.substring(0, maxLength)}...';
    }
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  static double screenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }

  static String getFormattedDate(
    DateTime date, {
    String format = 'dd MMM yyyy',
  }) {
    return DateFormat(format).format(date);
  }

  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static List<Widget> wrapWidgets(List<Widget> widgets, int rowSize) {
    final wrappedList = <Widget>[];
    for (var i = 0; i < widgets.length; i += rowSize) {
      final rowChildren = widgets.sublist(
        i,
        i + rowSize > widgets.length ? widgets.length : i + rowSize,
      );
      wrappedList.add(Row(children: rowChildren));
    }
    return wrappedList;
  }
  /*
  // دالة الضغط السريع (Single-Pass Execution)
  static Future<Uint8List> _fastBackgroundCompress(Uint8List bytes) async {
    try {
      final double imageSizeInMB = bytes.length / (1024 * 1024);

      // إذا كانت الصورة صغيرة بالفعل (أقل من 700 كيلوبايت) لا داعي لتبديد الطاقة في ضغطها
      if (imageSizeInMB < 0.7) return bytes;

      // تنفيذ ضغطة واحدة مباشرة فائقة السرعة بناءً على حجم الصورة الأصلية
      // تم اختيار الأبعاد 1440x2560 (دقة 2K للمحافظة الكاملة على التفاصيل الحادة للألمنيوم والمنتجات)
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1440,
        minHeight: 2560,
        quality:
            75, // الرقم السحري: أفضل نسبة تقليص للحجم مقابل صفر خسارة بالعين المجردة
        format: CompressFormat.jpeg,
        autoCorrectionAngle:
            true, // يمنع تدوير الصور الملتقطة من الكاميرا بشكل خاطئ
      );

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      if (kDebugMode) print("🎯 خطأ في الضغط السريع: $e");
      return bytes; // إرجاع الصورة الأصلية في حال حدوث أي استثناء لضمان استقرار التطبيق
    }
  }
*/

  // دالة الضغط السريع والمضمون (تستهدف دقة حادة وحجم مثالي)
  /*
  static Future<Uint8List> _fastBackgroundCompress(Uint8List bytes) async {
    try {
      final double imageSizeInMB = bytes.length / (1024 * 1024);

      // إذا كانت الصورة صغيرة بالفعل (أقل من 400 كيلوبايت) لا داعي لتبديد الطاقة في ضغطها
      if (imageSizeInMB < 0.4) return bytes;

      // تنفيذ الضغط مع وضع حدود قصوى ذكية للأبعاد (Target) لمنع الأحجام الفلكية
      // الأبعاد 1200x1600 أو 1440x1920 ممتازة جداً وتكفي لعرض تفاصيل الألمنيوم والزجاج بدقة 2K حادة
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1200, // 🌟 السحر هنا: حد أقصى للعرض المتناسب
        minHeight: 1600, // 🌟 السحر هنا: حد أقصى للارتفاع المتناسب
        quality:
            70, // جودة 70 تمنح توازناً مذهلاً بين الحجم الخفيف والنقاء البصري
        format: CompressFormat.jpeg,
        autoCorrectionAngle:
            true, // يمنع تدوير الصور الملتقطة من الكاميرا بشكل خاطئ
        keepExif:
            false, // 🌟 حذف البيانات المخفية الثقيلة التي ترفع حجم الملف دون داعٍ
      );

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      if (kDebugMode) print("🎯 خطأ في الضغط السريع المطور: $e");
      return bytes; // حماية استقرار التطبيق برادع الاستثناءات
    }
  }
*/

  /// دالة الضغط السريع الخلفية المعزولة (Single-Pass Execution) - النسخة المصححة والمطورة
  /*
  static Future<Uint8List> _fastBackgroundCompress(Uint8List bytes) async {
    try {
      final double imageSizeInMB = bytes.length / (1024 * 1024);

      // إذا كانت الصورة صغيرة بالفعل (أقل من 300 كيلوبايت) لا داعي لتبديد طاقة المعالجة
      if (imageSizeInMB < 0.3) return bytes;

      if (kDebugMode) {
        print(
          "📸 [Isolate] الحجم الأصلي الممرر للضغط: ${imageSizeInMB.toStringAsFixed(2)} ميجابايت",
        );
      }

      // 1️⃣ خطوة فحص الأبعاد وحساب الأبعاد الجديدة (بدون الـ Encoding الثقيل)
      img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return bytes;

      // الأبعاد القياسية للتطبيقات العالمية (تحافظ على تفاصيل وتناسق قطاعات الألمنيوم والمنتجات)
      const int maxTargetWidth = 1024;
      const int maxTargetHeight = 1280;

      int targetWidth = decodedImage.width;
      int targetHeight = decodedImage.height;

      // حساب نسبة التناسب (Aspect Ratio) لتقليص الأبعاد دون تشويه الصورة
      if (decodedImage.width > maxTargetWidth ||
          decodedImage.height > maxTargetHeight) {
        double ratioX = maxTargetWidth / decodedImage.width;
        double ratioY = maxTargetHeight / decodedImage.height;
        double scaleRatio = min(ratioX, ratioY);

        targetWidth = (decodedImage.width * scaleRatio).toInt();
        targetHeight = (decodedImage.height * scaleRatio).toInt();
      }

      if (kDebugMode) {
        print(
          "📏 [Isolate] الأبعاد الأصلية: ${decodedImage.width}x${decodedImage.height} -> الأبعاد المستهدفة: ${targetWidth}x${targetHeight}",
        );
      }

      // 2️⃣ خطوة الضغط الرقمي الفعلي وحذف الـ Exif في تمريرة واحدة
      // نقوم بتمرير البايتات الأصلية الخام، والمكتبة ستتكفل بالتحجيم والضغط معاً
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: targetWidth, // الأبعاد الجديدة المصغرة بدقة
        minHeight: targetHeight, // الأبعاد الجديدة المصغرة بدقة
        quality: 70, // توازن مثالي بين الحجم الصغير والجودة البصرية الممتازة
        format: CompressFormat.jpeg,
        autoCorrectionAngle:
            true, // تعديل زاوية دوران الصورة تلقائياً بناءً على الهاتف
        keepExif:
            false, // حذف البيانات الوصفية الثقيلة التي تزيد الحجم بلا فائدة
      );

      final Uint8List resultBytes = Uint8List.fromList(compressedBytes);

      if (kDebugMode) {
        final double compressedSizeInMB = resultBytes.length / (1024 * 1024);
        print(
          "⚡ [Isolate] الحجم النهائي الفعلي بعد الضغط: ${compressedSizeInMB.toStringAsFixed(3)} ميجابايت (${(resultBytes.length / 1024).toStringAsFixed(1)} كيلوبايت)",
        );
      }

      return resultBytes;
    } catch (e) {
      if (kDebugMode)
        print("🎯 [Isolate] فشل الضغط صامتاً وتم إرجاع الأصل، السبب: $e");
      return bytes;
    }
  }*/

  static Future<Uint8List> _fastBackgroundCompress(Uint8List bytes) async {
    try {
      final double imageSizeInMB = bytes.length / (1024 * 1024);

      // إذا كانت الصورة صغيرة جداً، نرجعها كما هي
      if (imageSizeInMB < 0.3) return bytes;

      if (kDebugMode) {
        print(
          "📸 [Isolate] الحجم الأصلي: ${imageSizeInMB.toStringAsFixed(2)} ميجابايت",
        );
      }

      // خطوة الضغط والتحجيم الذكي بـ تمريرة واحدة (Single-Pass) وبدون decodeImage
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth:
            1024, // المكتبة ستجعل العرض الأقصى 1024 وتحسب الارتفاع متناسباً تلقائياً
        minHeight: 1280, // المكتبة ستضمن عدم تجاوز الارتفاع 1280
        quality: 75, // جودة ممتازة جداً لقطاعات الألمنيوم والمنتجات
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
        keepExif: false, // إزالة البيانات الوصفية لتوفير مساحة إضافية
      );

      final Uint8List resultBytes = Uint8List.fromList(compressedBytes);

      if (kDebugMode) {
        print(
          "⚡ [Isolate] الحجم النهائي: ${(resultBytes.length / 1024).toStringAsFixed(1)} كيلوبايت",
        );
      }

      return resultBytes;
    } catch (e) {
      if (kDebugMode) print("🎯 [Isolate] فشل الضغط، السبب: $e");
      return bytes;
    }
  }

  // الدالة العامة للاستدعاء (تظل كما هي ممتازة)
  static Future<Uint8List> compressImageDirectly(Uint8List bytes) async {
    return await compute(_fastBackgroundCompress, bytes);
  }

  /*
  /// دالة الضغط السريع الخلفية المعزولة (Single-Pass Execution)
  static Future<Uint8List> _fastBackgroundCompress(Uint8List bytes) async {
    try {
      final double imageSizeInMB = bytes.length / (1024 * 1024);

      // إذا كانت الصورة صغيرة بالفعل (أقل من 400 كيلوبايت) لا داعي لتبديد طاقة المعالجة
      if (imageSizeInMB < 0.4) return bytes;

      if (kDebugMode) {
        print(
          "📸 الحجم الأصلي قبل المعالجة: ${imageSizeInMB.toStringAsFixed(2)} ميجابايت",
        );
      }

      // 1️⃣ خطوة معالجة الأبعاد الذكية (Downscaling):
      // نقوم بفك تشفير الصورة برمجياً للتحكم في أبعادها القصوى بدقة
      img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return bytes;

      const int maxTargetWidth = 1200;
      const int maxTargetHeight = 1600;

      // حساب نسبة التناسب للمحافظة على أبعاد الألمنيوم والمنتجات دون تشويه (Aspect Ratio)
      if (decodedImage.width > maxTargetWidth ||
          decodedImage.height > maxTargetHeight) {
        double ratioX = maxTargetWidth / decodedImage.width;
        double ratioY = maxTargetHeight / decodedImage.height;
        double scaleRatio = min(ratioX, ratioY);

        int newWidth = (decodedImage.width * scaleRatio).toInt();
        int newHeight = (decodedImage.height * scaleRatio).toInt();

        // إعادة تحجيم الصورة بالأبعاد الجديدة الممتازة لشاشات الموبايل
        decodedImage = img.copyResize(
          decodedImage,
          width: newWidth,
          height: newHeight,
        );
        bytes = Uint8List.fromList(img.encodeJpg(decodedImage, quality: 90));
      }

      // 2️⃣ خطوة ضغط البايتات الرقمية وحذف الـ Exif
      // بما أننا قمنا بضبط الأبعاد بالأعلى، نمرر الأبعاد الحالية كحد أدنى للمكتبة لتعمل بأمان
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: decodedImage.width, // الأبعاد الجديدة بعد التحجيم
        minHeight: decodedImage.height, // الأبعاد الجديدة بعد التحجيم
        quality: 70, // الضغط الرقمي السحري
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true, // تعديل زاوية الصورة تلقائياً
        keepExif: false, // تصفية البيانات الوصفية المخفية والثقيلة
      );

      final Uint8List resultBytes = Uint8List.fromList(compressedBytes);

      if (kDebugMode) {
        final double compressedSizeInMB = resultBytes.length / (1024 * 1024);
        print(
          "⚡ الحجم النهائي بعد الضغط المطور: ${compressedSizeInMB.toStringAsFixed(2)} ميجابايت",
        );
      }

      return resultBytes;
    } catch (e) {
      if (kDebugMode) print("🎯 خطأ استثنائي في الضغط: $e");
      return bytes;
    }
  }

  // الدالة العامة الاستدعاء
  static Future<Uint8List> compressImageDirectly(Uint8List bytes) async {
    // نرسلها للـ Isolate لضمان عدم تأثر خيوط المعالجة الرئيسية (UI Thread) نهائياً
    return await compute(_fastBackgroundCompress, bytes);
  }
*/
  // الدالة الأساسية التي سيتم تشغيلها في الـ Isolate الخلفي
  /* static Future<Uint8List> _backgroundCompress(Uint8List bytes) async {
    try {
      final double imageSizeInKB = bytes.length / 1024;
      if (imageSizeInKB <= 600) return bytes;

      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1920,
        minHeight: 1080,
        quality: 88,
        format: CompressFormat.jpeg,
      );
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      return bytes;
    }
  }

  // الدالة العامة التي سنستدعيها (تقوم بالرفع للخلفية تلقائياً)
  static Future<Uint8List> compressImageDataInBackground(
    Uint8List bytes,
  ) async {
    // 🌟 السحر هنا: compute تنقل البيانات لـ Isolate منفصل تماماً لتجنب أي تعليق في الواجهة
    return await compute(_backgroundCompress, bytes);
  }*/

  /*static Future<Uint8List> compressImageData(Uint8List bytes) async {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // شرط ذكي: إذا كان عرض الصورة أصلاً أقل من 1024، لا تقم بتغيير الحجم
    img.Image processedImage = image;
    if (image.width > 1024) {
      processedImage = img.copyResize(image, width: 1024);
    }

    // الضغط النهائي
    return Uint8List.fromList(img.encodeJpg(processedImage, quality: 70));
  }*/
  static Future<Uint8List> compressImageData(Uint8List bytes) async {
    try {
      // 1. حساب حجم الصورة الحالية بالكيلوبايت
      final double imageSizeInKB = bytes.length / 1024;

      // 2. إذا كانت الصورة أصلاً صغيرة (أقل من 600 كيلوبايت) لا تلمسها نهائياً للحفاظ على جودتها الكاملة
      if (imageSizeInKB <= 600) {
        return bytes;
      }

      // 3. الضغط الذكي والمحافظ على الأبعاد التناسبية للمنتجات دون تشويه
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1920, // دقة Full HD تضمن ظهور تفاصيل المنتج بوضوح مبهر
        minHeight: 1080,
        quality:
            88, // 88% هي النسبة المثالية عالمياً للحفاظ على حدة الألوان والتفاصيل
        format: CompressFormat.jpeg,
      );

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      // في حال حدوث أي خطأ غير متوقع، أرجع البيانات الأصلية بأمان
      debugPrint("Compression Error: $e");
      return bytes;
    }
  }

  /*
  static Future<Uint8List> compressImageData(Uint8List bytes) async {
    try {
      // 1. حساب حجم الصورة الحالية بالكيلوبايت
      // الحجم بالكيلوبايت = عدد البايتات / 1024
      final double imageSizeInKB = bytes.length / 1024;

      // 2. شرط التحقق الذكي: إذا كانت الصورة أصلاً أصغر من 500 كيلوبايت، لا تضغطها ووفر المعالجة
      if (imageSizeInKB <= 500) {
        return bytes;
      }

      // 3. إذا كانت الصورة كبيرة (مثلاً تم التقاطها بكاميرا الهاتف مباشرة)، نقوم بضغطها
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1024,
        minHeight: 1024,
        quality: 80, // جودة 80-85 ممتازة جداً للصور الكبيرة
        format: CompressFormat.jpeg,
      );

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      // في حال حدوث أي خطأ غير متوقع، أرجع البيانات الأصلية بأمان
      return bytes;
    }
  }
*/
  /*static Future<Uint8List> compressImageData(Uint8List bytes) async {
    try {
      // الضغط باستخدام Native Code يوفر جودة أعلى بمرتين بنفس الحجم
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1024,
        minHeight: 1024,
        quality: 85, // جودة 85 مثالية جداً (توازن بين الحجم والوضوح)
        format: CompressFormat.jpeg,
      );

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      // في حال حدوث خطأ، أرجع البيانات الأصلية
      return bytes;
    }
  }*/

  /*
  static Future<Uint8List> compressImageData(Uint8List bytes) async {
    // استخدام compute لتشغيل العملية في Isolate منفصل
    return await compute(_syncCompressProcess, bytes);
  }
*/
  // هذه الدالة ستحتوي على المنطق الفعلي وتعمل في الخلفية تماماً
  static Uint8List _syncCompressProcess(Uint8List bytes) {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    img.Image processedImage = image;
    if (image.width > 1024) {
      processedImage = img.copyResize(image, width: 1024);
    }

    return Uint8List.fromList(img.encodeJpg(processedImage, quality: 70));
  }

  /*static Future<Uint8List> compressImageData(Uint8List bytes) async {
    // 1. فك تشفير الصورة من Bytes
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // 2. تصغير الأبعاد لتسريع الرفع (مثلاً عرض 1024 بكسل)
    img.Image resized = img.copyResize(image, width: 1024);

    // 3. تحويلها لـ JPG بضغط 70%
    // هذا السطر سيحول الـ 7 ميجا إلى حوالي 300-500 كيلوبايت
    return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
  }*/
}
