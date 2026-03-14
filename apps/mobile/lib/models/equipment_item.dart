import 'package:freezed_annotation/freezed_annotation.dart';

part 'equipment_item.freezed.dart';
part 'equipment_item.g.dart';

@freezed
class EquipmentItem with _$EquipmentItem {
  const factory EquipmentItem({
    required String id,
    required String name,
    required String category,
  }) = _EquipmentItem;

  factory EquipmentItem.fromJson(Map<String, dynamic> json) =>
      _$EquipmentItemFromJson(json);
}
