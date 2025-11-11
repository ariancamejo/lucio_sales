import 'package:freezed_annotation/freezed_annotation.dart';
import 'product.dart';

part 'product_entry.freezed.dart';
part 'product_entry.g.dart';

@freezed
class ProductEntry with _$ProductEntry {
  const ProductEntry._();

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
    @Default(false) bool synced,
  }) = _ProductEntry;

  factory ProductEntry.fromJson(Map<String, dynamic> json) =>
      _$ProductEntryFromJson(json);

  /// Compares business data fields (excluding id, timestamps, and synced status)
  /// Returns true if this product entry has different data than the other product entry
  bool hasDataChanges(ProductEntry other) {
    return productId != other.productId ||
        quantity != other.quantity ||
        date != other.date ||
        notes != other.notes;
  }
}
