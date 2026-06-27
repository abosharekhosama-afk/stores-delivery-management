import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/ChooseUser/controller/choose_user_type_controller.dart';
import 'package:stors_admin_panel/data/reposity/driver/driver_authentication_repository.dart';

class ChooseUserTypeScreen extends StatelessWidget {
  const ChooseUserTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // حقن الكنترولر
    final controller = Get.put(ChooseUserTypeController());
    Get.put(DriverAuthenticationRepository());

    return Scaffold(
      body: Stack(
        children: [
          // خلفية بتدرج لوني خفيف (Gradient Background) لإضافة لمسة حداثة
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0F7FA), // لون فاتح جداً (Cyan light)
                  Colors.white,
                  Color(0xFFE3F2FD), // لون فاتح جداً (Blue light)
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // نص ترحيبي كبير وجذاب
                  Text(
                    "مرحباً بك في ستورز",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // نص فرعي توضيحي
                  Text(
                    "اختر نوع حسابك للبدء في استخدام التطبيق",
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 80),

                  // كروت الاختيار (User Type Cards)
                  _buildUserTypeCard(
                    context,
                    title: "أنا تاجر",
                    description: "لإدارة متجري وطلباتي ومنتجاتي",
                    icon: Icons.store_mall_directory_outlined,
                    color: Colors.blueAccent,
                    onTap: controller.navigateToMerchantLogin,
                  ),

                  const SizedBox(height: 30), // مسافة بين الكروت

                  _buildUserTypeCard(
                    context,
                    title: "أنا مندوب",
                    description: "لاستلام وتوصيل الطلبات للزبائن",
                    icon: Icons.delivery_dining_outlined,
                    color: Colors.amber[700]!, // لون دافئ للمندوب
                    onTap: controller.navigateToDriverLogin,
                  ),

                  const Spacer(),
                  // نص حقوق النشر في الأسفل
                  Text(
                    "© 2024 Stors Admin Panel. جميع الحقوق محفوظة",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget مساعد لبناء كرت اختيار نوع المستخدم بشكل احترافي
  Widget _buildUserTypeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            25,
          ), // زوايا مستديرة كبيرة لعصرنة التصميم
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.15 * 255).round()),
              spreadRadius: 3,
              blurRadius: 15,
              offset: const Offset(0, 8), // تأثير ظل خفيف للأسفل
            ),
          ],
          border: Border.all(color: Colors.grey.withAlpha((0.1 * 255).round()), width: 1),
        ),
        child: Row(
          children: [
            // أيقونة خلفيتها دائرية بنفس لون الاختيار
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(width: 20),
            // نصوص الكرت
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // أيقونة سهم صغيرة تشير لقابلية النقر
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[400],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}


