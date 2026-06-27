import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/data/reposity/store_reposity.dart';
import 'package:stors_admin_panel/features/features_authintication/models/address_model.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  final formKey = GlobalKey<FormState>();

  final _storeRepository = Get.put(StoreRepository()); // استدعاء المستودع
  // الـ Controllers للحقول
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final bankAccount = TextEditingController();
  final storeName = TextEditingController();
  final storeDescription = TextEditingController();
  final buildingNumber = TextEditingController();
  final postalCode = TextEditingController();
  final addressDetails = TextEditingController();

  // متغيرات العنوان (Observable)
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

  @override
  void onInit() {
    super.onInit();
    fetchStoreData(); // جلب البيانات فور تشغيل الصفحة
    loadAndBuildMap();
  }

  /// --- وظيفة العرض: جلب البيانات من Firestore ---
  Future<void> fetchStoreData() async {
    try {
      // افترضنا أننا نجلب بيانات المتجر الخاص بالمستخدم الحالي
      // يمكنك تمرير الـ ID المناسب هنا
      final store = await _storeRepository.getStoreById(
        AuthenticationRepository.instance.authUser!.uid,
      );

      if (store.storeId.isNotEmpty) {
        // تعبئة الحقول النصية
        storeName.text = store.storName;
        storeDescription.text = store.storeDescription;

        // تعبئة حقول العنوان (بناءً على المودل الخاص بك)
        if (store.addressModel != AddressModel.empty()) {
          onCityChanged(store.addressModel.city); // لتعبئة قائمة المناطق
          onDistrictChanged(
            store.addressModel.district,
          ); // لتعبئة قائمة الشوارع
          selectedStreet.value = store.addressModel.street;

          buildingNumber.text = store.addressModel.buildingNumber;
          postalCode.text = store.addressModel.postalCode;
          addressDetails.text = store.addressModel.address;
        }
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ في الجلب', message: e.toString());
    }
  }

  /// --- وظيفة التخزين: تحديث البيانات في Firestore ---
  Future<void> updateProfile() async {
    try {
      // 1. التحقق من صحة المدخلات
      if (!formKey.currentState!.validate()) return;

      // 2. تجميع البيانات في Map أو Object
      final Map<String, dynamic> updatedData = {
        'Name': storeName.text.trim(),
        'Description': storeDescription.text.trim(),
        'Address': {
          'city': selectedCity.value,
          'district': selectedDistrict.value,
          'street': selectedStreet.value,
          'buildingNumber': buildingNumber.text.trim(),
          'postalCode': postalCode.text.trim(),
          'address': addressDetails.text.trim(),
        },
        // أضف أي حقول أخرى هنا مثل الهاتف أو الحساب البنكي
      };

      // 3. إرسال البيانات للمستودع للتخزين
      await _storeRepository.updateStoreFields(
        AuthenticationRepository.instance.authUser!.uid,
        updatedData,
      );

      TLoaders.successSnackBar(
        title: 'تم الحفظ',
        message: 'تم تحديث بيانات المتجر بنجاح.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ في الحفظ', message: e.toString());
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
}
