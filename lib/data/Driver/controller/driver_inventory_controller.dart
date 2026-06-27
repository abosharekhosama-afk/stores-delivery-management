import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class DriverInventoryController extends GetxController {
  static DriverInventoryController get instance => Get.find();
  final _db = FirebaseFirestore.instance;

  // القائمة الأصلية والقائمة المفلترة للبحث
  var allPickedOrders = <StoreOrdersModel>[].obs;
  var filteredOrders = <StoreOrdersModel>[].obs;

  var searchQuery = "".obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyInventory();

    // مستمع لعملية البحث: يقوم بالتصفية تلقائياً عند تغيير نص البحث
    debounce(
      searchQuery,
      (_) => applyFilter(),
      time: const Duration(milliseconds: 300),
    );
  }

  void fetchMyInventory() {
    String myId = AuthenticationRepository.instance.authUser!.uid;

    _db
        .collection(StoreOrdersModel.getOrderCollectionName)
        .where(StoreOrdersModel.getDeliveryBoyId, isEqualTo: myId)
        .where(
          StoreOrdersModel.getStatus,
          isEqualTo: OrderStatus.shipped.name,
        ) // تم الخروج من المتجر
        .snapshots()
        .listen((snapshot) {
          allPickedOrders.assignAll(
            snapshot.docs
                .map((doc) => StoreOrdersModel.fromSnapshot(doc))
                .toList(),
          );
          applyFilter();
          isLoading.value = false;
        });
  }

  void applyFilter() {
    if (searchQuery.value.isEmpty) {
      filteredOrders.assignAll(allPickedOrders);
    } else {
      filteredOrders.assignAll(
        allPickedOrders
            .where(
              (order) =>
                  order.mainOrderId.contains(searchQuery.value) ||
                  order.storeId.toLowerCase().contains(
                    searchQuery.value.toLowerCase(),
                  ),
            )
            .toList(),
      );
    }
  }

  Future<void> handoverOrdersToHub() async {
    try {
      isLoading.value = true;
      final batch = _db.batch();

      for (var order in allPickedOrders) {
        final docRef = _db
            .collection(StoreOrdersModel.getOrderCollectionName)
            .doc(order.storeOrderId);

        batch.update(docRef, {
          StoreOrdersModel.getDeliveryStatus:
              DeliveryStatus.delivered.name, // حالة جديدة: في المركز
        });
      }

      await batch.commit();

      Get.back(); // إغلاق الدايالوج
      TLoaders.successSnackBar(
        title: 'نجاح',
        message: 'تم تسليم جميع الطلبات للمركز بنجاح',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'خطأ',
        message: 'حدث خطأ أثناء التسليم: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
