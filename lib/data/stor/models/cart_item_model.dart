import 'package:stors_admin_panel/utils/constants/enums.dart';

class CartItemModel {
  String productId;
  String storeId; // حقل معرف المتجر لتمكين تقسيم الطلب
  String title;
  double price;
  String? image;
  int quantity;
  ItemStatus itemStatus; // حالة العنصر (معلق، مقبول، مرفوض، إلخ)
  String variationId;
  Map<String, String>? selectedVariation;
  Map<String, dynamic>?
  productSnapshot; // نسخة كاملة من بيانات المنتج وقت الطلب
  String? mainOrderId;

  CartItemModel({
    required this.productId,
    required this.storeId,
    required this.quantity,
    this.itemStatus = ItemStatus.pending,
    this.variationId = "",
    this.image,
    this.price = 0.0,
    this.title = "",
    this.selectedVariation,
    this.productSnapshot,
  });

  /// مسميات الحقول الثابتة
  static String get getCartItemForLocalStorage => "CartItem";
  static String get getProductId => "productId";
  static String get getStoreId => "storeId";
  static String get getQuantity => "Quantity";
  static String get getItemStatus => "itemStatus";
  static String get getVariationId => "VariationId";
  static String get getImage => "Image";
  static String get getPrice => "price";
  static String get getTitle => "Title";
  static String get getSelectedVariation => "selectedVariation";
  static String get getProductSnapshot => "productSnapshot";

  /// كائن فارغ
  static CartItemModel empty() =>
      CartItemModel(productId: "", storeId: "", quantity: 0);

  /// تحويل الكائن إلى JSON لتخزينه في Firebase
  Map<String, dynamic> toJson() {
    return {
      getProductId: productId,
      getStoreId: storeId,
      getQuantity: quantity,
      getItemStatus: itemStatus.name, // تخزين اسم الحالة (pending, accepted...)
      getVariationId: variationId,
      getImage: image,
      getPrice: price,
      getTitle: title,
      getSelectedVariation: selectedVariation,
      getProductSnapshot: productSnapshot,
    };
  }

  /// إنشاء كائن من JSON القادم من Firebase
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json[getProductId] ?? '',
      storeId: json[getStoreId] ?? '',
      quantity: json[getQuantity] ?? 0,
      itemStatus: ItemStatus.values.firstWhere(
        (e) => e.name == (json[getItemStatus] ?? 'pending'),
        orElse: () => ItemStatus.pending,
      ),
      image: json[getImage],
      price: (json[getPrice] ?? 0.0).toDouble(),
      title: json[getTitle] ?? '',
      variationId: json[getVariationId] ?? '',
      selectedVariation: json[getSelectedVariation] != null
          ? Map<String, String>.from(json[getSelectedVariation])
          : null,
      productSnapshot: json[getProductSnapshot] != null
          ? Map<String, dynamic>.from(json[getProductSnapshot])
          : null,
    );
  }
}

















/*
class CartItemModel {
  String productId;
  String title;
  double price;
  String? image;
  int quantity;
  String variationId;
  String? brandName;
  Map<String, String>? selectedVariation;

  CartItemModel({
    required this.productId,
    required this.quantity,
    this.variationId = "",
    this.image,
    this.price = 0.0,
    this.title = "",
    this.brandName,
    this.selectedVariation,
  });

  static CartItemModel empty() => CartItemModel(productId: "", quantity: 0);

  static String get getCartItemForLocalStorage => "CartItem";

  static String get getProductId => "productId";
  static String get getQuantity => "Quantity";
  static String get getVariationId => "VariationId";
  static String get getImage => "Image";
  static String get getPrice => "price";
  static String get getTitle => "Title";
  static String get getBrandName => "BrandName";
  static String get getSelectedVariation => "selectedVariation";

  Map<String, dynamic> toJson() {
    return {
      getProductId: productId,
      getQuantity: quantity,
      getVariationId: variationId,
      getImage: image,
      getPrice: price,
      getTitle: title,
      getBrandName: brandName,
      getSelectedVariation: selectedVariation,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json[getProductId],
      quantity: json[getQuantity],
      brandName: json[getBrandName],
      image: json[getImage],
      price: json[getPrice]?.toDouble(),
      title: json[getTitle],
      variationId: json[getVariationId],
      selectedVariation: json[getSelectedVariation] != null
          ? Map<String, String>.from(json[getSelectedVariation])
          : null,
    );
  }
}
*/