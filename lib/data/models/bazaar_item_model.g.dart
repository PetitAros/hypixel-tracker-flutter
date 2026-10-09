// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bazaar_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BazaarItemModelAdapter extends TypeAdapter<BazaarItemModel> {
  @override
  final typeId = 0;

  @override
  BazaarItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BazaarItemModel(
      productId: fields[0] as String,
      buyPrice: (fields[1] as num).toDouble(),
      sellPrice: (fields[2] as num).toDouble(),
      weekVolume: (fields[3] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, BazaarItemModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.buyPrice)
      ..writeByte(2)
      ..write(obj.sellPrice)
      ..writeByte(3)
      ..write(obj.weekVolume);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BazaarItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
