import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/styles/shadows.dart';
import 'package:stors_admin_panel/features/features_authintication/controllers/store_financial_controller.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/device/device_utility.dart';

class FinancialScreen extends StatelessWidget {
  const FinancialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoreFinancialController());

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "المعلومات المالية للمتجر",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = controller.financialData.value;

                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: TDeviceUtils.isDesktopScreen(context)
                        ? 4
                        : 2,
                    mainAxisSpacing: TSizes.spaceBtwItems,
                    crossAxisSpacing: TSizes.spaceBtwItems,
                    mainAxisExtent: 140,
                  ),
                  children: [
                    _buildFinancialCard(
                      "إجمالي المبيعات",
                      data.totalSales,
                      Colors.blue,
                    ),
                    _buildFinancialCard(
                      "المبيعات المقبولة",
                      data.totalAccepted,
                      Colors.green,
                    ),
                    _buildFinancialCard(
                      "المرفوضات",
                      data.totalRejected,
                      Colors.red,
                    ),
                    _buildFinancialCard(
                      "نسبة العمولة",
                      "${(data.commissionRate * 100).toInt()}%",
                      Colors.orange,
                    ),
                    _buildFinancialCard(
                      "المبالغ المسحوبة",
                      data.totalWithdrawn,
                      Colors.purple,
                    ),
                    _buildFinancialCard(
                      "الرصيد القابل للسحب",
                      data.withdrawableBalance,
                      Colors.teal,
                      isHighlight: true,
                    ),
                  ],
                );
              }),

              const SizedBox(height: TSizes.spaceBtwSections),
              // هنا يمكنك إضافة جدول لعمليات السحب السابقة (Transaction History)
            ],
          ),
        ),
      ),
    );
  }

  // ودجت بناء البطاقة المالية
  Widget _buildFinancialCard(
    String title,
    dynamic value,
    Color color, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isHighlight ? color.withAlpha((0.1 * 255).round()) : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
        boxShadow: [TShadowStyle.verticalProductShadow],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            value is double
                ? "\$${value.toStringAsFixed(2)}"
                : value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


