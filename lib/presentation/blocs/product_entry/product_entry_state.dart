import 'package:equatable/equatable.dart';
import '../../../domain/entities/product_entry.dart';

abstract class ProductEntryState extends Equatable {
  const ProductEntryState();

  @override
  List<Object> get props => [];
}

class ProductEntryInitial extends ProductEntryState {}

class ProductEntryLoading extends ProductEntryState {}

class ProductEntryLoaded extends ProductEntryState {
  final List<ProductEntry> productEntries;

  const ProductEntryLoaded(this.productEntries);

  @override
  List<Object> get props => [productEntries];
}

class ProductEntryPaginatedLoaded extends ProductEntryState {
  final List<ProductEntry> productEntries;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  const ProductEntryPaginatedLoaded({
    required this.productEntries,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });

  @override
  List<Object> get props => [productEntries, currentPage, totalPages, totalItems];
}

class ProductEntryError extends ProductEntryState {
  final String message;

  const ProductEntryError(this.message);

  @override
  List<Object> get props => [message];
}

class ProductEntryOperationSuccess extends ProductEntryState {
  final String message;

  const ProductEntryOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
