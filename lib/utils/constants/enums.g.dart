// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductVisibilityAdapter extends TypeAdapter<ProductVisibility> {
  @override
  final int typeId = 4;

  @override
  ProductVisibility read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProductVisibility.published;
      case 1:
        return ProductVisibility.hidden;
      default:
        return ProductVisibility.published;
    }
  }

  @override
  void write(BinaryWriter writer, ProductVisibility obj) {
    switch (obj) {
      case ProductVisibility.published:
        writer.writeByte(0);
        break;
      case ProductVisibility.hidden:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductVisibilityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
