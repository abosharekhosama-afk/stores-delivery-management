/// Exception class for handling various errors.
/// كلاس الاستثناءات للتعامل مع الأخطاء المتنوعة.
class TExceptions implements Exception {
  /// رسالة الخطأ المرتبطة.
  final String message;

  /// منشئ افتراضي مع رسالة خطأ عامة.
  const TExceptions([
    this.message = 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
  ]);

  /// إنشاء استثناء مصادقة بناءً على رمز (code) استثناء Firebase.
  factory TExceptions.fromCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return const TExceptions(
          'عنوان البريد الإلكتروني مسجل بالفعل. يرجى استخدام بريد إلكتروني آخر.',
        );
      case 'invalid-email':
        return const TExceptions(
          'عنوان البريد الإلكتروني المقدم غير صالح. يرجى إدخال بريد صحيح.',
        );
      case 'weak-password':
        return const TExceptions(
          'كلمة المرور ضعيفة جداً. يرجى اختيار كلمة مرور أقوى.',
        );
      case 'user-disabled':
        return const TExceptions(
          'تم تعطيل حساب المستخدم هذا. يرجى الاتصال بالدعم للحصول على المساعدة.',
        );
      case 'user-not-found':
        return const TExceptions(
          'بيانات تسجيل الدخول غير صالحة. المستخدم غير موجود.',
        );
      case 'wrong-password':
        return const TExceptions(
          'كلمة المرور غير صحيحة. يرجى التحقق منها والمحاولة مرة أخرى.',
        );
      case 'INVALID_LOGIN_CREDENTIALS':
        return const TExceptions(
          'بيانات الاعتماد غير صالحة. يرجى التأكد من صحة معلوماتك.',
        );
      case 'too-many-requests':
        return const TExceptions(
          'طلبات كثيرة جداً. يرجى المحاولة مرة أخرى لاحقاً.',
        );
      case 'invalid-argument':
        return const TExceptions('تم تقديم وسيط غير صالح لطريقة المصادقة.');
      case 'invalid-password':
        return const TExceptions(
          'كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.',
        );
      case 'invalid-phone-number':
        return const TExceptions('رقم الهاتف المقدم غير صالح.');
      case 'operation-not-allowed':
        return const TExceptions(
          'مزود تسجيل الدخول هذا معطل لمشروع Firebase الخاص بك.',
        );
      case 'session-cookie-expired':
        return const TExceptions(
          'انتهت صلاحية جلسة تسجيل الدخول. يرجى تسجيل الدخول مرة أخرى.',
        );
      case 'uid-already-exists':
        return const TExceptions(
          'معرف المستخدم المقدم مستخدم بالفعل من قبل مستخدم آخر.',
        );
      case 'sign_in_failed':
        return const TExceptions('فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.');
      case 'network-request-failed':
        return const TExceptions(
          'فشل طلب الشبكة. يرجى التحقق من اتصالك بالإنترنت.',
        );
      case 'internal-error':
        return const TExceptions('خطأ داخلي. يرجى المحاولة مرة أخرى لاحقاً.');
      case 'invalid-verification-code':
        return const TExceptions('رمز التحقق غير صالح. يرجى إدخال رمز صحيح.');
      case 'invalid-verification-id':
        return const TExceptions(
          'معرف التحقق غير صالح. يرجى طلب رمز تحقق جديد.',
        );
      case 'quota-exceeded':
        return const TExceptions(
          'تم تجاوز الحصة المسموح بها (Quota). يرجى المحاولة لاحقاً.',
        );
      default:
        return const TExceptions();
    }
  }
}
