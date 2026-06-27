import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/features/personalizatuon/controllers/store_controller.dart';
import 'package:stors_admin_panel/features/personalizatuon/controllers/store_profile_controller.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';

class StoreProfileScreen extends StatelessWidget {
  const StoreProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoreController());
    final editController = Get.put(StoreProfileController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // خلفية الشاشة هادئة ومريحة للعين
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Obx(() {
          if (controller.profileLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final store = controller.store.value;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // الهيدر (الغلاف + الصورة الشخصية)
                _buildHeader(store),
                const SizedBox(height: 60),

                // اسم المتجر والبريد الإلكتروني
                Column(
                  children: [
                    Text(
                      "${store.firstName} ${store.lastName}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // بطاقة البيانات الأساسية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        _buildProfileField(
                          label: "الاسم الأول",
                          controller: controller.firstName,
                          icon: Icons.person_outline,
                          isEdit: editController.isEditing.value,
                        ),
                        _buildDivider(editController.isEditing.value),
                        _buildProfileField(
                          label: "اسم العائلة",
                          controller: controller.lastName,
                          icon: Icons.people_outline,
                          isEdit: editController.isEditing.value,
                        ),
                        _buildDivider(editController.isEditing.value),
                        _buildProfileField(
                          label: "رقم الهاتف",
                          controller: controller.phone,
                          icon: Icons.phone_android_outlined,
                          isEdit: editController.isEditing.value,
                          keyboardType: TextInputType.phone,
                        ),
                        _buildDivider(editController.isEditing.value),
                        _buildProfileField(
                          label: "رقم الحساب البنكي",
                          controller: controller.bankAccount,
                          icon: Icons.account_balance_outlined,
                          isEdit: editController.isEditing.value,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // زر التعديل / الحفظ مع مسافة أمان ممتازة بالأسفل
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 40,
                  ), // 🌟 هنا حل مشكلة الالتصاق بالأسفل
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // زوايا متناسقة مع البطاقات
                        ),
                        elevation: editController.isEditing.value ? 4 : 1,
                      ),
                      onPressed: () async {
                        if (editController.isEditing.value) {
                          await controller.updateStoreInformation();
                          editController.isEditing.value = false;
                        } else {
                          editController.toggleEdit();
                        }
                      },
                      child: controller.updateLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              editController.isEditing.value
                                  ? "حفظ التغييرات"
                                  : "تعديل الملف الشخصي",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ويدجيت ذكي لبناء الحقل (يتغير شكله بالكامل وبسلاسة عند التعديل)
  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEdit,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isEdit ? 6 : 10,
      ), // تقليل الحشو الداخلي في وضع التعديل لمنع الضخامة
      child: Row(
        crossAxisAlignment: isEdit
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          // الأيقونة الجانبية
          Padding(
            padding: EdgeInsets.only(top: isEdit ? 0 : 4),
            child: Icon(icon, color: TColors.primary, size: 22),
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان الصغير للحقل
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                // التبديل الذكي بين النص العادي وحقل الإدخال الأنيق
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isEdit
                      ? TextField(
                          key: ValueKey("edit_$label"),
                          controller: controller,
                          keyboardType: keyboardType,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors
                                .grey
                                .shade50, // خلفية رمادية فاتحة جداً للحقل المفتوح
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: TColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          key: ValueKey("view_$label"),
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          child: Text(
                            controller.text.isEmpty
                                ? "غير محدد"
                                : controller.text,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: controller.text.isEmpty
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ويدجيت لفصل العناصر (يختفي في وضع التعديل ليترك مساحة مريحة للحقول)
  Widget _buildDivider(bool isEditing) {
    if (isEditing)
      return const SizedBox(height: 10); // مسافة بديلة عن الخط في وضع التعديل
    return Divider(color: Colors.grey.shade100, height: 20);
  }

  Widget _buildHeader(StoreModel store) {
    final controller = StoreController.instance;
    final editController = Get.find<StoreProfileController>();

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // الغلاف (Store Banner)
        Obx(
          () => GestureDetector(
            onTap: editController.isEditing.value
                ? () => controller.updateStoreImage(false)
                : null,
            child: Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(store.storeBanner),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha((0.6 * 255).round()),
                      Colors.transparent,
                      Colors.black.withAlpha((0.6 * 255).round()),
                    ],
                  ),
                ),
                child: controller.bannerLoading.value
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : editController.isEditing.value
                    ? Container(
                        color: Colors.black26,
                        child: const Icon(
                          Icons.camera_enhance_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),

        // صورة البروفايل الدائرية
        Positioned(
          bottom: -50,
          child: Obx(
            () => GestureDetector(
              onTap: editController.isEditing.value
                  ? () => controller.updateStoreImage(true)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(store.profilePicture),
                    ),
                    if (controller.imageLoading.value)
                      const CircularProgressIndicator(),
                    if (editController.isEditing.value &&
                        !controller.imageLoading.value)
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((0.03 * 255).round()),
          blurRadius: 15,
          spreadRadius: 1,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(color: Colors.grey.shade100, width: 1),
    );
  }
}




/*
class StoreProfileScreen extends StatelessWidget {
  const StoreProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoreController());
    final editController = Get.put(
      StoreProfileController(),
    ); // المتحكم بالتبديل بين العرض والتعديل
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // جعل الخلفية شفافة
        statusBarIconBrightness: Brightness.dark, // للأندرويد: أيقونات سوداء
        statusBarBrightness: Brightness.light, // للـ iOS: أيقونات سوداء
      ),
    );
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // جعل شريط الحالة شفافاً تماماً
          statusBarIconBrightness: Brightness
              .light, // أيقونات بيضاء لتظهر بوضوح فوق الغلاف الأسود/الملون
          statusBarBrightness: Brightness.dark, // للـ iOS
        ),
        child: Obx(() {
          // حالة التحميل الأولي
          if (controller.profileLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final store = controller.store.value;

          return SingleChildScrollView(
            // 🌟 لمنع حدوث مشاكل في الأبعاد عند فتح لوحة المفاتيح أثناء التعديل
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // الهيدر (Banner + Profile Pic) كما في الكود السابق
                _buildHeader(store),
                const SizedBox(height: 60),

                // الاسم والإيميل
                Column(
                  children: [
                    Text(
                      "${store.firstName} ${store.lastName}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      store.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // بطاقة البيانات الأساسية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        _buildProfileField(
                          label: "الاسم الأول",
                          controller: controller.firstName,
                          icon: Icons.person_outline,
                          isEdit: editController.isEditing.value,
                        ),
                        const Divider(),
                        _buildProfileField(
                          label: "اسم العائلة",
                          controller: controller.lastName,
                          icon: Icons.people_outline,
                          isEdit: editController.isEditing.value,
                        ),
                        const Divider(),
                        _buildProfileField(
                          label: "رقم الهاتف",
                          controller: controller.phone,
                          icon: Icons.phone_android_outlined,
                          isEdit: editController.isEditing.value,
                        ),
                        const Divider(),
                        _buildProfileField(
                          label: "رقم الحساب البنكي",
                          controller: controller.bankAccount,
                          icon: Icons.account_balance_outlined,
                          isEdit: editController.isEditing.value,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // زر التعديل / الحفظ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (editController.isEditing.value) {
                          // تنفيذ عملية التحديث الفعلية
                          await controller.updateStoreInformation();
                          editController.isEditing.value = false;
                        } else {
                          editController.toggleEdit();
                        }
                      },
                      child: controller.updateLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              editController.isEditing.value
                                  ? "حفظ البيانات"
                                  : "تعديل البروفايل",
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ويدجيت لبناء حقل البيانات (عرض أو تعديل)
  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: TColors.primary, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                isEdit
                    ? TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : Text(
                        controller.text,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(StoreModel store) {
    final controller = StoreController.instance;
    final editController = Get.find<StoreProfileController>();

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // الغلاف (Store Banner)
        Obx(
          () => GestureDetector(
            onTap: editController.isEditing.value
                ? () => controller.updateStoreImage(false)
                : null,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(store.storeBanner),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha((0.4 * 255).round()),
                      Colors.transparent,
                      Colors.black.withAlpha((0.6 * 255).round()),
                    ],
                  ),
                ),
                child: controller.bannerLoading.value
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : editController.isEditing.value
                    ? const Icon(
                        Icons.camera_enhance,
                        color: Colors.white70,
                        size: 40,
                      )
                    : null,
              ),
            ),
          ),
        ),

        // صورة البروفايل الدائرية
        Positioned(
          bottom: -50,
          child: Obx(
            () => GestureDetector(
              onTap: editController.isEditing.value
                  ? () => controller.updateStoreImage(true)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(store.profilePicture),
                    ),
                    if (controller.imageLoading.value)
                      const CircularProgressIndicator(),
                    if (editController.isEditing.value &&
                        !controller.imageLoading.value)
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha((0.3 * 255).round()),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25), // زوايا دائرية كبيرة لروح عصرية
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((0.04 * 255).round()), // ظل خفيف جداً
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 10), // الظل للأسفل فقط
        ),
      ],
      border: Border.all(
        color: Colors.grey.shade100,
        width: 1,
      ), // إطار خفيف جداً للتحديد
    );
  }
}
*/