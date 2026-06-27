import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/driver/delivery_epository.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/address_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class ReadyStoresController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  var isLoading = false.obs; // ابدأ بـ false لتجنب تعليق الواجهة
  var allReadyStores = <Map<String, dynamic>>[].obs;
  final repository = Get.put(DeliveryRepository());
  // --- البيانات الجغرافية المعتمدة ---
  // الخريطة المتداخلة النهائية
  RxMap<String, Map<String, Map<String, dynamic>>> addressData =
      <String, Map<String, Map<String, dynamic>>>{}.obs;

  // القائمة التي يتم عرضها في الواجهة (المفلترة)
  var filteredStores = <Map<String, dynamic>>[].obs;

  // متغيرات الفلترة والبحث
  RxString selectedCity = "غزة".obs; // المحافظة (Country في الموديل)
  RxString selectedDistrict = "الكل".obs; // المنطقة (City في الموديل)
  RxString searchQuery = "".obs;

  // 💡 الحل هنا: معالجة قائمة المدن داخل الكنترولر وحمايتها كـ Getter جاهز ومستقر للـ UI
  List<String> get currentDistrictCities {
    final currentGov = selectedCity.value;
    if (addressData.containsKey(currentGov)) {
      return ["الكل", ...addressData[currentGov]!.keys];
    }
    return ["الكل"];
  }

  @override
  void onInit() {
    debugPrint("START: ReadyStoresController initialized");
    loadAndBuildMap();
    super.onInit();
    fetchReadyStores();

    // 🌟 إضافة selectedDistrict هنا لكي تعمل الفلترة فور الضغط على التابات
    everAll([
      allReadyStores,
      selectedCity,
      selectedDistrict,
    ], (_) => filterStores());
  }

  // جلب البيانات وبناء الخريطة المتداخلة
  Future<void> loadAndBuildMap() async {
    try {
      isLoading.value = true;
      final data = await repository.fetchAllShippingData();

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
      addressData.value = tempMap;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ في التحميل', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchReadyStores() async {
    try {
      isLoading.value = true;
      debugPrint("FETCH: Starting stream from Firestore...");

      _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .where(
            StoreOrdersModel.getStatus,
            isEqualTo: OrderStatus.readyForPickup.name,
          )
          .snapshots()
          .listen(
            (snapshot) async {
              debugPrint("DATA: Received ${snapshot.docs.length} orders");

              Map<String, Map<String, dynamic>> storesMap = {};

              for (var doc in snapshot.docs) {
                try {
                  // فحص يدوي سريع للبيانات قبل تحويلها للموديل لتجنب الانهيار
                  final data = doc.data();
                  final String storeId =
                      data[StoreOrdersModel.getStoreId] ?? '';

                  if (storeId.isEmpty) continue;

                  if (storesMap.containsKey(storeId)) {
                    storesMap[storeId]!['ordersCount'] += 1;
                  } else {
                    // جلب بيانات المتجر
                    final storeDoc = await _db
                        .collection(StoreModel.getStoreCollectionName)
                        .doc(storeId)
                        .get();
                    if (storeDoc.exists) {
                      final sData = storeDoc.data()!;
                      storesMap[storeId] = {
                        StoreModel.getStoreId: storeId,
                        StoreModel.getStorName:
                            sData[StoreModel.getStorName] ?? 'بدون اسم',
                        StoreModel.getAddressModel:
                            sData[StoreModel.getAddressModel] ?? 'بدون عنوان',
                        "ordersCount": 1,
                      };
                    }
                  }
                } catch (innerError) {
                  debugPrint("ERROR in inner loop: $innerError");
                }
              }

              allReadyStores.assignAll(storesMap.values.toList());
              isLoading.value = false;
              debugPrint("SUCCESS: Displaying ${allReadyStores.length} stores");
            },
            onError: (err) {
              debugPrint("STREAM ERROR: $err");
              isLoading.value = false;
            },
          );
    } catch (e) {
      debugPrint("GLOBAL ERROR: $e");
      isLoading.value = false;
    }
  }

  // 🌟 تصحيح منطق الفلترة المزدوجة الذكية
  void filterStores() {
    var tempStores = allReadyStores.where((store) {
      if (store[StoreModel.getAddressModel] == null ||
          store[StoreModel.getAddressModel] == 'بدون عنوان') {
        return false;
      }

      final address = AddressModel.fromMap(store[StoreModel.getAddressModel]);
      print("cite :${address.city}");
      print("district :${address.district}");
      print("selectedCity :${selectedCity.value}");
      print("selectedDistrict :${selectedDistrict.value}");
      print("noumber of allReadyStores: ${allReadyStores.length}");
      // فلترة المحافظة (مثل: غزة، الشمال، الوسطى...)
      bool matchesGov =
          (selectedDistrict.value == "الكل") ||
          (address.district == selectedDistrict.value);

      // فلترة المدينة/المنطقة (التابات الأفقي) مع معالجة حالة "الكل" بشكل صحيح برمجياً
      bool matchesDistrict =
          (selectedCity.value == "الكل") ||
          (address.city == selectedCity.value);

      return matchesGov && matchesDistrict;
    }).toList();

    for (int i = 0; i < tempStores.length; i++) {
      print("order : ${tempStores[i]['ordersCount']}");
    }
    // ترتيب المتاجر حسب عدد الطلبات المجهزة (الأعلى أولاً)
    tempStores.sort((a, b) => b['ordersCount'].compareTo(a['ordersCount']));

    filteredStores.assignAll(tempStores);
    print("noumber of orders: ${filteredStores.length}");
  }

  void updateCity(String city) {
    selectedCity.value = city;
    selectedDistrict.value =
        "الكل"; // إعادة التابات للوضع الافتراضي عند تغيير المحافظة
  }

  void updateDistrict(String district) {
    selectedDistrict.value = district;
  }
}




