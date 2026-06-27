import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/anim/TDelayedSlideIn.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/TransactionListShimmer.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/TransactionShimmer.dart';
import 'package:stors_admin_panel/data/stor/controller/wallet_controller.dart';
import 'package:intl/intl.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/wallet_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart'; // ستحتاج هذه المكتبة لتنسيق التاريخ

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // استدعاء المتحكم
    final controller = Get.put(WalletController());
    final scrollController = ScrollController();
    double lastScrollPosition = 0.0;

    scrollController.addListener(() {
      double currentPosition = scrollController.position.pixels;

      // مراقبة اتجاه الحركة لإلغاء حركة كروت الأنيميشن عند الصعود للأعلى
      if (currentPosition > lastScrollPosition && currentPosition > 0) {
        controller.isScrollingDown.value = true;
      } else if (currentPosition < lastScrollPosition) {
        controller.isScrollingDown.value = false;
      }
      lastScrollPosition = currentPosition;

      // جلب 10 عمليات إضافية عند الاقتراب من الحافة بـ 200 بكسل
      if (currentPosition >= scrollController.position.maxScrollExtent - 200) {
        controller.fetchMoreData();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        controller: scrollController, // ربط مستمع الحركة هنا
        slivers: [
          // 1. AppBar عصري مع رصد مباشر للرصيد القابل للسحب
          SliverAppBar(
            expandedHeight: 251.0,
            floating: false,
            pinned: true,
            actions: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // نغير لون الأيقونة بناءً على وضع التمرير
                  return IconButton(
                    icon: Icon(
                      Icons.picture_as_pdf,
                      // إذا كان الـ AppBar مفتوحاً يكون أبيض، وإذا أُغلق يصبح بلون أساسي أو أسود
                      color: (constraints.biggest.height < 120)
                          ? Colors.black87
                          : Colors.white,
                    ),
                    tooltip: "تصدير كشف حساب",
                    onPressed: () => _handleExportPdf(controller),
                  );
                },
              ),
            ],

            backgroundColor: const Color(0xFFF8F9FA),

            // نستخدم دالة تتابع الارتفاع للحصول على تحكم حقيقي في الألوان والنصوص
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // حساب الارتفاع الحالي أثناء التمرير
                double currentHeight = constraints.biggest.height;
                // جلب ارتفاع الـ AppBar في حالة الالتصاق التام (يختلف بحسب الجهاز)
                double appBarCollapsedHeight =
                    kToolbarHeight + MediaQuery.of(context).padding.top;

                // حساب نسبة الإغلاق: 1.0 يعني مفتوح بالكامل، 0.0 يعني مغلق (ملتصق) تماماً
                double isExpandedPercent =
                    (currentHeight - appBarCollapsedHeight) /
                    (250.0 - appBarCollapsedHeight);
                isExpandedPercent = isExpandedPercent.clamp(0.0, 1.0);

                // يتحقق الشرط إذا تم إغلاق الأب بار بنسبة تزيد عن 80%
                bool isCollapsed = isExpandedPercent < 0.2;

                return FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  centerTitle: true,

                  // العنوان الصغير الذي يظهر فقط عند الإغلاق والالتصاق
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: isCollapsed ? 1.0 : 0.0,
                    child: StreamBuilder<StoreModel>(
                      stream: controller.getWalletStream(),
                      builder: (context, snapshot) {
                        final store = snapshot.data;
                        final wallet = store?.wallet;
                        final available = wallet?.availableBalance ?? 0.0;

                        return Row(
                          // mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(width: TSizes.defaultSpace),
                            const Text(
                              " رصيد المحفظة :  ",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "₪ ${available.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // المحتوى الكبير (كارت الرصيد) الذي يختفي تدريجياً أثناء الصعود
                  background: AnimatedOpacity(
                    duration: const Duration(milliseconds: 100),
                    // يختفي الكارت تدريجياً متزامناً مع السحب للأعلى
                    opacity: isExpandedPercent,
                    child: Container(
                      // تلوين الخلفية الكبيرة بلون متناسق ومريح مع الكارت العصري
                      color: const Color(0xFFF8F9FA),
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 50,
                        left: 16,
                        right: 16,
                        bottom: 10,
                      ),
                      child: _buildModernWallet(context, controller),
                    ),
                  ),
                );
              },
            ),

            /*
            title: LayoutBuilder(
              builder: (context, constraints) {
                // حساب المسافة لتحديد متى يظهر العنوان
                var top = constraints.biggest.height;
                // يظهر العنوان المدمج فقط عندما يقترب الـ AppBar من حالة الالتصاق (أقل من 120 بكسل)
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: top < 120 ? 1.0 : 0.0,
                  child: StreamBuilder<StoreModel>(
                    stream: controller.getWalletStream(),
                    builder: (context, snapshot) {
                      final store = snapshot.data;
                      final wallet = store?.wallet;
                      final available = wallet?.availableBalance ?? 0.0;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "المحفظة: ",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "₪ ${available.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors
                                  .green, // تلوين الرصيد بالأخضر المالي المريح
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );

                /*
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  // يظهر العنوان فقط عندما يقترب الـ AppBar من حالة الالتصاق (Pinned)
                  opacity: top < 120 ? 1.0 : 0.0,
                  child: const Text(
                    "العمليات المالية",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );*/
              },
            ),
