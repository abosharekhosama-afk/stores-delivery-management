import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/TDashboardCardsShimmer.dart';
import 'package:stors_admin_panel/data/stor/controller/wallet_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/widgets/OrdersDistributionChart.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/widgets/SalesGrowthChart.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/widgets/TDashboardCard.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/wallet_model.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class DashboardMobail extends StatelessWidget {
  const DashboardMobail({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WalletController.instance;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("الرئيسة", style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: TSizes.spaceBtwSections),

              // --- استخدام StreamBuilder لجلب بيانات المحفظة ---
              StreamBuilder<StoreModel>(
                stream: controller.getWalletStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const TDashboardCardsShimmer();
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text("لا توجد بيانات حالياً"));
                  }

                  final storeData = snapshot.data!;
                  final wallet = storeData.wallet ?? WalletModel();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- البطاقات المالية ---
                      Row(
                        children: [
                          Expanded(
                            child: Tdashboardcard(
                              title: "إجمالي المبيعات",
                              subTitle: "${wallet.totalEarnings} ₪",
                              stats: 25,
                            ),
                          ),
                          const SizedBox(width: TSizes.spaceBtwItems),
                          Expanded(
                            child: Tdashboardcard(
                              title: "الرصيد القابل للسحب",
                              subTitle: "${wallet.availableBalance} ₪",
                              stats: 10,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems),
                      Row(
                        children: [
                          Expanded(
                            child: Tdashboardcard(
                              title: "الرصيد المسحوب",
                              subTitle: "${wallet.withdrawnAmount} ₪",
                              stats: 10,
                            ),
                          ),
                          const SizedBox(width: TSizes.spaceBtwItems),
                          Expanded(
                            child: Tdashboardcard(
                              title: "الرصيد تحت المعالجة",
                              subTitle:
                                  "${wallet.pendingBalance.toStringAsFixed(2)} ₪",
                              stats: 5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      // --- مؤشرات الأداء (KPIs) ---
                      Text(
                        "مؤشرات الأداء (KPIs)",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),

                      // تم استبدال Expanded بـ SizedBox أو تركها تأخذ حجمها الطبيعي
                      Row(
                        children: [
                          Expanded(
                            child: _buildRateIndicator(
                              context,
                              "نسبة القبول",
                              storeData.acceptanceRate,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: TSizes.spaceBtwItems),
                          Expanded(
                            child: _buildRateIndicator(
                              context,
                              "نسبة الرفض",
                              storeData.rejectionRate,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),
                      _buildRateIndicator(
                        context,
                        "الطلبات المكتملة",
                        storeData.completedOrders.toDouble(),
                        Colors.green,
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      // --- الرسوم البيانية ---
                      const Text("منحنى نمو المبيعات"),
                      const SizedBox(height: TSizes.spaceBtwItems),
                      SalesGrowthChart(
                        currentMonthSales: storeData.currentMonthSales,
                        previousMonthSales: storeData.previousMonthSales,
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      const Text("تحليل حالات الطلبات"),
                      const SizedBox(height: TSizes.spaceBtwItems),
                      OrdersDistributionChart(
                        total: storeData.totalOrders,
                        accepted: storeData.acceptedOrders,
                        rejected: storeData.rejectedOrders,
                        completed: storeData.completedOrders,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء مؤشر النسبة
  Widget _buildRateIndicator(
    BuildContext context,
    String label,
    double rate,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              "${rate.toStringAsFixed(1)}%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: rate / 100,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}

/*
 StreamBuilder<StoreModel>(
                stream: controller.getWalletStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // عرض شيمر أثناء التحميل (يمكنك استخدام الشيمر الذي صممناه سابقاً)
                    return const TDashboardCardsShimmer();
                  }

                  if (!snapshot.hasData) {
                    return const Text("لا توجد بيانات مالية");
                  }
                  final store = snapshot.data!;
                  storeData = store;
                  final wallet = store.wallet ?? WalletModel();

                  return Column(
                    children: [
                      // عرض إجمالي المبيعات من الفيربيز
                      Tdashboardcard(
                        title: "إجمالي المبيعات",
                        subTitle: "${wallet.totalEarnings} ₪",
                        stats:
                            25, // يمكنك حساب النسبة إذا كانت موجودة في الموديل
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),

                      // عرض الأرباح الحالية
                      Tdashboardcard(
                        title: "الرصيد القابل للسحب",
                        subTitle: "${wallet.availableBalance} ₪",
                        stats: 10,
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),

                      // عرض الأرباح الحالية
                      Tdashboardcard(
                        title: "الرصيد المسحوب",
                        subTitle: "${wallet.withdrawnAmount} ₪",
                        stats: 10,
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),

                      // عرض الأرباح الحالية
                      Tdashboardcard(
                        title: "الرصيد تحت المعالحة",
                        subTitle: "${wallet.pendingBalance} ₪",
                        stats: 10,
                      ),
                    ],
                  );
                },
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "مؤشرات الأداء (KPIs)",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Row(
                    children: [
                      // عرض نسبة القبول
                      Expanded(
                        child: _buildRateIndicator(
                          context,
                          "نسبة قبول الطلبات",
                          storeData.acceptanceRate,
                          Colors.blue,
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems),

                      // عرض نسبة الرفض
                      Expanded(
                        child: _buildRateIndicator(
                          context,
                          "نسبة رفض الطلبات",
                          storeData.rejectionRate,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: _buildRateIndicator(
                      context,
                      "نسبة الطلبات المكتملة",
                      storeData.completedOrders.toDouble(),
                      Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: TSizes.spaceBtwSections),
              const Text("منحنى نمو المبيعات"),
              SalesGrowthChart(
                currentMonthSales: storeData.currentMonthSales,
                previousMonthSales: storeData.previousMonthSales,
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              const Text("تحليل حالات الطلبات"),
              OrdersDistributionChart(
                total: storeData.totalOrders,
                accepted: storeData.acceptedOrders,
                rejected: storeData.rejectedOrders,
                completed: storeData.completedOrders,
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        ),
      ),
    );
*/
