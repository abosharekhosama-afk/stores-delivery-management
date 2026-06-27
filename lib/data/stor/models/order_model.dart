import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stors_admin_panel/data/stor/models/cart_item_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/address_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';

class OrderModel {
  final String id;
  final String userId;
  final OrderStatus status; // الحالة العامة (Processing, Shipped, etc.)
  final double
  rejectedAmount; // حقل جديد: إجمالي مبالغ العناصر المرفوضة (للإرجاع)
  final DateTime orderDate;
  final String paymentMethod;
  final AddressModel? address;
  final DateTime? deliveryDate;
  final List<CartItemModel> items;
  //final double itemsAmount; // تكلفة المنتجات فقط
  //final double shippingAmount; // تكلفة الشحن المحسوبة
  final double totalAmount; // المجموع الكلي (Items + Shipping)
  final String deliveryCode;
  final String? deliveryBoyId;

  OrderModel({
    required this.id,
    this.userId = "",
    required this.status,
    required this.totalAmount,
    this.rejectedAmount = 0.0, // القيمة الافتراضية صفر
    required this.orderDate,
    this.paymentMethod = "PayPal",
    this.address,
    this.deliveryDate,
    required this.items,
    // required this.itemsAmount,
    //required this.shippingAmount,
    required this.deliveryCode, // مطلوب عند إنشاء الطلب
    this.deliveryBoyId, // مطلوب عند إنشاء الطلب
  });

  // --- Getters للحسابات المنطقية ---

  // 1. حساب المبلغ الفعلي (الأصلي - المرفوض)
  double get actualAmount => totalAmount - rejectedAmount;

  // 2. جلب قائمة بمعرفات المتاجر الموجودة في هذا الطلب (بدون تكرار)
  List<String> get storeIds =>
      items.map((item) => item.storeId).toSet().toList();

  // 3. التحقق مما إذا كان هناك عناصر مرفوضة تحتاج استرداد مالي
  bool get needsRefund => rejectedAmount > 0;

  // 4. جلب العناصر الخاصة بمتجر معين فقط (لاستخدامه في تطبيق التاجر)
  List<CartItemModel> getItemsByStore(String storeId) {
    return items.where((item) => item.storeId == storeId).toList();
  }

  // --- مسميات الحقول لقاعدة البيانات ---
  static String get getOrderCollectionName => "Orders";
  static String get getId => "Id";
  static String get getUserId => "UserId";
  static String get getStatus => "Status";
  static String get getTotalAmount => "TotalAmount";
  static String get getRejectedAmount => "RejectedAmount"; // ثابت جديد
  static String get getOrderDate => "OrderDate";
  static String get getPaymentMethod => "PaymentMethod";
  static String get getAddress => "Address";
  static String get getDeliveryDate => "DeliveryDate";
  static String get getItems => "Items";
  //static String get getItemsAmount => "ItemsAmount";
  //static String get getShippingAmount => "ShippingAmount";
  static String get getDeliveryCode => "DeliveryCode";
  static String get getDeliveryBoyId => "DeliveryBoyId";

  // --- التنسيق والعرض ---
  String get formattedOrderDate => THelperFunctions.getFormattedDate(orderDate);

  String get orderStatusText {
    switch (status) {
      case OrderStatus.delivered:
        return "تم التسليم";
      case OrderStatus.shipped:
        return "في الطريق إليك";
      case OrderStatus.processing:
        return "قيد التجهيز";
      case OrderStatus.cancelled:
        return "ملغي";
      default:
        return "جاري المراجعة";
    }
  }

