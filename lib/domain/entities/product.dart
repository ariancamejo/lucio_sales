import 'package:freezed_annotation/freezed_annotation.dart';
import 'measurement_unit.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String userId,
    required String name,
    required double quantity,
    required String code,
    required double cost,
    required String measurementUnitId,
    required double price,
    required bool active,
    required DateTime createdAt,
    required DateTime updatedAt,
    MeasurementUnit? measurementUnit,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
