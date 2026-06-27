import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stors_admin_panel/data/reposity/repositories.authentication/authentication_repository.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class WalletController extends GetxController {
  static WalletController get instance => Get.find();
  final String storeId = AuthenticationRepository
      .instance
      .authUser!
      .uid; // يفضل جلبه من AuthController
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- متغيرات الترقيم والوضع الاقتصادي ---
  // RxList<DocumentSnapshot> transactions = <DocumentSnapshot>[].obs;
  RxBool isLoading = false.obs; // للتحميل أول مرة
  RxBool isMoreLoading = false.obs; // لتحميل الصفحات الإضافية في الأسفل
  RxBool hasMore = true.obs; // هل يوجد المزيد من العمليات؟
  DocumentSnapshot? lastDocument;

  final int initialLimit = 15; // الدفعة الأولى
  final int moreLimit = 10; // الدفعات التالية
  var selectedFilter = "الكل".obs;
  // اتجاه التمرير لمنع أنيميشن الصعود
  var isScrollingDown = true.obs;
  // --- القوائم الأساسية المخزنة كاش في الذاكرة (المصدر الحقيقي للبيانات) ---
  final List<DocumentSnapshot> _allTransactionsCache = [];
  final List<DocumentSnapshot> _allWithdrawalsCache = [];

  // --- القائمة التفاعلية المعروضة في الواجهة بناءً على الفلتر الحالي ---
  RxList<DocumentSnapshot> displayTransactions = <DocumentSnapshot>[].obs;

  RxBool hasMoreTransactions = true.obs;
  RxBool hasMoreWithdrawals = true.obs;

  DocumentSnapshot? lastTransactionDoc;
  DocumentSnapshot? lastWithdrawalDoc;

  @override
  void onInit() {
    super.onInit();
    _applyLocalFilter();
    fetchInitialData(); // جلب أول 15 عملية عند فتح الواجهة
  }

  /// الدالة الرئيسية لجلب البيانات لأول مرة بناءً على الكولكشن الأساسي
  Future<void> fetchInitialData() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      if (selectedFilter.value == "السحوبات") {
        // جلب الدفعة الأولى من كولكشن السحوبات المنفصل
        _allWithdrawalsCache.clear();
        lastWithdrawalDoc = null;
        hasMoreWithdrawals.value = true;

        final querySnapshot = await _db
            .collection('Withdrawals')
            .where('storeId', isEqualTo: storeId)
            .orderBy('createdAt', descending: true)
            .limit(initialLimit)
            .get();

        if (querySnapshot.docs.length < initialLimit)
          hasMoreWithdrawals.value = false;

        if (querySnapshot.docs.isNotEmpty) {
          lastWithdrawalDoc = querySnapshot.docs.last;
          _allWithdrawalsCache.addAll(querySnapshot.docs);
        }
      } else {
        // جلب الدفعة الأولى من كولكشن العمليات الرئيسي الشامل (يخدم الكل، الإيرادات، المسترجعات)
        _allTransactionsCache.clear();
        lastTransactionDoc = null;
        hasMoreTransactions.value = true;

        final querySnapshot = await _db
            .collection('Transactions')
            .where('storeId', isEqualTo: storeId)
            .orderBy('createdAt', descending: true)
            .limit(initialLimit)
            .get();

        if (querySnapshot.docs.length < initialLimit)
          hasMoreTransactions.value = false;

        if (querySnapshot.docs.isNotEmpty) {
          lastTransactionDoc = querySnapshot.docs.last;
          _allTransactionsCache.addAll(querySnapshot.docs);
        }
      }

      // تطبيق التحديث الفوري على الواجهة
      _applyLocalFilter();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "خطأ",
        message: "فشل جلب البيانات المالية: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// جلب المزيد من البيانات عند النزول لأسفل (توسيع الكاش)
  Future<void> fetchMoreData() async {
    if (isLoading.value || isMoreLoading.value) return;

    // التحقق من صلاحية جلب المزيد بناءً على التبويب الحالي
    bool isWithdrawal = selectedFilter.value == "السحوبات";
    if (isWithdrawal &&
        (!hasMoreWithdrawals.value || lastWithdrawalDoc == null))
      return;
    if (!isWithdrawal &&
        (!hasMoreTransactions.value || lastTransactionDoc == null))
      return;

    isMoreLoading.value = true;
    try {
      if (isWithdrawal) {
        final querySnapshot = await _db
            .collection('Withdrawals')
            .where('storeId', isEqualTo: storeId)
            .orderBy('createdAt', descending: true)
            .startAfterDocument(lastWithdrawalDoc!)
            .limit(moreLimit)
            .get();

        if (querySnapshot.docs.length < moreLimit) {
          hasMoreWithdrawals.value = false;
        }

        if (querySnapshot.docs.isNotEmpty) {
          lastWithdrawalDoc = querySnapshot.docs.last;
          _allWithdrawalsCache.addAll(querySnapshot.docs);
        }
      } else {
        final querySnapshot = await _db
            .collection('Transactions')
            .where('storeId', isEqualTo: storeId)
            .orderBy('createdAt', descending: true)
            .startAfterDocument(lastTransactionDoc!)
            .limit(moreLimit)
            .get();

        if (querySnapshot.docs.length < moreLimit) {
          hasMoreTransactions.value = false;
        }

        if (querySnapshot.docs.isNotEmpty) {
          lastTransactionDoc = querySnapshot.docs.last;
          _allTransactionsCache.addAll(querySnapshot.docs);
        }
      }

      // إعادة تطبيق الفلترة المحلية لتشمل البيانات الجديدة المقروءة حديثاً
      _applyLocalFilter();
    } catch (e) {
      print("Error fetching more data: $e");
    } finally {
      isMoreLoading.value = false;
    }
  }

  /// 🌟 الفلترة المحلية التلقائية (0 تكلفة قراءة إضافية لـ Firestore)
  void _applyLocalFilter() {
    switch (selectedFilter.value) {
      case "الكل":
        displayTransactions.assignAll(_allTransactionsCache);
        break;
      case "order_revenue":
        // تصفية محلية في الذاكرة لعمليات المبيعات فقط
        displayTransactions.assignAll(
          _allTransactionsCache.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data != null && data['type'] == 'order_revenue';
          }).toList(),
        );
        break;
      case "refund":
        // تصفية محلية في الذاكرة للمرتجعات فقط
        displayTransactions.assignAll(
          _allTransactionsCache.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data != null && data['type'] == 'refund';
          }).toList(),
        );
        break;
      case "السحوبات":
        displayTransactions.assignAll(_allWithdrawalsCache);
        break;
    }
  }

  /// دالة تغيير الفلتر من شريط الخيارات العليا
  void changeFilter(String newFilter) {
    if (selectedFilter.value == newFilter) return;

    selectedFilter.value = newFilter;

    // إذا تم التحول إلى السحوبات وكانت الكاش فارغة، أو تحولنا للعمليات والأخرى فارغة، ننفذ جلب فعلي
    if ((newFilter == "السحوبات" && _allWithdrawalsCache.isEmpty) ||
        (newFilter != "السحوبات" && _allTransactionsCache.isEmpty)) {
      fetchInitialData();
    } else {
      // 🌟 تصفية فورية فائقة السرعة بدون تحميل أو استهلاك شبكة
      _applyLocalFilter();
    }
  }

  // ميزة التأكد من توفر الملحقات المتبقية للصفحة (pagination indicator check)
  bool get hasMoreToShow => selectedFilter.value == "السحوبات"
      ? hasMoreWithdrawals.value
      : hasMoreTransactions.value;

  Future<void> requestWithdrawal(double amount) async {
    try {
      await _db.collection('Withdrawals').add({
        'storeId': storeId,
        'amount': amount,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      Get.back();
      TLoaders.successSnackBar(
        title: "نجاح",
        message: "تم إرسال طلب السحب بنجاح",
      );

      // إنعاش تبويب السحوبات تلقائياً
      if (selectedFilter.value == "السحوبات") fetchInitialData();
    } catch (e) {
      TLoaders.errorSnackBar(title: "خطأ", message: "فشل إرسال الطلب: $e");
    }
  }

  /// دالة ديناميكية لتحديد الكولكشن وبناء الاستعلام الصحيح
  Query _buildQuery() {
    if (selectedFilter.value == "الكل") {
      // كولكشن العمليات الشاملة (الأرباح والمبيعات)
      return _db
          .collection('Transactions')
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true);
    } else {
      // كولكشن طلبات السحب المنفصل
      return _db
          .collection('Withdrawals')
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true);
    }
  }

  /// دالة تغيير الفلتر وإعادة تهيئة المؤشرات
  /*
  void changeFilter(String newFilter) {
    if (selectedFilter.value == newFilter) return;

    selectedFilter.value = newFilter;
    lastDocument = null;
    hasMore.value = true;
    transactions.clear();

    fetchData(); // جلب الدفعة الأولى للفلتر الجديد
  }
*/
  /// جلب الدفعة الأولى (15 عنصر)
  /*
  Future<void> fetchData() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      Query query = _buildQuery().limit(initialLimit);

      final querySnapshot = await query.get();

      if (querySnapshot.docs.length < initialLimit) {
        hasMore.value = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        lastDocument = querySnapshot.docs.last;
        transactions.assignAll(querySnapshot.docs);
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: "خطأ", message: "فشل جلب البيانات: $e");
    } finally {
      isLoading.value = false;
    }
  }
*/
  /// جلب الدفعات الإضافية عند التمرير لأسفل (10 عناصر)
  /*
  Future<void> fetchMoreData() async {
    if (isLoading.value ||
        isMoreLoading.value ||
        !hasMore.value ||
        lastDocument == null)
      return;

    isMoreLoading.value = true;
    try {
      Query query = _buildQuery()
          .startAfterDocument(lastDocument!)
          .limit(moreLimit);

      final querySnapshot = await query.get();

      if (querySnapshot.docs.length < moreLimit) {
        hasMore.value = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        lastDocument = querySnapshot.docs.last;
        transactions.addAll(querySnapshot.docs);
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isMoreLoading.value = false;
    }
  }
*/
  // بث مباشر للمحفظة (وثيقة واحدة - اقتصادي وآمن)
  Stream<StoreModel> getWalletStream() {
    return _db.collection('Stores').doc(storeId).snapshots().map((snapshot) {
      return StoreModel.fromSnapshot(snapshot);
    });
  }

  // --- دالة جلب الدفعة الأولى (15 عملية) ---
  /*
  Future<void> fetchInitialTransactions() async {
    if (isLoading.value) return;

    isLoading.value = true;
    hasMore.value = true;
    lastDocument = null;
    transactions.clear();

    try {
      final querySnapshot = await _db
          .collection('Transactions')
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true)
          .limit(initialLimit)
          .get();

      if (querySnapshot.docs.length < initialLimit) {
        hasMore.value = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        lastDocument = querySnapshot.docs.last;
        transactions.assignAll(querySnapshot.docs);
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: "خطأ", message: "فشل جلب العمليات: $e");
    } finally {
      isLoading.value = false;
    }
  }
*/
  // --- دالة جلب الدفعات الإضافية عند التمرير (10 عمليات) ---
  /*
  Future<void> fetchMoreTransactions() async {
    // التحقق من الشروط لمنع طلبات مكررة متداخلة تعطل السيرفر
    if (isLoading.value ||
        isMoreLoading.value ||
        !hasMore.value ||
        lastDocument == null)
      return;

    isMoreLoading.value = true;
    try {
      final querySnapshot = await _db
          .collection('Transactions')
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastDocument!)
          .limit(moreLimit)
          .get();

      if (querySnapshot.docs.length < moreLimit) {
        hasMore.value = false; // وصلنا لنهاية البيانات
      }

      if (querySnapshot.docs.isNotEmpty) {
        lastDocument = querySnapshot.docs.last;
        transactions.addAll(
          querySnapshot.docs,
        ); // إضافة العمليات الجديدة للقائمة الحالية
      }
    } catch (e) {
      print("Error fetching more transactions: $e");
    } finally {
      isMoreLoading.value = false;
    }
  }
*/
  // وظيفة طلب سحب الرصيد
  /*
  Future<void> requestWithdrawal(double amount) async {
    try {
      await _db.collection('Transactions').add({
        'storeId': storeId,
        'amount': -amount,
        'type': 'withdrawal',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      Get.back();
      TLoaders.successSnackBar(
        title: "نجاح",
        message: "تم إرسال طلب السحب بنجاح",
      );

      // إعادة إنعاش القائمة الاقتصادية لتظهر الحركة الجديدة في الأعلى فوراً
      fetchInitialTransactions();
    } catch (e) {
      TLoaders.errorSnackBar(title: "خطأ", message: "فشل إرسال الطلب: $e");
    }
  }
*/
  // بث مباشر لبيانات المحفظة
  /*
  Stream<StoreModel> getWalletStream() {
    return _db.collection('Stores').doc(storeId).snapshots().map((snapshot) {
      return StoreModel.fromSnapshot(snapshot);
    });
  }
*/
  // بث مباشر لبيانات المتجر بالكامل (بما فيها الإحصائيات)
  Stream<StoreModel> getStoreDataStream() {
    return _db.collection('Stores').doc(storeId).snapshots().map((snapshot) {
      return StoreModel.fromSnapshot(snapshot);
    });
  }

  // بث مباشر للحركات المالية
  Stream<QuerySnapshot> getTransactionsStream() {
    return _db
        .collection('Transactions')
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // وظيفة طلب سحب الرصيد
  /*
  Future<void> requestWithdrawal(double amount) async {
    try {
      await _db.collection('Transactions').add({
        'storeId': storeId,
        'amount': -amount, // قيمة سالبة لأنها سحب
        'type': 'withdrawal',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      Get.back();
      TLoaders.successSnackBar(
        title: "نجاح",
        message: "تم إرسال طلب السحب بنجاح",
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: "خطأ", message: "فشل إرسال الطلب: $e");
    }
  }
*/
  double calculateGrowthPercentage(
    double currentMonthSales,
    double lastMonthSales,
  ) {
    if (lastMonthSales == 0) return currentMonthSales > 0 ? 100.0 : 0.0;

    double growth =
        ((currentMonthSales - lastMonthSales) / lastMonthSales) * 100;
    return double.parse(growth.toStringAsFixed(1)); // تقريب لرقم عشري واحد
  }

  // حساب نسبة النمو المئوية
  double calculateGrowth(double current, double previous) {
    if (previous <= 0) return current > 0 ? 100.0 : 0.0;
    double growth = ((current - previous) / previous) * 100;
    return double.parse(growth.toStringAsFixed(1));
  }
}
