/// كلاس التحقق من صحة المدخلات
class TValidator {
  /// التحقق من النصوص الفارغة
  static String? validateEmptyText(String? fieldName, String? value) {
    if (value == null || value.isEmpty) {
      return 'حقل $fieldName مطلوب.';
    }

    return null;
  }

  /// التحقق من اسم المستخدم
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'اسم المستخدم مطلوب.';
    }

    // تعبير نمطي (Regular Expression) لاسم المستخدم: طول بين 3-20 حرفاً، أرقام، وحروف، وشرطات.
    const pattern = r"^[a-zA-Z0-9_-]{3,20}$";
    final regex = RegExp(pattern);

    bool isValid = regex.hasMatch(username);

    // التحقق من أن اسم المستخدم لا يبدأ ولا ينتهي بشرطة أو شرطة سفلية.
    if (isValid) {
      isValid =
          !username.startsWith('_') &&
          !username.startsWith('-') &&
          !username.endsWith('_') &&
          !username.endsWith('-');
    }

    if (!isValid) {
      return 'اسم المستخدم غير صالح.';
    }

    return null;
  }

  /// التحقق من البريد الإلكتروني
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب.';
    }

    // التعبير النمطي للتحقق من تنسيق البريد الإلكتروني
    final emailRegExp = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(value)) {
      return 'عنوان بريد إلكتروني غير صالح.';
    }

    return null;
  }

  /// التحقق من كلمة المرور
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة.';
    }

    // التحقق من الحد الأدنى لطول كلمة المرور
    if (value.length < 6) {
      return 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.';
    }

    // التحقق من وجود حروف كبيرة
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل.';
    }

    // التحقق من وجود أرقام
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل.';
    }

    // التحقق من وجود رموز خاصة
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'يجب أن تحتوي كلمة المرور على رمز خاص واحد على الأقل.';
    }

    return null;
  }

  /// التحقق من رقم الهاتف
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم الهاتف مطلوب.';
    }

    // التعبير النمطي للتحقق من رقم الهاتف (يتوقع 12 رقماً بناءً على الكود الخاص بك)
    final phoneRegExp = RegExp(r'^\d{10}$');

    if (!phoneRegExp.hasMatch(value)) {
      return 'تنسيق رقم الهاتف غير صالح (يجب إدخال 12 رقماً).';
    }

    return null;
  }
}
