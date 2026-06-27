import 'package:get/get.dart';
import 'package:stors_admin_panel/features/features_authintication/models/store_financial_model.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class StoreFinancialController extends GetxController {
  static StoreFinancialController get instance => Get.find();

  RxBool isLoading = false.obs;
  Rx<StoreFinancialModel> financialData = StoreFinancialModel().obs;

  @override
  void onInit() {
    fetchFinancialData();
    super.onInit();
  }

  Future<void> fetchFinancialData() async {
    try {
      isLoading.value = true;
      // هنا نقوم بجلب البيانات من Firebase Firestore
      // مثال:
      // final data = await _repository.getStoreFinancials();
      // financialData.value = data;

      // بيانات تجريبية للفحص:
      financialData.value = StoreFinancialModel(
        commissionRate: 0.10, // 10%
        totalSales: 15000.0,
        totalRejected: 2000.0,
        totalAccepted: 13000.0,
        totalWithdrawn: 5000.0,
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'خطأ مالي', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
