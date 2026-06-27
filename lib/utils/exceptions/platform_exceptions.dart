/// كلاس مخصص للتعامل مع الأخطاء المتعلقة بالمنصة (Platform-related errors).
class TPlatformException implements Exception {
  final String code;

  TPlatformException(this.code);

  String get message {
    switch (code) {
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'بيانات تسجيل الدخول غير صالحة. يرجى التحقق من معلوماتك.';
      case 'too-many-requests':
        return 'طلبات كثيرة جداً. يرجى المحاولة مرة أخرى لاحقاً.';
      case 'invalid-argument':
        return 'تم تقديم وسيط غير صالح لطريقة المصادقة.';
      case 'invalid-password':
        return 'كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.';
      case 'invalid-phone-number':
        return 'رقم الهاتف المقدم غير صالح.';
      case 'operation-not-allowed':
        return 'مزود تسجيل الدخول هذا معطل لمشروع Firebase الخاص بك.';
      case 'session-cookie-expired':
        return 'انتهت صلاحية جلسة Firebase. يرجى تسجيل الدخول مرة أخرى.';
      case 'uid-already-exists':
        return 'معرف المستخدم المقدم مستخدم بالفعل من قبل مستخدم آخر.';
      case 'sign_in_failed':
        return 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.';
      case 'network-request-failed':
        return 'فشل طلب الشبكة. يرجى التحقق من اتصالك بالإنترنت.';
      case 'internal-error':
        return 'حدث خطأ داخلي. يرجى المحاولة مرة أخرى لاحقاً.';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صالح. يرجى إدخال رمز صحيح.';
      case 'invalid-verification-id':
        return 'معرف التحقق غير صالح. يرجى طلب رمز تحقق جديد.';
      case 'quota-exceeded':
        return 'تم تجاوز الحصة المسموح بها. يرجى المحاولة لاحقاً.';
      // يمكنك إضافة المزيد من الحالات حسب الحاجة...
      default:
        return 'حدث خطأ غير متوقع في نظام التشغيل. يرجى المحاولة مرة أخرى.';
    }
  }
}