/*
class ReadyStoresController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  var isLoading = false.obs; // ابدأ بـ false لتجنب تعليق الواجهة
  var allReadyStores = <Map<String, dynamic>>[].obs;

  // القائمة التي يتم عرضها في الواجهة (المفلترة)
  var filteredStores = <Map<String, dynamic>>[].obs;

  // المنطقة المختارة حالياً (Default: الكل)
  var selectedGov = "مدينة غزة".obs; // المحافظة المختارة
  var selectedCity = "الكل".obs; // المدينة/المنطقة المختارة

  @override
  void onInit() {
    debugPrint("START: ReadyStoresController initialized");
    super.onInit();
    fetchReadyStores();
    everAll([allReadyStores, selectedCity], (_) => filterStores());
  }

  Future<void> fetchReadyStores() async {
    try {
      isLoading.value = true;
      debugPrint("FETCH: Starting stream from Firestore...");

      _db
          .collection(StoreOrdersModel.getOrderCollectionName)
          .where(
            StoreOrdersModel.getStatus,
            isEqualTo: OrderStatus.readyForPickup.name,
          )
          .snapshots()
          .listen(
            (snapshot) async {
              debugPrint("DATA: Received ${snapshot.docs.length} orders");

              Map<String, Map<String, dynamic>> storesMap = {};

              for (var doc in snapshot.docs) {
                try {
                  // فحص يدوي سريع للبيانات قبل تحويلها للموديل لتجنب الانهيار
                  final data = doc.data();
                  final String storeId =
                      data[StoreOrdersModel.getStoreId] ?? '';

                  if (storeId.isEmpty) continue;

                  if (storesMap.containsKey(storeId)) {
                    storesMap[storeId]!['ordersCount'] += 1;
                  } else {
                    // جلب بيانات المتجر
                    final storeDoc = await _db
                        .collection(StoreModel.getStoreCollectionName)
                        .doc(storeId)
                        .get();
                    if (storeDoc.exists) {
                      final sData = storeDoc.data()!;
                      storesMap[storeId] = {
                        StoreModel.getStoreId: storeId,
                        StoreModel.getStorName:
                            sData[StoreModel.getStorName] ?? 'بدون اسم',
                        StoreModel.getAddressModel:
                            sData[StoreModel.getAddressModel] ?? 'بدون عنوان',
                        "ordersCount": 1,
                      };
                    }
                  }
                } catch (innerError) {
                  debugPrint("ERROR in inner loop: $innerError");
                }
              }

              allReadyStores.assignAll(storesMap.values.toList());
              isLoading.value = false;
              debugPrint("SUCCESS: Displaying ${allReadyStores.length} stores");
            },
            onError: (err) {
              debugPrint("STREAM ERROR: $err");
              isLoading.value = false;
            },
          );
    } catch (e) {
      debugPrint("GLOBAL ERROR: $e");
      isLoading.value = false;
    }
  }

  void filterStores() {
    var tempStores = allReadyStores.where((store) {
      final address = AddressModel.fromMap(store[StoreModel.getAddressModel]);

      // فلترة مزدوجة: حسب المحافظة وحسب المدينة (إذا لم تكن "الكل")
      bool matchesGov = address.city == selectedGov.value;
      bool matchesCity =
          (selectedCity.value == "الكل") ||
          (address.district == selectedCity.value);

      return matchesGov && matchesCity;
    }).toList();

    // ترتيب المتاجر حسب عدد الطلبات (الأكثر أولاً) لمساعدة المندوب
    tempStores.sort((a, b) => b['ordersCount'].compareTo(a['ordersCount']));

    filteredStores.assignAll(tempStores);
  }

  // دالة تحديث المحافظة
  void updateGovernorate(String gov) {
    selectedGov.value = gov;
    selectedCity.value = "الكل"; // تصفير المدينة عند تغيير المحافظة
    filterStores();
  }

  /*
  void filterStores() {
    if (selectedCity.value == "الكل") {
      filteredStores.assignAll(allReadyStores);
    } else {
      filteredStores.assignAll(
        allReadyStores.where((store) {
          final address = AddressModel.fromMap(
            store[StoreModel.getAddressModel],
          );
          // نفترض أن AddressModel يحتوي على حقل city أو district
          return address.city == selectedCity.value;
        }).toList(),
      );
    }
    filteredStores.sort((a, b) {
      final addrA = AddressModel.fromMap(a[StoreModel.getAddressModel]);
      final addrB = AddressModel.fromMap(b[StoreModel.getAddressModel]);
      return addrA.district.compareTo(addrB.district);
    });
  }
*/
}
*/

