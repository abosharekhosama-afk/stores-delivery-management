import 'package:get/get.dart';
import 'package:stors_admin_panel/data/Driver/controller/driver_profile_controller.dart';
import 'package:stors_admin_panel/data/reposity/driver/delivery_epository.dart';

class DriverBinding extends Bindings {
  @override
  void dependencies() {
    // Get.lazyPut(() => DriverInventoryController(), fenix: true);
    Get.put(DeliveryRepository());
    Get.put(DriverProfileController());
  }
}
