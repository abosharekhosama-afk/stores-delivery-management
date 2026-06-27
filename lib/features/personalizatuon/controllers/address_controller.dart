// address_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/utils/constants/address_data.dart';

class AddressController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  // قيم مختارة قابلة للمراقبة
  var selectedCity = "".obs;
  var selectedDistrict = "".obs;
  var selectedStreet = "".obs;

  TextEditingController buildingNumberController = TextEditingController();
  TextEditingController addressDetailsController = TextEditingController();
  TextEditingController postalCodeController = TextEditingController();

  // قوائم يتم تحديثها بناءً على الاختيار
  var districtsList = <String>[].obs;
  var streetsList = <String>[].obs;

  void onCityChanged(String? city) {
    if (city == null) return;
    selectedCity.value = city;
    selectedDistrict.value = "";
    selectedStreet.value = "";

    // جلب المناطق التابعة للمحافظة
    districtsList.assignAll(palestineAddressData[city]?.keys.toList() ?? []);
    streetsList.clear();
  }

  void onDistrictChanged(String? district) {
    if (district == null || selectedCity.isEmpty) return;
    selectedDistrict.value = district;
    selectedStreet.value = "";

    // جلب الشوارع/الأحياء التابعة للمنطقة
    streetsList.assignAll(
      palestineAddressData[selectedCity.value]?[district] ?? [],
    );
  }

  void onStreetChanged(String? street) {
    if (street != null) selectedStreet.value = street;
  }
}
