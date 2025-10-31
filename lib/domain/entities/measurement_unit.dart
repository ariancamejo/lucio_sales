import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_unit.freezed.dart';
part 'measurement_unit.g.dart';

@freezed
class MeasurementUnit with _$MeasurementUnit {
  const factory MeasurementUnit({
    required String id,
    required String userId,
    required String name,
    required String acronym,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool synced,
  }) = _MeasurementUnit;

  factory MeasurementUnit.fromJson(Map<String, dynamic> json) =>
      _$MeasurementUnitFromJson(json);
}
