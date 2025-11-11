import 'package:freezed_annotation/freezed_annotation.dart';

part 'output_type.freezed.dart';
part 'output_type.g.dart';

@freezed
class OutputType with _$OutputType {
  const OutputType._();

  const factory OutputType({
    required String id,
    required String userId,
    required String name,
    @Default(false) bool isDefault,
    @Default(true) bool isSale,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool synced,
  }) = _OutputType;

  factory OutputType.fromJson(Map<String, dynamic> json) =>
      _$OutputTypeFromJson(json);

  /// Compares business data fields (excluding id, timestamps, and synced status)
  /// Returns true if this output type has different data than the other output type
  bool hasDataChanges(OutputType other) {
    return name != other.name ||
        isDefault != other.isDefault ||
        isSale != other.isSale;
  }
}
