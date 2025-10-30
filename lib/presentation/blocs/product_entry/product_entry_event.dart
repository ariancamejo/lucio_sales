import 'package:equatable/equatable.dart';
import '../../../domain/entities/product_entry.dart';

abstract class ProductEntryEvent extends Equatable {
  const ProductEntryEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductEntries extends ProductEntryEvent {}

class LoadProductEntriesPaginated extends ProductEntryEvent {
  final int page;
  final int pageSize;

  const LoadProductEntriesPaginated({
    required this.page,
    required this.pageSize,
  });

  @override
  List<Object?> get props => [page, pageSize];
}

class LoadProductEntriesByProductId extends ProductEntryEvent {
  final String productId;

  const LoadProductEntriesByProductId(this.productId);

  @override
  List<Object?> get props => [productId];
}

class CreateProductEntry extends ProductEntryEvent {
  final ProductEntry productEntry;

  const CreateProductEntry(this.productEntry);

  @override
  List<Object?> get props => [productEntry];
}

class UpdateProductEntry extends ProductEntryEvent {
  final ProductEntry productEntry;
  final ProductEntry oldProductEntry;

  const UpdateProductEntry(this.productEntry, this.oldProductEntry);

  @override
  List<Object?> get props => [productEntry, oldProductEntry];
}

class DeleteProductEntry extends ProductEntryEvent {
  final String id;
  final ProductEntry productEntry;

  const DeleteProductEntry(this.id, this.productEntry);

  @override
  List<Object?> get props => [id, productEntry];
}

class SearchAndFilterProductEntries extends ProductEntryEvent {
  final String? searchQuery; // Search by product name
  final String? productIdFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minQuantity;
  final double? maxQuantity;

  const SearchAndFilterProductEntries({
    this.searchQuery,
    this.productIdFilter,
    this.startDate,
    this.endDate,
    this.minQuantity,
    this.maxQuantity,
  });

  @override
  List<Object?> get props => [
        searchQuery,
        productIdFilter,
        startDate,
        endDate,
        minQuantity,
        maxQuantity,
      ];
}
