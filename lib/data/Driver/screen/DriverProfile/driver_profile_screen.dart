import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/Driver/controller/driver_profile_controller.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب الكونترولر (تأكد من عمل put له في مكان ما قبل استدعاء الشاشة)
    final controller = Get.find<DriverProfileController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "الملف الشخصي",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        // تأكد من أن البيانات ليست null
        if (controller.driver.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final driverData = controller.driver.value!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // --- جزء الصورة الشخصية (التعديل الوحيد المسموح) ---
              Center(
                child: Stack(
                  children: [
                    // عرض الصورة من الشبكة
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.blue.withAlpha(
                        (0.1 * 255).round(),
                      ),
                      backgroundImage: NetworkImage(driverData.profilePicture),
                    ),

                    // أيقونة الكاميرا للتعديل
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: controller.isLoading.value
                            ? null // تعطيل النقر أثناء التحميل
                            : () => controller.uploadProfilePicture(),
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 20,
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // تنبيه بسيط للمندوب
              if (controller.isLoading.value)
                const Text(
                  "جاري رفع الصورة، يرجى الانتظار...",
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              const SizedBox(height: 30),

              // --- بيانات العرض فقط (لا يمكن النقر عليها أو تعديلها) ---
              _buildDataTile(
                "الاسم الكامل",
                driverData.name,
                Icons.person_outline,
              ),
              _buildDataTile(
                "البريد الإلكتروني",
                driverData.email,
                Icons.email_outlined,
              ),
              _buildDataTile(
                "رقم الهاتف",
                driverData.phoneNumber.isEmpty
                    ? "غير محدد"
                    : driverData.phoneNumber,
                Icons.phone_android_outlined,
              ),
              _buildDataTile(
                "حالة الحساب",
                driverData.isActive == true
                    ? "نشط ومفعل"
                    : "غير نشط / قيد المراجعة",
                Icons.verified_user_outlined,
              ),
            ],
          ),
        );
      }),
    );
  }

  // أداة لبناء ويدجت العرض
  Widget _buildDataTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50], // لون خلفية هادئ للبيانات غير القابلة للتعديل
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[400]), // لون أيكون أكثر هدوءاً
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis, // للتعامل مع النصوص الطويلة
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
