import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/product_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc({required this.repository}) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadProductsPaginated>(_onLoadProductsPaginated);
    on<SearchAndFilterProducts>(_onSearchAndFilterProducts);
    on<SearchProductByCode>(_onSearchProductByCode);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await repository.getAll(includeInactive: event.includeInactive);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductLoaded(products)),
    );
  }

  Future<void> _onLoadProductsPaginated(
    LoadProductsPaginated event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await repository.getPaginated(
      page: event.page,
      pageSize: event.pageSize,
      includeInactive: event.includeInactive,
    );
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (paginatedResult) {
        // If current page is empty and not the first page, go to previous page
        if (paginatedResult.items.isEmpty && event.page > 1) {
          add(LoadProductsPaginated(page: event.page - 1, pageSize: event.pageSize, includeInactive: event.includeInactive));
        } else {
          emit(ProductPaginatedLoaded(
            products: paginatedResult.items,
            currentPage: paginatedResult.page,
            totalPages: paginatedResult.totalPages,
            totalItems: paginatedResult.totalCount,
            pageSize: event.pageSize,
          ));
        }
      },
    );
  }

  Future<void> _onSearchAndFilterProducts(
    SearchAndFilterProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await repository.getAll(includeInactive: true);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) {
        var filteredProducts = products;

        // Apply search query
        if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
          final query = event.searchQuery!.toLowerCase();
          filteredProducts = filteredProducts.where((product) {
            return product.name.toLowerCase().contains(query) ||
                product.code.toLowerCase().contains(query);
          }).toList();
        }

        // Apply active filter
        if (event.activeFilter != null) {
          filteredProducts = filteredProducts
              .where((product) => product.active == event.activeFilter)
              .toList();
        }

        // Apply price range filter
        if (event.minPrice != null) {
          filteredProducts = filteredProducts
              .where((product) => product.price >= event.minPrice!)
              .toList();
        }
        if (event.maxPrice != null) {
          filteredProducts = filteredProducts
              .where((product) => product.price <= event.maxPrice!)
              .toList();
        }

        // Apply quantity range filter
        if (event.minQuantity != null) {
          filteredProducts = filteredProducts
              .where((product) => product.quantity >= event.minQuantity!)
              .toList();
        }
        if (event.maxQuantity != null) {
          filteredProducts = filteredProducts
              .where((product) => product.quantity <= event.maxQuantity!)
              .toList();
        }

        // Apply cost range filter
        if (event.minCost != null) {
          filteredProducts = filteredProducts
              .where((product) => product.cost >= event.minCost!)
              .toList();
        }
        if (event.maxCost != null) {
          filteredProducts = filteredProducts
              .where((product) => product.cost <= event.maxCost!)
              .toList();
        }

        emit(ProductLoaded(filteredProducts));
      },
    );
  }

  Future<void> _onSearchProductByCode(
    SearchProductByCode event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await repository.getByCode(event.code);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductLoaded([product])),
    );
  }

  Future<void> _onCreateProduct(
    CreateProduct event,
    Emitter<ProductState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.create(event.product);
    result.fold(
      (failure) {
        emit(ProductError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is ProductPaginatedLoaded) {
          add(LoadProductsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is ProductLoaded) {
          add(const LoadProducts());
        }
      },
      (_) {
        emit(const ProductOperationSuccess('Product created successfully'));
        // Reload based on previous state
        if (previousState is ProductPaginatedLoaded) {
          add(LoadProductsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(const LoadProducts());
        }
      },
    );
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<ProductState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.update(event.product);
    result.fold(
      (failure) {
        emit(ProductError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is ProductPaginatedLoaded) {
          add(LoadProductsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is ProductLoaded) {
          add(const LoadProducts());
        }
      },
      (_) {
        emit(const ProductOperationSuccess('Product updated successfully'));
        // Reload based on previous state
        if (previousState is ProductPaginatedLoaded) {
          add(LoadProductsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(const LoadProducts());
        }
      },
    );
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.delete(event.id);
    result.fold(
      (failure) {
        emit(ProductError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is ProductPaginatedLoaded) {
          add(LoadProductsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is ProductLoaded) {
          add(const LoadProducts());
        }
      },
      (_) {
        emit(const ProductOperationSuccess('Product deleted successfully'));
        // Reload based on previous state
        if (previousState is ProductPaginatedLoaded) {
          add(LoadProductsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(const LoadProducts());
        }
      },
    );
  }
}