  Map<String, dynamic> toJson() {
    return {
      getId: id,
      getUserId: userId,
      getStatus: status.name,
      getTotalAmount: totalAmount,
      getRejectedAmount: rejectedAmount,
      getOrderDate: orderDate,
      getPaymentMethod: paymentMethod,
      getAddress: address?.toJson(),
      getDeliveryDate: deliveryDate,
      getItems: items.map((item) => item.toJson()).toList(),
      getDeliveryCode: deliveryCode, // حفظ الرمز
      getDeliveryBoyId: deliveryBoyId, // حفظ معرف طبيب التسليم
    };
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return OrderModel(
      id: data[getId] as String,
      userId: data[getUserId] as String,
      status: OrderStatus.values.firstWhere(
        (element) => element.name == data[getStatus],
      ),
      totalAmount: (data[getTotalAmount] ?? 0.0).toDouble(),
      rejectedAmount: (data[getRejectedAmount] ?? 0.0).toDouble(),
      orderDate: (data[getOrderDate] as Timestamp).toDate(),
      paymentMethod: data[getPaymentMethod] as String,
      address: data[getAddress] != null
          ? AddressModel.fromMap(data[getAddress])
          : null,
      deliveryDate: data[getDeliveryDate] == null
          ? null
          : (data[getDeliveryDate] as Timestamp).toDate(),
      items: (data[getItems] as List<dynamic>)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      //itemsAmount: (data[getItemsAmount] ?? 0.0).toDouble(),
      //shippingAmount: (data[getShippingAmount] ?? 0.0).toDouble(),
      deliveryCode: data[getDeliveryCode] ?? '', // استعادة الرمز
      deliveryBoyId: data[getDeliveryBoyId], // استعادة معرف طبيب التسليم
    );
  }

  // دالة مساعدة لإنشاء الطلب وحساب تكاليفه
  /*
  factory OrderModel.createNewOrder({
    required String id,
    required String userId,
    required List<CartItemModel> items,
    required AddressModelNew userAddress,
    required Map<String, AddressModelNew> storeAddresses,
  }) {
    String generatedCode = (100000 + (DateTime.now().millisecond % 900000))
        .toString();
    // حساب تكلفة المنتجات
    double itemsTotal = items.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    // حساب تكلفة الشحن باستخدام الخدمة الجديدة
    double shippingTotal = ShippingCalculatorService.calculateTotalShipping(
      items: items,
      userAddress: userAddress,
      storeAddresses: storeAddresses,
    );

    return OrderModel(
      id: id,
      userId: userId,
      status: OrderStatus.pending,
      itemsAmount: itemsTotal,
      shippingAmount: shippingTotal,
      totalAmount: itemsTotal + shippingTotal,
      orderDate: DateTime.now(),
      items: items,
      address: userAddress,
      deliveryCode: generatedCode, // الرمز هنا
    );
  }
*/
}















/*
class OrderModel {
  final String id;
  final String userId;
  final OrderStatus status;
  final double totalAmount;
  final DateTime orderDate;
  final String paymentMethod;
  final AddressModel? address;
  final DateTime? deliveryDate;
  final List<CartItemModel> items;

  OrderModel({
    required this.id,
    this.userId = "",
    required this.status,
    required this.totalAmount,
    required this.orderDate,
    this.paymentMethod = "PayPal",
    this.address,
    this.deliveryDate,
    required this.items,
  });

  static String get getOrderCollectionName => "Orders";
  static String get getId => "Id";
  static String get getUserId => "UserId";
  static String get getStatus => "Status";
  static String get getTotalAmount => "TotalAmount";
  static String get getOrderDate => "OrderDate";
  static String get getPaymentMethod => "PaymentMethod";
  static String get getAddress => "Address";
  static String get getDeliveryDate => "DeliveryDate";
  static String get getItems => "Items";

  String get formattedOrderDate => THelperFunctions.getFormattedDate(orderDate);
  String get formattedDeilveryDate =>
      deliveryDate != null ? THelperFunctions.getFormattedDate(orderDate) : "";

  String get orderStatusText => status == OrderStatus.delivered
      ? "Delivered"
      : status == OrderStatus.shipped
      ? "Shipment on the way"
      : "Processing";

  Map<String, dynamic> toJson() {
    return {
      getId: id,
      getUserId: userId,
      getStatus: status.toString(),
      getTotalAmount: totalAmount,
      getOrderDate: orderDate,
      getPaymentMethod: paymentMethod,
      getAddress: address?.toJson(),
      getDeliveryDate: deliveryDate,
      getItems: items.map((item) => item.toJson()).toList(),
    };
  }

  factory OrderModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return OrderModel(
      id: data[getId] as String,
      userId: data[getUserId] as String,
      status: OrderStatus.values.firstWhere(
        (element) => element.toString() == data[getStatus],
      ),
      totalAmount: data[getTotalAmount] as double,
      orderDate: (data[getOrderDate] as Timestamp).toDate(),
      paymentMethod: data[getPaymentMethod] as String,
      address: AddressModel.fromMap(data[getAddress] as Map<String, dynamic>),
      deliveryDate: data[getDeliveryDate] == null
          ? null
          : (data[getDeliveryDate] as Timestamp).toDate(),
      items: (data[getItems] as List<dynamic>)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
*/