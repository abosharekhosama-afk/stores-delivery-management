/// كلاس مخصص للتعامل مع استثناءات Firebase Authentication المختلفة.
class TFirebaseAuthException implements Exception {
  /// رمز الخطأ المرتبط بالاستثناء.
  final String code;

  /// منشئ (Constructor) يأخذ رمز الخطأ.
  TFirebaseAuthException(this.code);

  /// الحصول على رسالة الخطأ المقابلة بناءً على رمز الخطأ.
  String get message {
    switch (code) {
      case 'email-already-in-use':
        return 'عنوان البريد الإلكتروني مسجل بالفعل. يرجى استخدام بريد إلكتروني آخر.';
      case 'invalid-email':
        return 'عنوان البريد الإلكتروني المقدم غير صالح. يرجى إدخال بريد صحيح.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً. يرجى اختيار كلمة مرور أقوى.';
      case 'user-disabled':
        return 'تم تعطيل حساب المستخدم هذا. يرجى التواصل مع الدعم للمساعدة.';
      case 'user-not-found':
        return 'بيانات تسجيل الدخول غير صحيحة. المستخدم غير موجود.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة. يرجى التحقق والمحاولة مرة أخرى.';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صالح. يرجى إدخال رمز صحيح.';
      case 'invalid-verification-id':
        return 'معرف التحقق غير صالح. يرجى طلب رمز تحقق جديد.';
      case 'quota-exceeded':
        return 'تم تجاوز الحصة المسموح بها. يرجى المحاولة مرة أخرى لاحقاً.';
      case 'email-already-exists':
        return 'عنوان البريد الإلكتروني موجود بالفعل. يرجى استخدام بريد آخر.';
      case 'provider-already-linked':
        return 'الحساب مرتبط بالفعل بمزود خدمة آخر.';
      case 'requires-recent-login':
        return 'هذه العملية حساسة وتتطلب إعادة تسجيل الدخول حديثاً.';
      case 'credential-already-in-use':
        return 'بيانات الاعتماد هذه مرتبطة بالفعل بحساب مستخدم آخر.';
      case 'user-mismatch':
        return 'بيانات الاعتماد المقدمة لا تتطابق مع المستخدم المسجل دخوله مسبقاً.';
      case 'account-exists-with-different-credential':
        return 'يوجد حساب مسجل بنفس البريد ولكن ببيانات دخول مختلفة.';
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموح بها. يرجى التواصل مع الدعم.';
      case 'expired-action-code':
        return 'انتهت صلاحية رمز الإجراء. يرجى طلب رمز جديد.';
      case 'invalid-action-code':
        return 'رمز الإجراء غير صالح. يرجى التحقق والمحاولة مرة أخرى.';
      case 'missing-action-code':
        return 'رمز الإجراء مفقود. يرجى تقديم رمز صحيح.';
      case 'user-token-expired':
        return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.';
      case 'invalid-credential':
        return 'بيانات الاعتماد المقدمة غير صالحة أو منتهية الصلاحية.';
      case 'user-token-revoked':
        return 'تم إلغاء جلسة المستخدم. يرجى تسجيل الدخول مرة أخرى.';
      case 'invalid-message-payload':
        return 'محتوى رسالة التحقق غير صالح.';
      case 'invalid-sender':
        return 'مرسل قالب البريد الإلكتروني غير صالح. يرجى التحقق من البريد المرسل.';
      case 'invalid-recipient-email':
        return 'عنوان بريد المستلم غير صالح. يرجى تقديم بريد صحيح.';
      case 'missing-iframe-start':
        return 'قالب البريد الإلكتروني يفتقد لعلامة بداية iframe.';
      case 'missing-iframe-end':
        return 'قالب البريد الإلكتروني يفتقد لعلامة نهاية iframe.';
      case 'missing-iframe-src':
        return 'قالب البريد الإلكتروني يفتقد لسمة المصدر (src) لـ iframe.';
      case 'auth-domain-config-required':
        return 'إعدادات authDomain مطلوبة لرابط التحقق من رمز الإجراء.';
      case 'missing-app-credential':
        return 'بيانات اعتماد التطبيق مفقودة. يرجى تقديم بيانات صحيحة.';
      case 'invalid-app-credential':
        return 'بيانات اعتماد التطبيق غير صالحة.';
      case 'session-cookie-expired':
        return 'انتهت صلاحية ملف تعريف الارتباط للجلسة. يرجى تسجيل الدخول مجدداً.';
      case 'uid-already-exists':
        return 'معرف المستخدم المقدم مستخدم بالفعل من قبل مستخدم آخر.';
      case 'invalid-cordova-configuration':
        return 'إعدادات Cordova المقدمة غير صالحة.';
      case 'app-deleted':
        return 'تم حذف هذه النسخة من FirebaseApp.';
      case 'user-token-mismatch':
        return 'هناك عدم تطابق في معرف المستخدم الخاص بالجلسة.';
      case 'web-storage-unsupported':
        return 'تخزين الويب غير مدعوم أو تم تعطيله.';
      case 'app-not-authorized':
        return 'التطبيق غير مصرح له باستخدام Firebase Authentication بمفتاح API هذا.';
      case 'keychain-error':
        return 'حدث خطأ في سلسلة المفاتيح (Keychain). يرجى التحقق والمحاولة ثانية.';
      case 'internal-error':
        return 'حدث خطأ داخلي في عملية المصادقة. يرجى المحاولة لاحقاً.';
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'بيانات تسجيل الدخول غير صالحة.';
      default:
        return 'حدث خطأ غير متوقع في المصادقة. يرجى المحاولة مرة أخرى.';
    }
  }
}
