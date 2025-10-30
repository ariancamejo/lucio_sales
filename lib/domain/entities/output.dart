import 'package:freezed_annotation/freezed_annotation.dart';
import 'product.dart';
import 'measurement_unit.dart';
import 'output_type.dart';

part 'output.freezed.dart';
part 'output.g.dart';

@freezed
class Output with _$Output {
  const factory Output({
    required String id,
    required String userId,
    required String productId,
    required double quantity,
    required String measurementUnitId,
    required double totalAmount,
    required String outputTypeId,
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
    Product? product,
    MeasurementUnit? measurementUnit,
    OutputType? outputType,
  }) = _Output;

  factory Output.fromJson(Map<String, dynamic> json) =>
      _$OutputFromJson(json);
}
