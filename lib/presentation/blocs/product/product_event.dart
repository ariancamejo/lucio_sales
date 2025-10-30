import 'package:equatable/equatable.dart';
import '../../../domain/entities/product.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  final bool includeInactive;

  const LoadProducts({this.includeInactive = false});

  @override
  List<Object?> get props => [includeInactive];
}

class LoadProductsPaginated extends ProductEvent {
  final int page;
  final int pageSize;
  final bool includeInactive;

  const LoadProductsPaginated({
    required this.page,
    required this.pageSize,
    this.includeInactive = false,
  });

  @override
  List<Object?> get props => [page, pageSize, includeInactive];
}

class SearchAndFilterProducts extends ProductEvent {
  final String? searchQuery;
  final bool? activeFilter;
  final double? minPrice;
  final double? maxPrice;
  final double? minQuantity;
  final double? maxQuantity;
  final double? minCost;
  final double? maxCost;

  const SearchAndFilterProducts({
    this.searchQuery,
    this.activeFilter,
    this.minPrice,
    this.maxPrice,
    this.minQuantity,
    this.maxQuantity,
    this.minCost,
    this.maxCost,
  });

  @override
  List<Object?> get props => [
        searchQuery,
        activeFilter,
        minPrice,
        maxPrice,
        minQuantity,
        maxQuantity,
        minCost,
        maxCost,
      ];
}

class SearchProductByCode extends ProductEvent {
  final String code;

  const SearchProductByCode(this.code);

  @override
  List<Object?> get props => [code];
}

class CreateProduct extends ProductEvent {
  final Product product;

  const CreateProduct(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateProduct extends ProductEvent {
  final Product product;

  const UpdateProduct(this.product);

  @override
  List<Object?> get props => [product];
}

class DeleteProduct extends ProductEvent {
  final String id;

  const DeleteProduct(this.id);

  @override
  List<Object?> get props => [id];
}
