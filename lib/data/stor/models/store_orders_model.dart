import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stors_admin_panel/data/stor/models/cart_item_model.dart';
import 'package:stors_admin_panel/features/features_authintication/models/address_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';

class StoreOrdersModel {
  final String storeOrderId;
  final String mainOrderId;
  final String storeId;
  final List<CartItemModel> items;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? pickupDate;
  final AddressModel? userAddress;
  final String userId;
  final String pickupCode;
  final DeliveryStatus? deliveryStatus;
  final String? deliveryBoyId;

  StoreOrdersModel({
    required this.storeOrderId,
    required this.mainOrderId,
    required this.storeId,
    required this.items,
    required this.status,
    required this.orderDate,
    required this.pickupDate,
    required this.userAddress,
    required this.userId,
    required this.pickupCode,
    this.deliveryStatus,
    this.deliveryBoyId,
  });

  static String get getOrderCollectionName => "StoreOrders";
  static String get getMainOrderId => "MainOrderId";
  static String get getStoreId => "StoreId";
  static String get getItems => "Items";
  static String get getStatus => "Status";
  static String get getOrderDate => "OrderDate";
  static String get getPickupDate => "PickupDate";
  static String get getUserAddress => "UserAddress";
  static String get getUserId => "UserId";
  static String get getStoreOrderId => "StoreOrderId";
  static String get getPickupCode => "PickupCode";
  static String get getDeliveryStatus => "DeliveryStatus";
  static String get getDeliveryBoyId => "DeliveryBoyId";

  // --- التنسيق والعرض ---
  String get formattedOrderDate => THelperFunctions.getFormattedDate(orderDate);

  static StoreOrdersModel empty() {
    return StoreOrdersModel(
      storeOrderId: '',
      mainOrderId: '',
      storeId: '',
      items: [],
      status: OrderStatus.pending,
      orderDate: DateTime.now(),
      pickupDate: DateTime.now(),
      userAddress: null,
      userId: '',
      pickupCode: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      getStoreOrderId: storeOrderId,
      getUserId: userId,
      getMainOrderId: mainOrderId,
      getStatus: status.name,
      getOrderDate: orderDate,
      getPickupDate: pickupDate,
      getUserAddress: userAddress?.toJson(),
      getItems: items.map((item) => item.toJson()).toList(),
      getStoreId: storeId,
      getPickupCode: pickupCode,
      getDeliveryStatus: deliveryStatus?.name,
      getDeliveryBoyId: deliveryBoyId,
    };
  }

  factory StoreOrdersModel.fromJson(Map<String, dynamic> data) {
    return StoreOrdersModel(
      storeOrderId: data[getStoreOrderId] ?? "",
      mainOrderId: data[getMainOrderId] ?? "",
      userId: data[getUserId] ?? "",
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data[getStatus],
        orElse: () => OrderStatus.pending,
      ),
      // هنا نتعامل مع التاريخ كـ String لأنه مخزن في GetStorage بصيغة ISO
      orderDate: data[getOrderDate] != null
          ? DateTime.parse(data[getOrderDate])
          : DateTime.now(),

      pickupDate: data[getPickupDate] != null
          ? DateTime.parse(data[getPickupDate])
          : null,

      userAddress: data[getUserAddress] != null
          ? AddressModel.fromMap(data[getUserAddress])
          : null,

      items:
          (data[getItems] as List<dynamic>?)
              ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],

      storeId: data[getStoreId] ?? "",
      pickupCode: data[getPickupCode] ?? "",
      deliveryBoyId: data[getDeliveryBoyId],
    );
  }

  factory StoreOrdersModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return StoreOrdersModel(
      storeOrderId: snapshot.id,
      mainOrderId: data[getMainOrderId] as String,
      userId: data[getUserId] as String,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (data[getStatus] ?? OrderStatus.pending.name),
        orElse: () => OrderStatus.pending,
      ),
      orderDate: data[getOrderDate] != null
          ? (data[getOrderDate] as Timestamp).toDate()
          : DateTime.now(),

      pickupDate: data[getPickupDate] != null
          ? (data[getPickupDate] as Timestamp).toDate()
          : null,
      userAddress: data[getUserAddress] != null
          ? AddressModel.fromMap(data[getUserAddress])
          : null,
      items:
          (data[getItems] as List<dynamic>?)
              ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      storeId: data[getStoreId] ?? "",
      pickupCode: data[getPickupCode] ?? "",
      deliveryStatus: data[getDeliveryStatus] != null
          ? DeliveryStatus.values.firstWhere(
              (e) => e.name == data[getDeliveryStatus],
              orElse: () => DeliveryStatus.pickedUp,
            )
          : null,
      deliveryBoyId: data[getDeliveryBoyId],
    );
  }
}
