import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class StoreProfileController extends GetxController {
  // هل الواجهة في وضع التعديل؟
  RxBool isEditing = false.obs;

  // الحقول القابلة للتعديل
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;
  late TextEditingController bankController;

  @override
  void onInit() {
    super.onInit();
    // افتراضياً نملأ البيانات من الموديل (سيتم تمريره للكنترولر لاحقاً)
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    phoneController = TextEditingController();
    bankController = TextEditingController();
  }

  void toggleEdit() => isEditing.value = !isEditing.value;

  void saveProfile() {
    // هنا تضع منطق التحديث في Firebase
    isEditing.value = false;
    TLoaders.successSnackBar(
      title: "نجاح",
      message: "تم تحديث بيانات البروفايل بنجاح",
    );
  }
}
