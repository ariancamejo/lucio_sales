import 'package:freezed_annotation/freezed_annotation.dart';
import 'product.dart';

part 'product_entry.freezed.dart';
part 'product_entry.g.dart';

@freezed
class ProductEntry with _$ProductEntry {
  const factory ProductEntry({
    required String id,
    required String userId,
    required String productId,
    required double quantity,
    required DateTime date,
    String? notes,
    Product? product,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProductEntry;

  factory ProductEntry.fromJson(Map<String, dynamic> json) =>
      _$ProductEntryFromJson(json);
}
