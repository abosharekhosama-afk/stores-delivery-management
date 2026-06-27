import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/features/personalizatuon/controllers/profile_controller_new.dart';
import 'package:stors_admin_panel/features/personalizatuon/screens/profile/widgets/address_settings_screen.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class FormProfileScrren extends StatelessWidget {
  const FormProfileScrren({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileControllerNew());

    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        // 🌟 تم التأكيد على وجود التمرير لمنع الـ Overflow
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // --- 1️⃣ قسم رفع وعرض شعار المتجر (Logo) ---
            // --- 1️⃣ قسم رفع وعرض شعار المتجر (Logo) المطور ---
            Obx(() {
              final isUploading = controller.isLogoLoading.value;
              final logoUrl = controller.storeM.value.storeLogo;
              final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

              return Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        // 🌟 تحسين: إذا كان جاري الرفع، لا تعرض الصورة القديمة بالخلفية لمنع التداخل
                        image: hasLogo && !isUploading
                            ? DecorationImage(
                                image: NetworkImage(logoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      // 🌟 تحسين: ترتيب الشروط لعرض مؤشر التحميل بأولوية قصوى
                      child: isUploading
                          ? const Padding(
                              padding: EdgeInsets.all(35.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  TColors.primary,
                                ),
                              ),
                            )
                          : !hasLogo
                          ? Icon(
                              Iconsax.shop,
                              size: 40,
                              color: Colors.grey.shade400,
                            )
                          : null, // إذا كانت الصورة موجودة وليس هناك تحميل، يظهر الـ DecorationImage تلقائياً
                    ),

                    // زر رفع/تعديل الصورة (يختفي أو يتوقف أثناء التحميل لحماية العملية)
                    GestureDetector(
                      onTap: isUploading
                          ? null
                          : () => controller.pickAndUploadLogo(),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isUploading
                            ? 0.5
                            : 1.0, // تبهيت الزر أثناء الرفع
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: TColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.camera,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: TSizes.spaceBtwSections),

            // --- 2️⃣ قسم البطاقات الإحصائية (عرض فقط) ---
            Obx(() {
              return Column(
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        label: "العمولة",
                        value: "${controller.storeM.value.commissionRate}%",
                        icon: Iconsax.percentage_square,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      _buildStatCard(
                        label: "الحالة",
                        value: getStorStatus(
                          controller.storeM.value.storeStatus,
                        ),
                        icon: Iconsax.status,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Row(
                    children: [
                      _buildStatCard(
                        label: "التقييم",
                        value: controller.storeM.value.rating.toString(),
                        icon: Iconsax.star,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      _buildStatCard(
                        label: "التوثيق",
                        value: controller.storeM.value.isVerified
                            ? "موثق"
                            : "غير موثق",
                        icon: controller.storeM.value.isVerified
                            ? Iconsax.verify
                            : Iconsax.danger,
                        color: controller.storeM.value.isVerified
                            ? Colors.green
                            : Colors.red,
                      ),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: TSizes.spaceBtwSections),

            // --- 3️⃣ بطاقة حالة استقبال الطلبات تفاعلياً (مفتوح / مغلق) ---
            TRoundedContainer(
              showBorder: false,
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.sm,
                vertical: TSizes.xs,
              ),
              child: Obx(() {
                return SwitchListTile.adaptive(
                  activeColor: Colors.green,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TSizes.md,
                  ),
                  title: const Text(
                    "حالة استقبال الطلبات الحالي",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    controller.isStoreOpen.value
                        ? "المتجر مفتوح ويستقبل طلبات الآن"
                        : "المتجر مغلق مؤقتاً",
                    style: TextStyle(
                      color: controller.isStoreOpen.value
                          ? Colors.green
                          : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  secondary: Icon(
                    controller.isStoreOpen.value
                        ? Iconsax.cloud_lightning
                        : Iconsax.cloud_notif,
                    color: controller.isStoreOpen.value
                        ? Colors.green
                        : Colors.red,
                  ),
                  value: controller.isStoreOpen.value,
                  onChanged: (value) =>
                      _showStatusConfirmationDialog(context, controller, value),
                );
              }),
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // --- 4️⃣ المعلومات الأساسية ---
            TRoundedContainer(
              padding: const EdgeInsets.all(TSizes.md),
              showBorder: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "المعلومات الأساسية",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  TextFormField(
                    controller: controller.storeName,
                    decoration: const InputDecoration(
                      labelText: "اسم المتجر",
                      prefixIcon: Icon(Iconsax.shop),
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: controller.storeDescription,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "وصف المتجر",
                      prefixIcon: Icon(Iconsax.document_text),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // --- 5️⃣ بطاقة العنوان ---
            TRoundedContainer(
              showBorder: false,
              child: ListTile(
                leading: const Icon(Iconsax.location, color: TColors.primary),
                title: const Text("تفاصيل العنوان"),
                subtitle: const Text("المحافظة، الحي، الشارع ورقم المبنى"),
                trailing: const Icon(Iconsax.arrow_right_3),
                onTap: () => Get.to(() => const AddressSettingsScreen()),
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // --- 6️⃣ زر الحفظ السفلي مع مسافة أمان مريحة للتصفح ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.updateBasicProfile(),
                child: const Text("حفظ المعلومات الأساسية"),
              ),
            ),

            const SizedBox(
              height: 40,
            ), // مسافة حماية سفلية لمنع الالتصاق عند السحب
          ],
        ),
      ),
    );
  }

  void _showStatusConfirmationDialog(
    BuildContext context,
    ProfileControllerNew controller,
    bool newValue,
  ) {
    // تحديد نص الرسالة بناءً على الحالة الجديدة
    final String title = newValue ? "فتح المتجر؟" : "إغلاق المتجر؟";
    final String message = newValue
        ? "هل أنت متأكد من فتح المتجر؟ سيتمكن جميع الزبائن من تقديم طلبات جديدة الآن."
        : "تنبيه: إغلاق المتجر سيمنع المستخدمين تماماً من الطلب أو تصفح القائمة النشطة حتى تعيد فتحه.";

    Get.defaultDialog(
      title: title,
      titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      contentPadding: const EdgeInsets.all(TSizes.md),
      backgroundColor: Colors.white,
      radius: 12,

      // محتوى الرسالة التحذيرية
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
      ),

      // زر التراجع/الإلغاء
      textCancel: "تراجع",
      cancelTextColor: Colors.grey,
      onCancel: () {
        // لا نفعل شيء، سيغلق الديالوج تلقائياً ويحافظ السويتش على حالته الأصلية
      },

      // زر التأكيد والقبول
      textConfirm: "تأكيد العملية",
      confirmTextColor: Colors.white,
      buttonColor: newValue
          ? Colors.green
          : Colors.red, // تلوين الزر حسب خطورة الإجراء
      onConfirm: () {
        Get.back(); // إغلاق نافذة الديالوج أولاً
        controller.toggleStoreOpenStatus(
          newValue,
        ); // 🌟 تنفيذ العملية الفعلية وتحديث البيانات
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: TRoundedContainer(
        padding: const EdgeInsets.all(TSizes.md),
        backgroundColor: color.withOpacity(0.1),
        showBorder: true,
        borderColor: color.withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: TSizes.xs),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: TSizes.sm),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String getStorStatus(StoreStatus status) {
    if (status.name == StoreStatus.active.name) {
      return "نشط";
    } else if (status.name == StoreStatus.pending.name) {
      return "قيد المراجعة";
    } else if (status.name == StoreStatus.suspended.name) {
      return "معلق";
    } else {
      return status.name;
    }
  }
}




/*
class FormProfileScrren extends StatelessWidget {
  const FormProfileScrren({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileControllerNew());

    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          // --- قسم البطاقات الإحصائية (عرض فقط) ---
          Obx(() {
            return Column(
              children: [
                Row(
                  children: [
                    _buildStatCard(
                      label: "العمولة",
                      value: "${controller.storeM.value.commissionRate}%",
                      icon: Iconsax.percentage_square,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    _buildStatCard(
                      label: "الحالة",
                      value: getStorStatus(controller.storeM.value.storeStatus),
                      icon: Iconsax.status,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Row(
                  children: [
                    _buildStatCard(
                      label: "التقييم",
                      value: controller.storeM.value.rating.toString(),
                      icon: Iconsax.star,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    _buildStatCard(
                      label: "التوثيق",
                      value: controller.storeM.value.isVerified
                          ? "موثق"
                          : "غير موثق",
                      icon: controller.storeM.value.isVerified
                          ? Iconsax.verify
                          : Iconsax.danger,
                      color: controller.storeM.value.isVerified
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),
              ],
            );
          }),

          const SizedBox(height: TSizes.spaceBtwSections),

          // --- المعلومات الأساسية ---
          TRoundedContainer(
            padding: const EdgeInsets.all(TSizes.md),
            showBorder: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "المعلومات الأساسية",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                TextFormField(
                  controller: controller.storeName,
                  decoration: const InputDecoration(
                    labelText: "اسم المتجر",
                    prefixIcon: Icon(Iconsax.shop),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwInputFields),
                TextFormField(
                  controller: controller.storeDescription,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "وصف المتجر",
                    prefixIcon: Icon(Iconsax.document_text),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          // بطاقة العنوان
          TRoundedContainer(
            showBorder: false,
            child: ListTile(
              leading: const Icon(Iconsax.location, color: TColors.primary),
              title: const Text("تفاصيل العنوان"),
              subtitle: const Text("المحافظة، الحي، الشارع ورقم المبنى"),
              trailing: const Icon(Iconsax.arrow_right_3),
              onTap: () => Get.to(() => const AddressSettingsScreen()),
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.updateBasicProfile(),
              child: const Text("حفظ المعلومات الأساسية"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: TRoundedContainer(
        padding: const EdgeInsets.all(TSizes.md),
        backgroundColor: color.withOpacity(0.1),
        showBorder: true,
        borderColor: color.withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: TSizes.xs),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: TSizes.sm),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String getStorStatus(StoreStatus status) {
    if (status.name == StoreStatus.active.name) {
      return "نشط";
    } else if (status.name == StoreStatus.pending.name) {
      return "قيد المراجعة";
    } else if (status.name == StoreStatus.suspended.name) {
      return "معلق";
    } else {
      return status.name;
    }
  }
}
*/