*/
            /* flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1.0,
              background: Column(
                children: [
                  SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildModernWallet(context, controller),
                  ),
                ],
              ),
            ),*/

            /*
            flexibleSpace: FlexibleSpaceBar(
              // 5. تعطيل العنوان الافتراضي للـ FlexibleSpaceBar لأنه يتداخل مع العنوان الذي وضعناه فوق
              expandedTitleScale: 1.0,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [TColors.borderPrimary, TColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: StreamBuilder<StoreModel>(
                  stream: controller.getWalletStream(),
                  builder: (context, snapshot) {
                    final store = snapshot.data;
                    final wallet = store?.wallet ?? WalletModel();
                    final available = wallet.availableBalance;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "الرصيد القابل للسحب",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "₪ ${available.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _showWithdrawDialog(
                            context,
                            controller,
                            available,
                          ),
                          icon: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: TColors.primary,
                          ),
                          label: const Text("طلب سحب رصيد"),
                          style: ElevatedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.zero, // حواف حادة بزاوية 90 درجة
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: TColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          */
          ),

          // 2. تفاصيل الأرصدة الأخرى (المعلق والإجمالي)
          /*        SliverToBoxAdapter(
            child: StreamBuilder(
              stream: controller.getWalletStream(),
              builder: (context, snapshot) {
                final store = snapshot.data;
                final wallet = store?.wallet ?? WalletModel();
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildStatCard(
                        "بانتظار التأكيد",
                        "₪ ${wallet.pendingBalance.toStringAsFixed(2)}",
                        Icons.hourglass_empty,
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        "إجمالي الأرباح",
                        "₪ ${wallet.totalEarnings.toStringAsFixed(2)}",
                        Icons.trending_up,
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        "إجمالي المسحوبات",
                        "₪ ${wallet.withdrawnAmount.toStringAsFixed(2)}",
                        Icons.wallet,
                        Colors.green,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
*/
          // أضف هذا التبويب في الـ Slivers تحت كروت الأرصدة مباشرة
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(
                  0.08,
                ), // خلفية ناعمة محيطة بالشريط
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Row(
                children:
                    [
                      {'label': 'الكل', 'value': 'الكل'},
                      {'label': 'الأرباح', 'value': 'order_revenue'},
                      {'label': 'المرتجعات', 'value': 'refund'},
                      {'label': 'السحوبات', 'value': 'السحوبات'},
                    ].map((filter) {
                      return Obx(() {
                        final isSelected =
                            controller.selectedFilter.value == filter['value'];

                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                controller.changeFilter(filter['value']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                // تأثير الانتقال اللوني العصري
                                color: isSelected
                                    ? TColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: TColors.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  filter['label']!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      });
                    }).toList(),
              ),
            ),

            /* child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    [
                      {'label': 'الكل', 'value': 'الكل'},
                      {'label': 'الأرباح', 'value': 'order_revenue'},
                      {'label': 'المرتجعات', 'value': 'refund'},
                      {'label': 'السحوبات', 'value': 'السحوبات'},
                    ].map((option) {
                      return Expanded(
                        // 🌟 جعل العناصر تتوزع بالتساوي على كامل عرض الشاشة
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                          ), // مسافة صغيرة بين الرقاقات
                          child: Obx(() {
                            final isSelected =
                                controller.selectedFilter.value ==
                                option['value'];
                            return ChoiceChip(
                              // لضمان توسط النص تماماً وبقاء الشكل متناسقاً
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              label: FittedBox(
                                // يحمي النص من الاختفاء أو الـ Overflow على الشاشات الصغيرة
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  option['label']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) =>
                                  controller.changeFilter(option['value']!),
                              selectedColor: TColors.primary,
                              backgroundColor: Colors.grey.shade100,
                              showCheckmark:
                                  false, // إلغاء علامة الصح الافتراضية للحفاظ على المساحة الأفادية للكلمة
                            );
                          }),
                        ),
                      );
                    }).toList(),
              ),
            ),
          */
          ),
          /*
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children:
                    [
                      {'label': 'كل العمليات', 'value': 'الكل'},
                      {'label': 'طلبات السحب', 'value': 'السحوبات'},
                      {'label': 'طلبات السحب', 'value': 'السحوبات'},
                      {'label': 'طلبات السحب', 'value': 'السحوبات'},
                    ].map((option) {
                      return Obx(() {
                        final isSelected =
                            controller.selectedFilter.value == option['value'];
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ChoiceChip(
                            label: Text(option['label']!),
                            selected: isSelected,
                            onSelected: (_) =>
                                controller.changeFilter(option['value']!),
                            selectedColor: TColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        );
                      });
                    }).toList(),
              ),
            ),
          ),
*/
          // 3. عنوان قائمة الحركات المالية
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "آخر العمليات المالية",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ),
          ),

          // 4. عرض العمليات المالية بالطريقة الاقتصادية الذكية (المحدث)
          Obx(() {
            // حالة التحميل الأولية للـ 15 عنصر أول مرة
            if (controller.isLoading.value) {
              return const TransactionListShimmer(
                itemCount: 7,
              ); // استبدال المؤشر القديم بشيمر احترافي متناسق
            }

            // حالة عدم وجود أي عمليات مالية بالمتجر
            if (controller.displayTransactions.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("لا توجد عمليات حالياً"),
                  ),
                ),
              );
            }

            // بناء القائمة الموفرة
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // تحقق النهاية الذكي: إذا وصلنا لآخر القائمة وهناك المزيد من البيانات
                  if (index == controller.displayTransactions.length) {
                    // يظهر مؤشر التحميل السفلي فقط عند النزول الفعلي وجود بيانات قيد الجلب
                    if (controller.isMoreLoading.value &&
                        controller.isScrollingDown.value) {
                      return const TransactionShimmer(); // شيمر مفرد بالأسفل أثناء التمرير اللانهائي (Pagination)
                    }
                    return const SizedBox(height: 40);
                  }

                  final data =
                      controller.displayTransactions[index].data()
                          as Map<String, dynamic>;

                  // إحاطة العنصر بـ TDelayedSlideIn مع تمرير حالة اتجاه السكرول لضمان الـ UX
                  return TDelayedSlideIn(
                    delayInMilliseconds: (index % 20) * 50,
                    direction: SlideDirection.bottomToTop,
                    isScrollingDown: controller.isScrollingDown.value,
                    child: _buildTransactionItem(data),
                  );
                },
                // نزيد الطول بمقدار 1 لتهيئة مساحة الـ Shimmer السفلي للـ Pagination
                childCount:
                    controller.displayTransactions.length +
                    (controller.hasMore.value ? 1 : 0),
              ),
            );
          }),

          // 4. قائمة الحركات المالية الحقيقية من Firestore
          /*
          StreamBuilder<QuerySnapshot>(
            stream: controller.getTransactionsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text("لا توجد عمليات حالياً")),
                );
              }

              final transactions = snapshot.data!.docs;

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final data =
                      transactions[index].data() as Map<String, dynamic>;
                  return _buildTransactionItem(data);
                }, childCount: transactions.length),
              );
            },
          ),
        */
        ],
      ),
    );
  }

  // بطاقة إحصائية صغيرة
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // عنصر الحركة المالية المربوط بالبيانات
  Widget _buildTransactionItem(Map<String, dynamic> data) {
    final double amount = (data['amount'] ?? 0.0).toDouble();
    final String type = data['type'] ?? 'unknown';
    final String status = data['status'] ?? 'pending';
    final Timestamp? timestamp = data['createdAt'] as Timestamp?;

    // تنسيق التاريخ
    final String dateStr = timestamp != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
        : "";

    // تحديد الأيقونة واللون بناءً على نوع العملية
    IconData icon;
    Color color;
    String title;

    if (type == 'order_revenue') {
      icon = Icons.add_shopping_cart;
      color = Colors.orange;
      title = "أرباح طلب #${data['orderId']?.toString().substring(0, 5)}...";
    } else if (type == 'refund') {
      icon = Icons.history;
      color = Colors.red;
      title = "مرتجع طلب";
    } else if (type == 'payout_cleared') {
      icon = Icons.cached;
      color = Colors.green;
      title = "تحرير رصيد";
    } else if (type == 'withdrawal') {
      icon = Icons.account_balance_wallet;
      color = Colors.blue;
      title = "سحب رصيد";
    } else {
      icon = Icons.account_balance_wallet;
      color = Colors.purple;
      title = "معاملة مجهولة";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha((0.1 * 255).round()),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(dateStr, style: const TextStyle(fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${amount > 0 ? '+' : ''} ₪ ${amount.toStringAsFixed(2)}",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              status == 'pending' ? "معلق" : "مكتمل",
              style: TextStyle(
                color: status == 'pending' ? Colors.orange : Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // نافذة طلب السحب المحسنة مع التحقق من الرصيد
  void _showWithdrawDialog(
    BuildContext context,
    WalletController controller,
    double availableBalance,
  ) {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "طلب سحب رصيد",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "الرصيد المتاح حالياً: ₪ ${availableBalance.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "المبلغ المطلوب",
                prefixText: "₪ ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  double? requestedAmount = double.tryParse(
                    amountController.text,
                  );
                  if (requestedAmount != null &&
                      requestedAmount > 0 &&
                      requestedAmount <= availableBalance) {
                    controller.requestWithdrawal(requestedAmount);
                  } else {
                    TLoaders.errorSnackBar(
                      title: "خطأ",
                      message: "المبلغ المدخل غير صحيح أو يتجاوز رصيدك المتاح",
                    );
                  }
                },

                child: const Text(
                  "تأكيد طلب السحب",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _handleExportPdf(WalletController controller) async {
    try {
      // 1. إظهار مؤشر تحميل بسيط
      Get.snackbar(
        "جاري التحضير",
        "يتم الآن تجهيز كشف الحساب...",
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
      );

      // 2. جلب آخر بيانات الحركات المالية من الـ Stream (بدون الحاجة للاشتراك الدائم)
      final transactionsSnapshot = await controller
          .getTransactionsStream()
          .first;

      // تحويل الـ QuerySnapshot إلى List<Map>
      final List<Map<String, dynamic>> transactionsList = transactionsSnapshot
          .docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // 3. جلب بيانات المحفظة للرصيد الإجمالي
      final walletData = await controller.getWalletStream().first;

      // 4. استدعاء خدمة الـ PDF
      /* await PdfService.generateTransactionReport(
        storeName: "متجر أسامة أبو شارخ", // يمكنك جلب الاسم من AuthController
        transactions: transactionsList,
        totalBalance: walletData.availableBalance,
      );*/
    } catch (e) {
      TLoaders.errorSnackBar(title: "خطأ", message: "فشل توليد الملف: $e");
    }
  }

  Widget _buildModernWallet(BuildContext context, WalletController controller) {
    return StreamBuilder<StoreModel>(
      stream: controller.getWalletStream(),
      builder: (context, snapshot) {
        final store = snapshot.data;
        final wallet = store?.wallet ?? WalletModel();
        final available = wallet.availableBalance;

        return GestureDetector(
          onTap: () => _showWithdrawDialog(
            context,
            controller,
            available,
          ), // استدعاء البوتم شيت
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [TColors.black, TColors.borderDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: TColors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: TColors.borderDark.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "الرصيد المتاح للسحب (اضغط للتحويل)",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Icon(Iconsax.wallet_3, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "₪$available",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _walletSubItem(
                      "المعلق",
                      "₪${wallet.pendingBalance.toPrecision(2)}",
                    ),
                    _walletSubItem("المسحوب", "₪${wallet.withdrawnAmount}"),
                    _walletSubItem("الإجمالي", "₪${wallet.totalEarnings}"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _walletSubItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
