# دليل استخدام الخطوط في التطبيق

## الخطوط المتاحة

### 1. خط Tajawal (الخط الأساسي)
- **المصدر**: Google Fonts
- **الاستخدام**: الخط الافتراضي للتطبيق
- **اللغة**: عربي ممتاز
- **الأسلوب**: أنيق وواضح

### 2. خط Cairo (الخط المحلي)
- **المصدر**: ملفات محلية
- **المسار**: `assets/fonts/cairo/`
- **الأوزان**: من 200 إلى 900
- **الاستخدام**: كخط احتياطي أو للاستخدام المخصص

### 3. خط Urbanist (خط إنجليزي)
- **المصدر**: ملفات محلية
- **المسار**: `assets/fonts/urbanist/`
- **الأوزان**: من 100 إلى 900
- **الأساليب**: عادي ومائل
- **الاستخدام**: للنصوص الإنجليزية

### 4. خط Montserrat (خط إنجليزي)
- **المصدر**: ملفات محلية
- **المسار**: `assets/fonts/montaser/` (ملاحظة: الاسم في المجلد خاطئ، يجب أن يكون montserrat)
- **الأوزان**: من 100 إلى 900
- **الأساليب**: عادي ومائل

## كيفية الاستخدام

### استخدام الخط Tajawal (موصى به)

```dart
import 'package:google_fonts/google_fonts.dart';

// في الثيم
fontFamily: GoogleFonts.tajawal().fontFamily,

// في النصوص المباشرة
Text(
  'نص عربي',
  style: GoogleFonts.tajawal(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  ),
)
```

### استخدام الخطوط المحلية

```dart
// استخدام خط Cairo
Text(
  'نص عربي',
  style: TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w500,
  ),
)

// استخدام خط Urbanist
Text(
  'English Text',
  style: TextStyle(
    fontFamily: 'Urbanist',
    fontWeight: FontWeight.w400,
  ),
)
```

### استخدام فئة AppFonts

```dart
import 'package:stors_admin_panel/utils/fonts/app_fonts.dart';

// استخدام خط Tajawal
Text(
  'نص عربي',
  style: AppFonts.tajawal(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  ),
)

// استخدام خط Amiri
Text(
  'نص عربي كلاسيكي',
  style: AppFonts.amiri(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
)

// استخدام Extensions
Text(
  'نص عربي',
  style: Theme.of(context).bodyMedium!.tajawal,
)
```

## ملاحظات مهمة

1. **خط Tajawal** هو الخط الافتراضي للتطبيق ويُستخدم في جميع TextTheme
2. **خط Cairo** متاح كخط احتياطي محلي في حالة عدم تحميل Google Fonts
3. **الخطوط الإنجليزية** (Urbanist, Montserrat) مخصصة للنصوص الإنجليزية فقط
4. جميع الخطوط تدعم اللغة العربية باستثناء Montserrat (قد تكون محدودة)

## إضافة خطوط جديدة

لإضافة خط جديد:

1. أضف ملفات الخط في `assets/fonts/`
2. حدث `pubspec.yaml` في قسم fonts
3. أضف الخط في `AppFonts` class إذا كان من Google Fonts
4. حدث الثيم إذا لزم الأمر

## استكشاف الأخطاء

### خطأ "unable to locate asset entry"
- تأكد من صحة مسارات الملفات في `pubspec.yaml`
- تأكد من وجود الملفات في المجلد الصحيح

### خطأ "Font not found"
- تأكد من اسم الخط في `fontFamily`
- تأكد من وجود اتصال بالإنترنت لـ Google Fonts

### نص غير واضح
- جرب تغيير `fontWeight`
- تأكد من أن حجم الخط مناسب