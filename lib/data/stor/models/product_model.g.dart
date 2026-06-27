// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 0;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as String,
      storId: fields[1] as String,
      title: fields[5] as String,
      stock: fields[2] as int,
      price: fields[4] as double,
      thumbnail: fields[8] as String,
      productType: fields[15] as String,
      sortId: fields[19] as int,
      sku: fields[3] as String?,
      brande: fields[10] as BrandModel?,
      date: fields[6] as DateTime?,
      images: (fields[13] as List?)?.cast<String>(),
      tags: (fields[14] as List?)?.cast<String>(),
      salePrice: fields[7] as double,
      isFeatured: fields[9] as bool?,
      categoryId: fields[12] as String?,
      description: fields[11] as String?,
      searchKeywords: (fields[20] as List?)?.cast<String>(),
      titleLowercase: fields[21] as String?,
      productAttribute: (fields[17] as List?)?.cast<ProductAttributeModel>(),
      productVariation: (fields[18] as List?)?.cast<ProductVariationModel>(),
      productVisibility: fields[16] as ProductVisibility,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.storId)
      ..writeByte(2)
      ..write(obj.stock)
      ..writeByte(3)
      ..write(obj.sku)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.salePrice)
      ..writeByte(8)
      ..write(obj.thumbnail)
      ..writeByte(9)
      ..write(obj.isFeatured)
      ..writeByte(10)
      ..write(obj.brande)
      ..writeByte(11)
      ..write(obj.description)
      ..writeByte(12)
      ..write(obj.categoryId)
      ..writeByte(13)
      ..write(obj.images)
      ..writeByte(14)
      ..write(obj.tags)
      ..writeByte(15)
      ..write(obj.productType)
      ..writeByte(16)
      ..write(obj.productVisibility)
      ..writeByte(17)
      ..write(obj.productAttribute)
      ..writeByte(18)
      ..write(obj.productVariation)
      ..writeByte(19)
      ..write(obj.sortId)
      ..writeByte(20)
      ..write(obj.searchKeywords)
      ..writeByte(21)
      ..write(obj.titleLowercase);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
