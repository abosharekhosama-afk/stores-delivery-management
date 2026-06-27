/// كلاس مخصص للتعامل مع استثناءات Firebase العامة.
class TFirebaseException implements Exception {
  /// رمز الخطأ المرتبط بالاستثناء.
  final String code;

  /// منشئ (Constructor) يأخذ رمز الخطأ.
  TFirebaseException(this.code);

  /// الحصول على رسالة الخطأ المقابلة بناءً على رمز الخطأ.
  String get message {
    switch (code) {
      case 'unknown':
        return 'حدث خطأ غير معروف في Firebase. يرجى المحاولة مرة أخرى.';
      case 'invalid-custom-token':
        return 'تنسيق الرمز المخصص (Custom Token) غير صحيح. يرجى التحقق منه.';
      case 'custom-token-mismatch':
        return 'الرمز المخصص لا يتطابق مع الجمهور المستهدف.';
      case 'user-disabled':
        return 'تم تعطيل حساب المستخدم هذا.';
      case 'user-not-found':
        return 'لم يتم العثور على مستخدم بهذا البريد أو المعرف.';
      case 'invalid-email':
        return 'عنوان البريد الإلكتروني المقدم غير صالح. يرجى إدخال بريد صحيح.';
      case 'email-already-in-use':
        return 'عنوان البريد الإلكتروني مسجل بالفعل. يرجى استخدام بريد آخر.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة. يرجى التحقق والمحاولة ثانية.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً. يرجى اختيار كلمة مرور أقوى.';
      case 'provider-already-linked':
        return 'الحساب مرتبط بالفعل بمزود خدمة آخر.';
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموح بها. يرجى التواصل مع الدعم.';
      case 'invalid-credential':
        return 'بيانات الاعتماد المقدمة غير صالحة أو منتهية الصلاحية.';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صالح. يرجى إدخال رمز صحيح.';
      case 'invalid-verification-id':
        return 'معرف التحقق غير صالح. يرجى طلب رمز جديد.';
      case 'captcha-check-failed':
        return 'استجابة reCAPTCHA غير صالحة. يرجى المحاولة مرة أخرى.';
      case 'app-not-authorized':
        return 'التطبيق غير مصرح له باستخدام المصادقة بمفتاح API المقدم.';
      case 'keychain-error':
        return 'حدث خطأ في سلسلة المفاتيح (Keychain). يرجى التحقق والمحاولة ثانية.';
      case 'internal-error':
        return 'حدث خطأ داخلي. يرجى المحاولة مرة أخرى لاحقاً.';
      case 'invalid-app-credential':
        return 'بيانات اعتماد التطبيق غير صالحة.';
      case 'user-mismatch':
        return 'بيانات الاعتماد المقدمة لا تتطابق مع المستخدم السابق.';
      case 'requires-recent-login':
        return 'هذه العملية حساسة وتتطلب إعادة تسجيل دخول حديثة.';
      case 'quota-exceeded':
        return 'تم تجاوز الحصة المسموح بها. يرجى المحاولة لاحقاً.';
      case 'account-exists-with-different-credential':
        return 'يوجد حساب مسجل بنفس البريد ولكن ببيانات دخول مختلفة.';
      case 'missing-iframe-start':
        return 'قالب البريد الإلكتروني يفتقد لعلامة بداية iframe.';
      case 'missing-iframe-end':
        return 'قالب البريد الإلكتروني يفتقد لعلامة نهاية iframe.';
      case 'missing-iframe-src':
        return 'قالب البريد الإلكتروني يفتقد لسمة المصدر (src) لـ iframe.';
      case 'auth-domain-config-required':
        return 'إعدادات authDomain مطلوبة لرابط التحقق.';
      case 'missing-app-credential':
        return 'بيانات اعتماد التطبيق مفقودة.';
      case 'session-cookie-expired':
        return 'انتهت صلاحية جلسة Firebase. يرجى تسجيل الدخول مجدداً.';
      case 'uid-already-exists':
        return 'معرف المستخدم (UID) مستخدم بالفعل من قبل مستخدم آخر.';
      case 'web-storage-unsupported':
        return 'تخزين الويب غير مدعوم أو تم تعطيله.';
      case 'app-deleted':
        return 'تم حذف هذه النسخة من FirebaseApp.';
      case 'user-token-mismatch':
        return 'هناك عدم تطابق في معرف جلسة المستخدم.';
      case 'invalid-message-payload':
        return 'محتوى رسالة قالب التحقق غير صالح.';
      case 'invalid-sender':
        return 'مرسل قالب البريد غير صالح.';
      case 'invalid-recipient-email':
        return 'عنوان بريد المستلم غير صالح.';
      case 'missing-action-code':
        return 'رمز الإجراء مفقود.';
      case 'user-token-expired':
        return 'انتهت صلاحية الجلسة، يجب تسجيل الدخول مرة أخرى.';
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'بيانات تسجيل الدخول غير صالحة.';
      case 'expired-action-code':
        return 'انتهت صلاحية رمز الإجراء.';
      case 'invalid-action-code':
        return 'رمز الإجراء غير صالح.';
      case 'credential-already-in-use':
        return 'بيانات الاعتماد هذه مرتبطة بالفعل بحساب آخر.';
      default:
        return 'حدث خطأ غير متوقع في Firebase. يرجى المحاولة مرة أخرى.';
    }
  }
}
