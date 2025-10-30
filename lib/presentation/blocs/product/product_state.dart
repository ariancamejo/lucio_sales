import 'package:equatable/equatable.dart';
import '../../../domain/entities/product.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;

  const ProductLoaded(this.products);

  @override
  List<Object> get props => [products];
}

class ProductPaginatedLoaded extends ProductState {
  final List<Product> products;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  const ProductPaginatedLoaded({
    required this.products,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });

  @override
  List<Object> get props => [products, currentPage, totalPages, totalItems];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object> get props => [message];
}

class ProductOperationSuccess extends ProductState {
  final String message;

  const ProductOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
