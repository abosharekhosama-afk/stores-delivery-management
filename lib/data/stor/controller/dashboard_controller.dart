import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart'; // تأكد من استخدام موديل طلبات المتجر
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';

class DashboardController extends GetxController {
  static DashboardController get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // المتغيرات المراقبة (Reactive)
  final String storeId = AuthenticationRepository.instance.authUser?.uid ?? "";

  RxList<double> weeklySales = List<double>.filled(7, 0.0).obs;
  RxMap<OrderStatus, int> orderStatusData = <OrderStatus, int>{}.obs;
  RxMap<OrderStatus, double> totalAmount = <OrderStatus, double>{}.obs;
  RxList<StoreOrdersModel> allOrders = <StoreOrdersModel>[].obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    // بدء الاستماع للطلبات بمجرد تشغيل الكنترولر
    fetchAndCalculateStoreData();
  }

  void fetchAndCalculateStoreData() {
    try {
      isLoading.value = true;

      // الاستماع للطلبات التي تحتوي على storeId الخاص بهذا المتجر فقط
      _db
          .collection(
            StoreOrdersModel.getOrderCollectionName,
          ) // تأكد من اسم الكولكشن لديك
          .where(StoreOrdersModel.getStoreId, isEqualTo: storeId)
          .snapshots()
          .listen((snapshot) {
            // 1. تحويل المستندات إلى موديلات
            final fetchedOrders = snapshot.docs
                .map((doc) => StoreOrdersModel.fromSnapshot(doc))
                .toList();

            allOrders.assignAll(fetchedOrders);

            // 2. إعادة حساب الإحصائيات بناءً على البيانات الجديدة
            _calculateWeeklySales(fetchedOrders);
            _calculateOrderStatusData(fetchedOrders);

            isLoading.value = false;
          });
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
      isLoading.value = false;
    }
  }

  // حساب المبيعات الأسبوعية (الرسم البياني للأعمدة)
  void _calculateWeeklySales(List<StoreOrdersModel> orders) {
    List<double> temporarySales = List<double>.filled(7, 0.0);
    DateTime now = DateTime.now();
    DateTime startOfWeek = THelperFunctions.getStartOfWeek(now);

    for (var order in orders) {
      // نتحقق إذا كان الطلب في الأسبوع الحالي
      if (order.orderDate.isAfter(startOfWeek)) {
        // تحويل اليوم إلى index (0 للاتنين، 6 للأحد - حسب لغة Dart)
        int index = (order.orderDate.weekday - 1) % 7;
        temporarySales[index] += order.items.fold(
          0.0,
          (sum, item) => sum + (item.price * item.quantity),
        );
      }
    }
    weeklySales.value = temporarySales;
  }

  // حساب حالات الطلبات (الرسم البياني الدائري)
  void _calculateOrderStatusData(List<StoreOrdersModel> orders) {
    orderStatusData.clear();
    Map<OrderStatus, double> tempAmounts = {
      for (var status in OrderStatus.values) status: 0.0,
    };
    Map<OrderStatus, int> tempCounts = {};

    for (var order in orders) {
      final status = order.status;
      tempCounts[status] = (tempCounts[status] ?? 0) + 1;
      tempAmounts[status] =
          (tempAmounts[status] ?? 0.0) +
          order.items.fold(
            0.0,
            (sum, item) => sum + (item.price * item.quantity),
          );
    }

    orderStatusData.addAll(tempCounts);
    totalAmount.value = tempAmounts;
  }

  String getDisplayStatusName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return "مرسل";

      case OrderStatus.processing:
        return "قيد التحضير";

      case OrderStatus.shipped:
        return "تم الشحن";

      case OrderStatus.delivered:
        return "تم توصيله";

      case OrderStatus.cancelled:
        return "ملغي";

      default:
        return "غير معروف";
    }
  }
}














/**
 * 3. تحرير الأموال + إحصائيات الاكتمال والمبيعات الأسبوعية
 */
