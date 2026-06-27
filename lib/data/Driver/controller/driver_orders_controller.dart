import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';

class DriverOrdersController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final String driverId = AuthenticationRepository.instance.authUser!.uid;

  var pickedUpOrders = <StoreOrdersModel>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyPickedUpOrders();
  }

  void fetchMyPickedUpOrders() {
    try {
      isLoading.value = true;

      // الاستعلام عن الطلبات التي استلمها المندوب ولم يتم تسليمها للعميل النهائي بعد
      _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .where('deliveryBoyId', isEqualTo: driverId)
          .where(
            'deliveryStatus',
            isEqualTo: 'pickedUp',
          ) // الحالة التي وضعناها في الـ Repository
          .snapshots()
          .listen((snapshot) {
            pickedUpOrders.assignAll(
              snapshot.docs
                  .map((doc) => StoreOrdersModel.fromSnapshot(doc))
                  .toList(),
            );
            isLoading.value = false;
          });
    } catch (e) {
      debugPrint("Error fetching driver orders: $e");
      isLoading.value = false;
    }
  }
}
