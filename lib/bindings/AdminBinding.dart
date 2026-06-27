import 'package:get/get.dart';
import 'package:stors_admin_panel/data/Services/notification_controller.dart';
import 'package:stors_admin_panel/data/reposity/store_reposity.dart';
import 'package:stors_admin_panel/data/stor/controller/product/product_addition_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/store_order_controller.dart';
import 'package:stors_admin_panel/data/stor/controller/wallet_controller.dart';
import 'package:stors_admin_panel/features/personalizatuon/controllers/store_controller.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    // استخدم lazyPut لتوفير الذاكرة، سيتم إنشاؤه فقط عند الحاجة إليه
    //Get.lazyPut(() => StoreRepository(), fenix: true);
    Get.put(StoreRepository());
    Get.put(ProductAdditionController());
    Get.put(StoreOrderController());
    Get.put(NotificationController());
    Get.put(StoreController());
    Get.put(WalletController());
  }
}
