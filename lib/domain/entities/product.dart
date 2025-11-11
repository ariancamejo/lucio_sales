import 'package:freezed_annotation/freezed_annotation.dart';
import 'measurement_unit.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const Product._();

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
    @Default(false) bool synced,
    MeasurementUnit? measurementUnit,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  /// Compares business data fields (excluding id, timestamps, and synced status)
  /// Returns true if this product has different data than the other product
  bool hasDataChanges(Product other) {
    return name != other.name ||
        code != other.code ||
        quantity != other.quantity ||
        cost != other.cost ||
        price != other.price ||
        measurementUnitId != other.measurementUnitId ||
        active != other.active;
  }
}
