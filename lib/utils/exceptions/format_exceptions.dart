/// كلاس مخصص للتعامل مع الأخطاء المتعلقة بتنسيق البيانات (Format).
class TFormatException implements Exception {
  /// رسالة الخطأ المرتبطة.
  final String message;

  /// منشئ افتراضي مع رسالة خطأ عامة.
  const TFormatException([
    this.message =
        'حدث خطأ غير متوقع في تنسيق البيانات. يرجى التحقق من المدخلات.',
  ]);

  /// إنشاء استثناء تنسيق بناءً على رسالة خطأ محددة.
  factory TFormatException.fromMessage(String message) {
    return TFormatException(message);
  }

  /// الحصول على رسالة الخطأ المنسقة.
  String get formattedMessage => message;

  /// إنشاء استثناء تنسيق بناءً على رمز خطأ (code) محدد.
  factory TFormatException.fromCode(String code) {
    switch (code) {
      case 'invalid-email-format':
        return const TFormatException(
          'تنسيق البريد الإلكتروني غير صحيح. يرجى إدخال بريد صالح.',
        );
      case 'invalid-phone-number-format':
        return const TFormatException(
          'تنسيق رقم الهاتف المقدم غير صحيح. يرجى إدخال رقم صالح.',
        );
      case 'invalid-date-format':
        return const TFormatException(
          'تنسيق التاريخ غير صحيح. يرجى إدخال تاريخ صالح.',
        );
      case 'invalid-url-format':
        return const TFormatException(
          'تنسيق رابط الـ URL غير صحيح. يرجى إدخال رابط صالح.',
        );
      case 'invalid-credit-card-format':
        return const TFormatException(
          'تنسيق بطاقة الائتمان غير صحيح. يرجى إدخال رقم بطاقة صالح.',
        );
      case 'invalid-numeric-format':
        return const TFormatException('يجب أن تكون المدخلات بتنسيق رقمي صحيح.');
      // يمكنك إضافة المزيد من الحالات هنا حسب الحاجة...
      default:
        return const TFormatException();
    }
  }
}
