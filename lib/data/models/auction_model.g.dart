// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuctionModelAdapter extends TypeAdapter<AuctionModel> {
  @override
  final typeId = 1;

  @override
  AuctionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuctionModel(
      uuid: fields[0] as String,
      itemName: fields[1] as String,
      tier: fields[2] as String,
      category: fields[3] as String,
      bin: fields[4] as bool,
      startingBid: (fields[5] as num).toInt(),
      highestBid: (fields[6] as num).toInt(),
      end: (fields[7] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, AuctionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.tier)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.bin)
      ..writeByte(5)
      ..write(obj.startingBid)
      ..writeByte(6)
      ..write(obj.highestBid)
      ..writeByte(7)
      ..write(obj.end);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuctionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