/*exports.onMainOrderDelivered = onDocumentUpdated("Orders/{mainOrderId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();

    if (newData.Status === "delivered" && previousData.Status !== "delivered") {
        const mainOrderId = event.params.mainOrderId;

        try {
            const storeOrdersSnapshot = await admin.firestore()
                .collection("StoreOrders")
                .where("MainOrderId", "==", mainOrderId)
                .get();

            const batch = admin.firestore().batch();

            for (const storeOrderDoc of storeOrdersSnapshot.docs) {
                const storeOrderData = storeOrderDoc.data();
                const storeId = storeOrderData.StoreId;
                const items = storeOrderData.Items || [];

                const storeRef = admin.firestore().collection("Stores").doc(storeId);
                const storeDoc = await storeRef.get();
                const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

                let finalStoreTotal = 0;
                items.forEach(item => {
                    if (item.itemStatus !== "rejected") {
                        finalStoreTotal += (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
                    }
                });

                const finalNetProfit = Math.round((finalStoreTotal * (1 - (commRate / 100))) * 100) / 100;

                if (finalNetProfit > 0) {
                    batch.update(storeRef, {
                        "wallet.pendingBalance": admin.firestore.FieldValue.increment(-finalNetProfit),
                        "wallet.availableBalance": admin.firestore.FieldValue.increment(finalNetProfit),
                        "wallet.totalEarnings": admin.firestore.FieldValue.increment(finalNetProfit),
                        // ✅ تحديث الإحصائيات الأسبوعية والكلية هنا لضمان أنها مبيعات حقيقية مستلمة
                        "completedOrders": admin.firestore.FieldValue.increment(1),
                        "currentWeekSales": admin.firestore.FieldValue.increment(finalNetProfit),
                        "totalSales": admin.firestore.FieldValue.increment(finalNetProfit)
                    });

                    const transRef = admin.firestore().collection("Transactions").doc();
                    batch.set(transRef, {
                        storeId, mainOrderId, orderId: storeOrderDoc.id,
                        amount: finalNetProfit, type: "payout_cleared", status: "completed",
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                }
            }
            
            // تحديث إحصائيات الإدارة العامة (النمو الشهري)
            const now = new Date();
            const monthKey = `${now.getFullYear()}-${now.getMonth() + 1}`;
            
            batch.set(getGlobalRef(), {
                completedOrders: admin.firestore.FieldValue.increment(1),
                [`monthlySales.${monthKey}`]: admin.firestore.FieldValue.increment(totalPlatformProfit)
            }, { merge: true });


            await batch.commit();
        } catch (error) {
            console.error("🔥 Error in onMainOrderDelivered:", error);
        }
    }
});*/




/**
 * 3. تحرير الأموال عند وصول الطلب الرئيسي للحالة النهائية (تم التوصيل)
 */
/*
exports.onMainOrderDelivered = onDocumentUpdated("Orders/{mainOrderId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();

    // التأكد من تغير الحالة إلى delivered
    if (newData.Status === "delivered" && previousData.Status !== "delivered") {
        const mainOrderId = event.params.mainOrderId;

        try {
            // جلب كافة طلبات المتاجر المرتبطة بهذا الطلب الرئيسي
            const storeOrdersSnapshot = await admin.firestore()
                .collection("StoreOrders")
                .where("MainOrderId", "==", mainOrderId)
                .get();

            const batch = admin.firestore().batch();

            for (const storeOrderDoc of storeOrdersSnapshot.docs) {
                const storeOrderData = storeOrderDoc.data();
                const storeId = storeOrderData.StoreId;
                const items = storeOrderData.Items || [];

                // جلب بيانات المتجر لمعرفة نسبة العمولة
                const storeRef = admin.firestore().collection("Stores").doc(storeId);
                const storeDoc = await storeRef.get();
                const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

                // حساب الربح الصافي الفعلي للمنتجات غير المرفوضة
                let finalStoreTotal = 0;
                items.forEach(item => {
                    if (item.itemStatus !== "rejected") {
                        finalStoreTotal += (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
                    }
                });

                const finalNetProfit = Math.round((finalStoreTotal * (1 - (commRate / 100))) * 100) / 100;

                if (finalNetProfit > 0) {
                    // تحريك الأموال داخل المحفظة
                    batch.update(storeRef, {
                        "wallet.pendingBalance": admin.firestore.FieldValue.increment(-finalNetProfit),
                        "wallet.availableBalance": admin.firestore.FieldValue.increment(finalNetProfit),
                        "wallet.totalEarnings": admin.firestore.FieldValue.increment(finalNetProfit)
                    });

                    // تسجيل معاملة اكتمال الربح
                    const transRef = admin.firestore().collection("Transactions").doc();
                    batch.set(transRef, {
                        storeId,
                        mainOrderId,
                        orderId: storeOrderDoc.id,
                        amount: finalNetProfit,
                        type: "payout_cleared",
                        status: "completed",
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                }
            }

            await batch.commit();
            console.log(`✅ Funds cleared for all stores in main order: ${mainOrderId}`);
        } catch (error) {
            console.error("🔥 Error in onMainOrderDelivered:", error);
        }
    }
});
*/

