import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/features/personalizatuon/controllers/store_controller.dart';
import 'package:stors_admin_panel/features/personalizatuon/controllers/store_profile_controller.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';

// --- 2. ويدجيت المحتوى (تستخدم في التابلت والموبايل) ---
class StoreProfileContent extends StatelessWidget {
  const StoreProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoreController());
    final editController = Get.put(StoreProfileController());

    return Obx(() {
      if (controller.profileLoading.value) {
        return const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final store = controller.store.value;

      return Column(
        children: [
          // الهيدر
          _buildHeader(store, controller, editController),
          const SizedBox(height: 60),

          // الاسم والإيميل
          Column(
            children: [
              Text(
                "${store.firstName} ${store.lastName}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                store.email,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // بطاقة البيانات
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _buildProfileField(
                    label: "الاسم الأول",
                    controller: controller.firstName,
                    icon: Icons.person_outline,
                    isEdit: editController.isEditing.value,
                  ),
                  const Divider(height: 20),
                  _buildProfileField(
                    label: "اسم العائلة",
                    controller: controller.lastName,
                    icon: Icons.people_outline,
                    isEdit: editController.isEditing.value,
                  ),
                  const Divider(height: 20),
                  _buildProfileField(
                    label: "رقم الهاتف",
                    controller: controller.phone,
                    icon: Icons.phone_android_outlined,
                    isEdit: editController.isEditing.value,
                  ),
                  const Divider(height: 20),
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

          const SizedBox(height: 25),

          // زر التعديل
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (editController.isEditing.value) {
                    await controller.updateStoreInformation();
                    editController.isEditing.value = false;
                  } else {
                    editController.toggleEdit();
                  }
                },
                child: controller.updateLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        editController.isEditing.value
                            ? "حفظ البيانات"
                            : "تعديل البروفايل",
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }

  // --- التوابع المساعدة (Private Methods) ---

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEdit,
  }) {
    return Row(
      children: [
        Icon(icon, color: TColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              isEdit
                  ? TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : Text(
                      controller.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    StoreModel store,
    StoreController controller,
    StoreProfileController editController,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // الغلاف
        GestureDetector(
          onTap: editController.isEditing.value
              ? () => controller.updateStoreImage(false)
              : null,
          child: Container(
            height: 180, // قللنا الارتفاع قليلاً ليتناسب مع وضع التابلت العرضي
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(store.storeBanner),
                fit: BoxFit.cover,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
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
                      size: 30,
                    )
                  : null,
            ),
          ),
        ),

        // الصورة الدائرية
        Positioned(
          bottom: -45,
          child: GestureDetector(
            onTap: editController.isEditing.value
                ? () => controller.updateStoreImage(true)
                : null,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: NetworkImage(store.profilePicture),
                  ),
                  if (controller.imageLoading.value)
                    const CircularProgressIndicator(),
                  if (editController.isEditing.value &&
                      !controller.imageLoading.value)
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_a_photo, color: Colors.white),
                    ),
                ],
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
          color: Colors.black.withOpacity(0.03),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(color: Colors.grey.shade100),
    );
  }
}
