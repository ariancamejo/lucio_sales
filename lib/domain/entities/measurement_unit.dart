import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_unit.freezed.dart';
part 'measurement_unit.g.dart';

@freezed
class MeasurementUnit with _$MeasurementUnit {
  const MeasurementUnit._();

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

  /// Compares business data fields (excluding id, timestamps, and synced status)
  /// Returns true if this measurement unit has different data than the other measurement unit
  bool hasDataChanges(MeasurementUnit other) {
    return name != other.name ||
        acronym != other.acronym;
  }
}
