import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hive/hive.dart';

// 1. لا تنسَ سطر الـ part لربط الملف التلقائي
part 'brand_model.g.dart';

@HiveType(typeId: 1) // 2. إعطاء الرقم 1 لهذا الموديل
class BrandModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String image;

  @HiveField(3)
  bool? isFeatured;

  @HiveField(4)
  int? productsCount;
  BrandModel({
    required this.id,
    required this.name,
    required this.image,
    this.isFeatured,
    this.productsCount,
  });

  static BrandModel empty() => BrandModel(id: "", name: "", image: "");

  toJson() {
    return {
      "Id": id,
      "Name": name,
      "Image": image,
      "IsFeatured": isFeatured,
      "ProductsCount": productsCount,
    };
  }

  factory BrandModel.fromJson(Map<String, dynamic> document) {
    final data = document;
    if (data.isEmpty) return BrandModel.empty();
    return BrandModel(
      id: data["Id"] ?? "",
      name: data["Name"] ?? "",
      image: data["Image"] ?? "",
      isFeatured: data["IsFeatured"] ?? false,
      productsCount: data["ProductsCount"] ?? 0,
    );
  }

  factory BrandModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (document.data() != null) {
      final data = document.data()!;
      return BrandModel(
        // id: document.id,
        id: data["Id"] ?? "",
        name: data["Name"] ?? "",
        image: data["Image"] ?? "",
        isFeatured: data["IsFeatured"] ?? false,
        productsCount: data["ProductsCount"] ?? 0,
      );
    } else {
      return BrandModel.empty();
    }
  }
}




















/*
class BrandModel {
  String id;
  String name;
  String image;
  bool? isFeatured;
  int? productsCount;

  BrandModel({
    required this.id,
    required this.name,
    required this.image,
    this.isFeatured,
    this.productsCount,
  });

  static BrandModel empty() => BrandModel(id: "", name: "", image: "");

  toJson() {
    return {
      "Id": id,
      "Name": name,
      "Image": image,
      "IsFeatured": isFeatured,
      "ProductsCount": productsCount,
    };
  }

  factory BrandModel.fromJson(Map<String, dynamic> document) {
    final data = document;
    if (data.isEmpty) return BrandModel.empty();
    return BrandModel(
      id: data["Id"] ?? "",
      name: data["Name"] ?? "",
      image: data["Image"] ?? "",
      isFeatured: data["IsFeatured"] ?? false,
      productsCount: data["ProductsCount"] ?? 0,
    );
  }

  factory BrandModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (document.data() != null) {
      final data = document.data()!;
      return BrandModel(
        // id: document.id,
        id: data["Id"] ?? "",
        name: data["Name"] ?? "",
        image: data["Image"] ?? "",
        isFeatured: data["IsFeatured"] ?? false,
        productsCount: data["ProductsCount"] ?? 0,
      );
    } else {
      return BrandModel.empty();
    }
  }
}
*/