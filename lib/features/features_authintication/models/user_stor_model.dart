import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stors_admin_panel/features/features_authintication/models/wallet_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/formatters/formatter.dart';
import 'package:stors_admin_panel/features/features_authintication/models/address_model.dart';

class StoreModel {
  final String storeId;
  String firstName;
  String lastName;
  final String storName;
  final String email;
  String phoneNumber;
  String banckAcountNumber;
  String profilePicture;
  String storeLogo;
  String storeBanner;
  String storeDescription;
  AddressModel addressModel;
  bool isOpen;
  Map<String, Map<String, dynamic>>? workingHours;
  StoreStatus storeStatus;
  bool isVerified;
  double commissionRate;
  double totalSales;
  double rating;
  DateTime? createdAt;
  DateTime? updatedAt;
  String fcmToken; // الحقل الجديد للإشعارات
  WalletModel? wallet;
  // --- حقول الإحصائيات الجديدة ---
  int totalOrders; // إجمالي عدد الطلبات الكلي
  int acceptedOrders; // عدد الطلبات التي تم قبولها
  int rejectedOrders; // عدد الطلبات التي تم رفضها
  int completedOrders; // عدد الطلبات التي تمت بنجاح
  double previousMonthSales; // مبيعات الشهر السابق (لحساب نسبة النمو)
  double currentMonthSales; // مبيعات الشهر الحالي

  StoreModel({
    required this.storeId,
    this.fcmToken = "", // قيمة افتراضية فارغة
    required this.firstName,
    required this.lastName,
    required this.storName,
    required this.banckAcountNumber,
    required this.storeLogo,
    required this.storeBanner,
    required this.storeDescription,
    required this.email,
    required this.phoneNumber,
    required this.profilePicture,
    required this.addressModel,
    required this.isOpen,
    required this.isVerified,
    required this.rating,
    required this.storeStatus,
    required this.workingHours,
    required this.commissionRate,
    required this.totalSales,
    required this.createdAt,
    required this.updatedAt,
    this.wallet,
    this.totalOrders = 0,
    this.acceptedOrders = 0,
    this.rejectedOrders = 0,
    this.completedOrders = 0,
    this.previousMonthSales = 0.0,
    this.currentMonthSales = 0.0,
  });

  static String get getStoreCollectionName => "Stores";
  static String get getStoreId => "storeId";
  static String get getFcmToken => "fcmToken";
  static String get getUpdatedAt => "updatedAt";
  static String get getCreatedAt => "createdAt";
  static String get getTotalSales => "totalSales";
  static String get getCommissionRate => "commissionRate";
  static String get getStoreStatus => "storeStatus";
  static String get getRating => "rating";
  static String get getIsVerified => "isVerified";
  static String get getIsOpen => "isOpen";
  static String get getBanckAcountNumber => "banckAcountNumber";
  static String get getAddressModel => "addressModel";
  static String get getProfilePicture => "profilePicture";
  static String get getPhoneNumber => "phoneNumber";
  static String get getStoreDescription => "storeDescription";
  static String get getStoreBanner => "storeBanner";
  static String get getStoreLogo => "storeLogo";
  static String get getStorName => "storName";
  static String get getEmail => "email";
  static String get getLastName => "lastName";
  static String get getFirstName => "firstName";
  static String get getWorkingHours => "workingHours";
  static String get getTotalOrders => "totalOrders";
  static String get getAcceptedOrders => "acceptedOrders";
  static String get getRejectedOrders => "rejectedOrders";
  static String get getCompletedOrders => "completedOrders";
  static String get getPreviousMonthSales => "previousWeekSales";
  static String get getCurrentMonthSales => "currentWeekSales";
  static String get getWallet => "wallet";

