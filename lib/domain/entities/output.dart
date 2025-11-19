import 'package:freezed_annotation/freezed_annotation.dart';
import 'product.dart';
import 'measurement_unit.dart';
import 'output_type.dart';

part 'output.freezed.dart';
part 'output.g.dart';

@freezed
abstract class Output with _$Output {
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
    @Default(false) bool synced,
    Product? product,
    MeasurementUnit? measurementUnit,
    OutputType? outputType,
  }) = _Output;

  factory Output.fromJson(Map<String, dynamic> json) =>
      _$OutputFromJson(json);
}

extension OutputX on Output {
  /// Compares business data fields (excluding id, timestamps, and synced status)
  bool hasDataChanges(Output other) {
    return productId != other.productId ||
        quantity != other.quantity ||
        measurementUnitId != other.measurementUnitId ||
        totalAmount != other.totalAmount ||
        outputTypeId != other.outputTypeId ||
        date != other.date;
  }
}
