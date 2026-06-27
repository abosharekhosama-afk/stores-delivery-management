
/*
class VendorOrderManagement extends StatelessWidget {
  const VendorOrderManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // الأربعة أقسام التي طلبتها
      child: Scaffold(
        appBar: AppBar(
          title: const Text("إدارة طلبات المتجر"),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: TColors.primary,
            tabs: [
              Tab(text: "جديدة"),
              Tab(text: "قيد التجهيز"),
              Tab(text: "جاهزة للاستلام"),
              Tab(text: "مرفوضة"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OrderItemsList(statusTab: 'new'),
            OrderItemsList(statusTab: 'processing'),
            OrderItemsList(statusTab: 'ready'),
            OrderItemsList(statusTab: 'rejected'),
          ],
        ),
      ),
    );
  }
}
*/