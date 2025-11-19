import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_unit.freezed.dart';
part 'measurement_unit.g.dart';

@freezed
abstract class MeasurementUnit with _$MeasurementUnit {
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

extension MeasurementUnitX on MeasurementUnit {
  /// Compares business data fields (excluding id, timestamps, and synced status)
  bool hasDataChanges(MeasurementUnit other) {
    return name != other.name || acronym != other.acronym;
  }
}
