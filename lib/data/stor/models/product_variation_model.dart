import 'package:hive/hive.dart';

// 1. لا تنسَ سطر الـ part لربط الملف التلقائي
part 'product_variation_model.g.dart';

@HiveType(typeId: 3) // 2. إعطاء الرقم 3 لهذا الموديل
class ProductVariationModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String sku;

  @HiveField(2)
  String image;

  @HiveField(3)
  String? description;

  @HiveField(4)
  double price;

  @HiveField(5)
  double salePrice;

  @HiveField(6)
  int stock;

  @HiveField(7)
  Map<String, String> attributeValues;

  ProductVariationModel({
    required this.id,
    required this.attributeValues,
    this.sku = "",
    this.image = "",
    this.description = "",
    this.price = 0.0,
    this.salePrice = 0.0,
    this.stock = 0,
  });

  static ProductVariationModel empty() =>
      ProductVariationModel(id: "", attributeValues: {});

  toJson() {
    return {
      "Id": id,
      "Image": image,
      "Sku": sku,
      "Description": description,
      "Price": price,
      "SalePrice": salePrice,
      "Stock": stock,
      "AttributeValues": attributeValues,
    };
  }

  factory ProductVariationModel.fromJson(Map<String, dynamic> document) {
    final data = document;
    if (data.isEmpty) return ProductVariationModel.empty();
    return ProductVariationModel(
      id: data["Id"] ?? "",
      attributeValues: Map<String, String>.from(data["AttributeValues"]),
      description: data["Description"] ?? "",
      image: data["Image"] ?? "",
      price: double.parse((data["Price"] ?? 0.0).toString()),
      salePrice: double.parse((data["SalePrice"] ?? 0.0).toString()),
      sku: data["Sku"] ?? "",
      stock: data["Stock"] ?? 0,
    );
  }
}
