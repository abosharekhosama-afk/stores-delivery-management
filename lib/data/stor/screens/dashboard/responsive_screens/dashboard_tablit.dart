import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/TDashboardCardsShimmer.dart';
import 'package:stors_admin_panel/data/stor/controller/wallet_controller.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/table/data_table.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/widgets/OrdersDistributionChart.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/widgets/SalesGrowthChart.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/widgets/TDashboardCard.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/wallet_model.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class DashboardTablet extends StatelessWidget {
  const DashboardTablet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WalletController.instance;

    return Scaffold(
      body: StreamBuilder<StoreModel>(
        stream: controller.getWalletStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const TDashboardCardsShimmer();
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("لا توجد بيانات مالية"));
          }

          final store = snapshot.data!;
          final wallet = store.wallet ?? WalletModel();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "لوحة التحكم - تابلت",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  // --- البطاقات المالية: توزيع شبكي (2 في كل صف) للتابلت ---
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: TSizes.spaceBtwItems,
                    crossAxisSpacing: TSizes.spaceBtwItems,
                    childAspectRatio: 2.5, // التحكم في ارتفاع البطاقة
                    children: [
                      Tdashboardcard(
                        title: "إجمالي المبيعات",
                        subTitle: "${wallet.totalEarnings} ₪",
                        stats: 25,
                      ),
                      Tdashboardcard(
                        title: "الرصيد القابل للسحب",
                        subTitle: "${wallet.availableBalance} ₪",
                        stats: 10,
                      ),
                      Tdashboardcard(
                        title: "الرصيد المسحوب",
                        subTitle: "${wallet.withdrawnAmount} ₪",
                        stats: 10,
                      ),
                      Tdashboardcard(
                        title: "الرصيد تحت المعالجة",
                        subTitle: "${wallet.pendingBalance} ₪",
                        stats: 10,
                      ),
                    ],
                  ),

                  const SizedBox(height: TSizes.spaceBtwSections),

                  // --- المخططات البيانية: وضعها بجانب بعضها البعض ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // مخطط المبيعات (يأخذ مساحة أكبر)
                      Expanded(
                        flex: 2,
                        child: TRoundedContainer(
                          padding: const EdgeInsets.all(TSizes.md),
                          showBorder: true,
                          child: Column(
                            children: [
                              const Text(
                                "منحنى نمو المبيعات",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: TSizes.spaceBtwItems),
                              SalesGrowthChart(
                                currentMonthSales: store.currentMonthSales,
                                previousMonthSales: store.previousMonthSales,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),

                      // مخطط توزيع الطلبات
                      Expanded(
                        flex: 1,
                        child: TRoundedContainer(
                          padding: const EdgeInsets.all(TSizes.md),
                          showBorder: true,
                          child: Column(
                            children: [
                              const Text(
                                "حالات الطلبات",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: TSizes.spaceBtwItems),
                              OrdersDistributionChart(
                                total: store.totalOrders,
                                accepted: store.acceptedOrders,
                                rejected: store.rejectedOrders,
                                completed: store.completedOrders,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: TSizes.spaceBtwSections),

                  // --- جدول الطلبات ---
                  Text(
                    "آخر الطلبات",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  const TRoundedContainer(
                    showBorder: true,
                    child: DashboardOrderDataTable(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
