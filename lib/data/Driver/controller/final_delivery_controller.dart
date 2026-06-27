import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/driver/delivery_epository.dart';
import 'package:stors_admin_panel/data/stor/models/order_model.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class FinalDeliveryController extends GetxController {
  static FinalDeliveryController get instance => Get.find();

  var isLoading = true.obs;
  var mainOrders = <OrderModel>[].obs;
  StreamSubscription? _orderSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchShippedOrders();
  }

  void fetchShippedOrders() {
    try {
      isLoading.value = true;

      // إلغاء أي اشتراك قديم لتجنب تسريب الذاكرة
      _orderSubscription?.cancel();

      _orderSubscription = DeliveryRepository.instance
          .getShippedOrdersStream()
          .listen(
            (orders) {
              mainOrders.assignAll(orders);
              isLoading.value = false;
              debugPrint("✅ جلب بنجاح: ${orders.length} طلب");
            },
            onError: (error) {
              isLoading.value = false;
              TLoaders.errorSnackBar(
                title: 'خطأ في جلب البيانات',
                message: error.toString(),
              );
            },
          );
    } catch (e) {
      isLoading.value = false;
      TLoaders.errorSnackBar(title: 'خطأ مفاجئ', message: e.toString());
    }
  }

  Future<bool> completeFinalDelivery(String orderId, String inputCode) async {
    try {
      // إظهار لودر الشاشة كاملة لعملية التحديث
      final correctCode = await DeliveryRepository.instance.getDeliveryCode(
        orderId,
      );

      if (inputCode == correctCode) {
        await DeliveryRepository.instance.updateOrderStatusToDelivered(orderId);
        return true;
      }
      return false;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'فشل التحديث', message: e.toString());
      return false;
    }
  }

  @override
  void onClose() {
    _orderSubscription
        ?.cancel(); // ضروري جداً لإيقاف الـ Stream عند إغلاق الصفحة
    super.onClose();
  }
}
