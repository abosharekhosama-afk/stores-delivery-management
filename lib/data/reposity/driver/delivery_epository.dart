import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/Driver/model/driver_model.dart';
import 'package:stors_admin_panel/data/stor/models/order_model.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';

class DeliveryRepository extends GetxController {
  static DeliveryRepository get instance => Get.find();
  final _db = FirebaseFirestore.instance;

  // جلب الطلبات التي تخص هذا المندوب فقط
  Stream<List<StoreOrdersModel>> getMyDeliveries(String deliveryBoyId) {
    return _db
        .collection(StoreOrdersModel.getOrderCollectionName)
        .where(StoreOrdersModel.getDeliveryBoyId, isEqualTo: deliveryBoyId)
        .orderBy(StoreOrdersModel.getOrderDate, descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StoreOrdersModel.fromSnapshot(doc))
              .toList(),
        );
  }

  Future<void> confirmPickup({
    required String storeOrderId,
    required String deliveryBoyId,
  }) async {
    await _db
        .collection(StoreOrdersModel.getOrderCollectionName)
        .doc(storeOrderId)
        .update({
          StoreOrdersModel.getDeliveryBoyId:
              deliveryBoyId, // ربط الطلب بالمندوب
          StoreOrdersModel.getStatus:
              OrderStatus.shipped.name, // تحديث حالة المتجر (خرج)
          StoreOrdersModel.getDeliveryStatus:
              DeliveryStatus.pickedUp.name, // حالة التوصيل الجديدة
          StoreOrdersModel.getPickupDate: DateTime.now(), // توثيق وقت الاستلام
        });
  }

  /// جلب بيانات المندوب باستخدام المعرف الفريد
  Future<DriverModel> getDriverDetails(String driverId) async {
    try {
      final documentSnapshot = await _db
          .collection(DriverModel.driverCollectionName)
          .doc(driverId)
          .get();

      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        // تحويل البيانات من Map إلى Model
        return DriverModel.fromSnapshot(documentSnapshot);
      } else {
        // في حال لم يجد المستند
        throw "لم يتم العثور على بيانات المندوب في النظام.";
      }
    } on FirebaseException catch (e) {
      // معالجة أخطاء الفايربيز (مثل انقطاع الاتصال)
      throw "خطأ في قاعدة البيانات: ${e.message}";
    } catch (e) {
      // معالجة أي خطأ برمجى آخر
      throw "حدث خطأ غير متوقع: $e";
    }
  }

  // جلب الطلبات المشحونة كـ Stream
  Stream<List<OrderModel>> getShippedOrdersStream() {
    return _db
        .collection(OrderModel.getOrderCollectionName)
        .where(OrderModel.getStatus, isEqualTo: OrderStatus.shipped.name)
        .snapshots()
        .map((snapshot) {
          // تحويل البيانات هنا لتقليل العبء على الكنترولر
          return snapshot.docs.map((doc) {
            return OrderModel.fromSnapshot(doc);
          }).toList();
        })
        .handleError((error) {
          // معالجة الخطأ داخل الـ Stream نفسه
          debugPrint("Error in Repository Stream: $error");
          throw error;
        });
  }

  // تحديث حالة الطلب (التسليم النهائي)
  Future<void> updateOrderStatusToDelivered(String orderId) async {
    await _db
        .collection(OrderModel.getOrderCollectionName)
        .doc(orderId)
        .update({
          OrderModel.getStatus: OrderStatus.delivered.name,
          OrderModel.getDeliveryDate: FieldValue.serverTimestamp(),
        });
  }

  // جلب كود التسليم
  Future<String> getDeliveryCode(String orderId) async {
    final doc = await _db
        .collection(OrderModel.getOrderCollectionName)
        .doc(orderId)
        .get();
    return doc.data()?[OrderModel.getDeliveryCode] ?? "";
  }

  // جلب كافة البيانات من Firebase
  Future<List<Map<String, dynamic>>> fetchAllShippingData() async {
    try {
      final snapshot = await _db.collection('ShippingRates').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (e) {
      throw 'حدث خطأ في قاعدة البيانات: ${e.message}';
    } catch (e) {
      throw 'عذراً، حدث خطأ غير متوقع أثناء جلب البيانات.';
    }
  }
}
