import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/reposity/store_reposity.dart';
import 'package:stors_admin_panel/features/features_authintication/models/address_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class AddressControllerNew extends GetxController {
  static AddressControllerNew get instance => Get.find();

  final formKey = GlobalKey<FormState>();
  final _storeRepository = StoreRepository.instance;

  // قيم مختارة قابلة للمراقبة
  var selectedCity = "".obs;
  var selectedDistrict = "".obs;
  var selectedStreet = "".obs;
  var selectedMarks = "".obs;

  // قوائم يتم تحديثها بناءً على الاختيار
  var districtsList = <String>[].obs;
  var streetsList = <String>[].obs;
  var landmarksList = <String>[].obs; // قائمة المعالم

  RxMap<String, Map<String, Map<String, dynamic>>> palestineAddressData =
      <String, Map<String, Map<String, dynamic>>>{}.obs;

  final buildingNumber = TextEditingController();
  final postalCode = TextEditingController();
  final addressDetails = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchAddressData();
    loadAndBuildMap();
  }

  Future<void> fetchAddressData() async {
    try {
      final store = await _storeRepository.getStoreById(
        AuthenticationRepository.instance.authUser!.uid,
      );
      onCityChanged(store.addressModel.city);
      onDistrictChanged(store.addressModel.district);
      selectedStreet.value = store.addressModel.street;
      buildingNumber.text = store.addressModel.buildingNumber;
      postalCode.text = store.addressModel.postalCode;
      addressDetails.text = store.addressModel.address;
    } catch (e) {
      /* معالجة الخطأ */
    }
  }

  // جلب البيانات وبناء الخريطة المتداخلة
  Future<void> loadAndBuildMap() async {
    try {
      final data = await _storeRepository.fetchAllShippingData();

      Map<String, Map<String, Map<String, dynamic>>> tempMap = {};

      for (var item in data) {
        String gov = item['governorate'];
        String city = item['city'];
        String street = item['street'];

        tempMap.putIfAbsent(gov, () => {});
        tempMap[gov]!.putIfAbsent(city, () => {});
        tempMap[gov]![city]![street] = {
          "landmarks": List<String>.from(item['landmarks']),
          "fee": item['deliveryFee'],
        };
      }
      palestineAddressData.value = tempMap;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ في التحميل', message: e.toString());
    } finally {}
  }

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
    selectedMarks.value = "";

    // جلب مفاتيح الشوارع من الخريطة
    var streets =
        palestineAddressData[selectedCity.value]?[district]?.keys.toList() ??
        [];
    streetsList.assignAll(streets.cast<String>());

    landmarksList.clear(); // مسح المعالم عند تغيير المنطقة
  }

  void onStreetChanged(String? street) {
    if (street == null || selectedDistrict.isEmpty) return;
    selectedStreet.value = street;
    selectedMarks.value = "";

    // الوصول إلى قائمة المعالم داخل الخريطة
    var data =
        palestineAddressData[selectedCity.value]?[selectedDistrict
            .value]?[street];

    if (data != null && data['landmarks'] != null) {
      List<String> marks = List<String>.from(data['landmarks']);
      landmarksList.assignAll(marks);
    } else {
      landmarksList.clear();
    }
  }

  void onMarksChanged(String? mark) {
    if (mark != null) selectedMarks.value = mark;
  }

  Future<void> updateAddress() async {
    try {
      if (!formKey.currentState!.validate()) return;

      final Map<String, dynamic> addressJson = {
        StoreModel.getAddressModel: {
          AddressModel.getCity: selectedCity.value,
          AddressModel.getDistrict: selectedDistrict.value,
          AddressModel.getStreet: selectedStreet.value,
          AddressModel.getBuildingNumber: buildingNumber.text.trim(),
          AddressModel.getPostalCode: postalCode.text.trim(),
          AddressModel.getAddress: addressDetails.text.trim(),
        },
      };

      await _storeRepository.updateSingleField(
        AuthenticationRepository.instance.authUser!.uid,
        addressJson,
      );
      TLoaders.successSnackBar(
        title: 'تم بنجاح',
        message: 'تم تحديث العنوان بنجاح.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ', message: e.toString());
    }
  }
}
