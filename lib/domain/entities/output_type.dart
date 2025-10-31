import 'package:freezed_annotation/freezed_annotation.dart';

part 'output_type.freezed.dart';
part 'output_type.g.dart';

@freezed
class OutputType with _$OutputType {
  const factory OutputType({
    required String id,
    required String userId,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool synced,
  }) = _OutputType;

  factory OutputType.fromJson(Map<String, dynamic> json) =>
      _$OutputTypeFromJson(json);
}
