import 'package:hive/hive.dart';

// 1. هذا السطر ضروري جداً لتوليد الملف التلقائي
part 'product_attribute_model.g.dart';

@HiveType(typeId: 2) // 2. إعطاء رقم فريد لهذا الكلاس
class ProductAttributeModel {
  @HiveField(0) // 3. ترقيم الحقول
  String? name;

  @HiveField(1)
  final List<String>? values;
  ProductAttributeModel({this.name, this.values});

  toJson() {
    return {"Name": name, "Values": values};
  }

  factory ProductAttributeModel.fromJson(Map<String, dynamic> document) {
    final data = document;
    if (data.isEmpty) return ProductAttributeModel();
    return ProductAttributeModel(
      name: data.containsKey("Name") ? data["Name"] : "",
      values: List<String>.from(data["Values"]),
    );
  }
}
