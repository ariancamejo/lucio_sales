import 'package:freezed_annotation/freezed_annotation.dart';
import 'measurement_unit.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
abstract class Product with _$Product {
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
    String? imageUrl,
    MeasurementUnit? measurementUnit,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

extension ProductX on Product {
  /// Compares business data fields (excluding id, timestamps, and synced status)
  bool hasDataChanges(Product other) {
    return name != other.name ||
        code != other.code ||
        quantity != other.quantity ||
        cost != other.cost ||
        price != other.price ||
        measurementUnitId != other.measurementUnitId ||
        active != other.active ||
        imageUrl != other.imageUrl;
  }
}