  String get fullName => "$firstName $lastName";

  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phoneNumber);

  String get fullAddress => addressModel.fullAddress;

  static List<String> nameParts(fullName) => fullName.split(" ");

  static String generateUsername(fullName) {
    List<String> nameParts = fullName.split(" ");
    String firstName = nameParts[0].toLowerCase();
    String lastName = nameParts.length > 1 ? nameParts[1].toLowerCase() : "";

    String cameCaseUserName = "$firstName$lastName";
    String userNameWithPrefix = "unt_$cameCaseUserName";
    return userNameWithPrefix;
  }

  // داخل كلاس StoreModel

  // 1. نسبة القبول
  double get acceptanceRate =>
      totalOrders == 0 ? 0 : (acceptedOrders / totalOrders) * 100;

  // 2. نسبة الرفض
  double get rejectionRate =>
      totalOrders == 0 ? 0 : (rejectedOrders / totalOrders) * 100;

  // 3. نسبة النمو (Growth Rate)
  // المعادلة: ((المبيعات الحالية - مبيعات الشهر السابق) / مبيعات الشهر السابق) * 100
  double get growthRate {
    if (previousMonthSales == 0) return currentMonthSales > 0 ? 100 : 0;
    return ((currentMonthSales - previousMonthSales) / previousMonthSales) *
        100;
  }

  static StoreModel empty() => StoreModel(
    storeId: "",
    firstName: "",
    lastName: "",
    storName: "",
    storeLogo: "",
    storeBanner: "",
    storeDescription: "",
    email: "",
    phoneNumber: "",
    banckAcountNumber: "",
    profilePicture: "",
    addressModel: AddressModel.empty(),
    isOpen: false,
    isVerified: false,
    rating: 0.0,
    storeStatus: StoreStatus.suspended,
    workingHours: null,
    commissionRate: 0.0,
    totalSales: 0.0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() {
    return {
      getStoreId: storeId,
      getFcmToken: fcmToken, // إضافة التوكن هنا
      getFirstName: firstName,
      getLastName: lastName,
      getStorName: storName,
      getEmail: email,
      getPhoneNumber: phoneNumber,
      getProfilePicture: profilePicture,
      getStoreLogo: storeLogo,
      getStoreBanner: storeBanner,
      getStoreDescription: storeDescription,
      getBanckAcountNumber: banckAcountNumber,
      getAddressModel: addressModel.toJson(),
      getIsOpen: isOpen,
      getWorkingHours: workingHours,
      getStoreStatus: storeStatus.name,
      getIsVerified: isVerified,
      getCommissionRate: commissionRate,
      getTotalSales: totalSales,
      getRating: rating,
      getCreatedAt: createdAt,
      getUpdatedAt: updatedAt,
    };
  }

  StoreModel copyWith({
    String? storeId,
    String? firstName,
    String? lastName,
    String? storName,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    String? storeLogo,
    String? storeBanner,
    String? storeDescription,
    String? banckAcountNumber,
    AddressModel? addressModel,
    bool? isOpen,
    Map<String, Map<String, dynamic>>? workingHours,
    StoreStatus? storeStatus,
    bool? isVerified,
    double? commissionRate,
    double? totalSales,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalOrders,
    int? acceptedOrders,
    int? rejectedOrders,
    int? completedOrders,
    double? previousMonthSales,
    double? currentMonthSales,
  }) {
    return StoreModel(
      storeId: storeId ?? this.storeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      storName: storName ?? this.storName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      storeLogo: storeLogo ?? this.storeLogo,
      storeBanner: storeBanner ?? this.storeBanner,
      storeDescription: storeDescription ?? this.storeDescription,
      banckAcountNumber: banckAcountNumber ?? this.banckAcountNumber,
      addressModel: addressModel ?? this.addressModel,
      isOpen: isOpen ?? this.isOpen,
      workingHours: workingHours ?? this.workingHours,
      storeStatus: storeStatus ?? this.storeStatus,
      isVerified: isVerified ?? this.isVerified,
      commissionRate: commissionRate ?? this.commissionRate,
      totalSales: totalSales ?? this.totalSales,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalOrders: totalOrders ?? this.totalOrders,
      acceptedOrders: acceptedOrders ?? this.acceptedOrders,
      rejectedOrders: rejectedOrders ?? this.rejectedOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      previousMonthSales: previousMonthSales ?? this.previousMonthSales,
      currentMonthSales: currentMonthSales ?? this.currentMonthSales,
    );
  }

  factory StoreModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (document.data() != null) {
      final data = document.data()!;
      return StoreModel(
        storeId: document.id,
        fcmToken: data[getFcmToken] ?? "", // قراءة التوكن هنا
        firstName: data[getFirstName] ?? "",
        lastName: data[getLastName] ?? "",
        storName: data[getStorName] ?? "",
        email: data[getEmail] ?? "",
        phoneNumber: data[getPhoneNumber] ?? "",
        profilePicture: data[getProfilePicture] ?? "",
        storeLogo: data[getStoreLogo] ?? "",
        storeBanner: data[getStoreBanner] ?? "",
        storeDescription: data[getStoreDescription] ?? "",
        banckAcountNumber: data[getBanckAcountNumber] ?? "",
        addressModel: AddressModel.fromMap(data[getAddressModel] ?? {}),
        isOpen: data[getIsOpen] ?? false,
        workingHours: data[getWorkingHours],
        storeStatus: StoreStatus.values.firstWhere(
          (e) => e.name == data[getStoreStatus],
          orElse: () => StoreStatus.suspended,
        ),
        isVerified: data[getIsVerified] ?? false,
        commissionRate: (data[getCommissionRate] ?? 0.0).toDouble(),
        totalSales: (data[getTotalSales] ?? 0.0).toDouble(),
        rating: (data[getRating] ?? 0.0).toDouble(),
        createdAt: data[getCreatedAt] != null
            ? (data[getCreatedAt] as Timestamp).toDate()
            : null,
        updatedAt: data[getUpdatedAt] != null
            ? (data[getUpdatedAt] as Timestamp).toDate()
            : null,
        totalOrders: (data[getTotalOrders] ?? 0.0).toInt(),
        acceptedOrders: (data[getAcceptedOrders] ?? 0.0).toInt(),
        completedOrders: (data[getCompletedOrders] ?? 0.0).toInt(),
        rejectedOrders: (data[getRejectedOrders] ?? 0.0).toInt(),
        currentMonthSales: (data[getCurrentMonthSales] ?? 0.0).toDouble(),
        previousMonthSales: (data[getPreviousMonthSales] ?? 0.0).toDouble(),
        wallet: WalletModel.fromMap(data[getWallet] ?? WalletModel()),
      );
    } else {
      return StoreModel.empty();
    }
  }
}
