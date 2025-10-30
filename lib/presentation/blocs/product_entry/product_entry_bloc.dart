import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/product_entry_repository.dart';
import '../../../domain/repositories/product_repository.dart';
import 'product_entry_event.dart';
import 'product_entry_state.dart';

class ProductEntryBloc extends Bloc<ProductEntryEvent, ProductEntryState> {
  final ProductEntryRepository repository;
  final ProductRepository productRepository;

  ProductEntryBloc({
    required this.repository,
    required this.productRepository,
  }) : super(ProductEntryInitial()) {
    on<LoadProductEntries>(_onLoadProductEntries);
    on<LoadProductEntriesPaginated>(_onLoadProductEntriesPaginated);
    on<LoadProductEntriesByProductId>(_onLoadProductEntriesByProductId);
    on<SearchAndFilterProductEntries>(_onSearchAndFilterProductEntries);
    on<CreateProductEntry>(_onCreateProductEntry);
    on<UpdateProductEntry>(_onUpdateProductEntry);
    on<DeleteProductEntry>(_onDeleteProductEntry);
  }

  Future<void> _onLoadProductEntries(
    LoadProductEntries event,
    Emitter<ProductEntryState> emit,
  ) async {
    emit(ProductEntryLoading());
    final result = await repository.getAll();
    result.fold(
      (failure) => emit(ProductEntryError(failure.message)),
      (productEntries) => emit(ProductEntryLoaded(productEntries)),
    );
  }

  Future<void> _onLoadProductEntriesPaginated(
    LoadProductEntriesPaginated event,
    Emitter<ProductEntryState> emit,
  ) async {
    emit(ProductEntryLoading());
    final result = await repository.getPaginated(
      page: event.page,
      pageSize: event.pageSize,
    );
    result.fold(
      (failure) => emit(ProductEntryError(failure.message)),
      (paginatedResult) => emit(ProductEntryPaginatedLoaded(
        productEntries: paginatedResult.items,
        currentPage: paginatedResult.page,
        totalPages: paginatedResult.totalPages,
        totalItems: paginatedResult.totalCount,
      )),
    );
  }

  Future<void> _onLoadProductEntriesByProductId(
    LoadProductEntriesByProductId event,
    Emitter<ProductEntryState> emit,
  ) async {
    emit(ProductEntryLoading());
    final result = await repository.getByProductId(event.productId);
    result.fold(
      (failure) => emit(ProductEntryError(failure.message)),
      (productEntries) => emit(ProductEntryLoaded(productEntries)),
    );
  }

  Future<void> _onSearchAndFilterProductEntries(
    SearchAndFilterProductEntries event,
    Emitter<ProductEntryState> emit,
  ) async {
    emit(ProductEntryLoading());
    final result = await repository.getAll();
    result.fold(
      (failure) => emit(ProductEntryError(failure.message)),
      (productEntries) {
        var filteredEntries = productEntries;

        // Apply search query (by product name)
        if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
          final query = event.searchQuery!.toLowerCase();
          filteredEntries = filteredEntries.where((entry) {
            final productName = entry.product?.name.toLowerCase() ?? '';
            return productName.contains(query);
          }).toList();
        }

        // Apply product filter
        if (event.productIdFilter != null) {
          filteredEntries = filteredEntries
              .where((entry) => entry.productId == event.productIdFilter)
              .toList();
        }

        // Apply date range filter
        if (event.startDate != null) {
          filteredEntries = filteredEntries
              .where((entry) => entry.date.isAfter(event.startDate!) ||
                                 entry.date.isAtSameMomentAs(event.startDate!))
              .toList();
        }
        if (event.endDate != null) {
          // Set end date to end of day
          final endOfDay = DateTime(
            event.endDate!.year,
            event.endDate!.month,
            event.endDate!.day,
            23,
            59,
            59,
          );
          filteredEntries = filteredEntries
              .where((entry) => entry.date.isBefore(endOfDay) ||
                                 entry.date.isAtSameMomentAs(endOfDay))
              .toList();
        }

        // Apply quantity range filter
        if (event.minQuantity != null) {
          filteredEntries = filteredEntries
              .where((entry) => entry.quantity >= event.minQuantity!)
              .toList();
        }
        if (event.maxQuantity != null) {
          filteredEntries = filteredEntries
              .where((entry) => entry.quantity <= event.maxQuantity!)
              .toList();
        }

        emit(ProductEntryLoaded(filteredEntries));
      },
    );
  }

  Future<void> _onCreateProductEntry(
    CreateProductEntry event,
    Emitter<ProductEntryState> emit,
  ) async {
    final result = await repository.create(event.productEntry);
    await result.fold(
      (failure) async => emit(ProductEntryError(failure.message)),
      (productEntry) async {
        // Update product quantity: add the entry quantity
        final productResult = await productRepository.getById(productEntry.productId);
        await productResult.fold(
          (failure) async => emit(ProductEntryError('Failed to update product quantity')),
          (product) async {
            final updatedProduct = product.copyWith(
              quantity: product.quantity + productEntry.quantity,
            );
            await productRepository.update(updatedProduct);
            emit(const ProductEntryOperationSuccess('Product entry created successfully'));
            // Let the UI handle reload with pagination
          },
        );
      },
    );
  }

  Future<void> _onUpdateProductEntry(
    UpdateProductEntry event,
    Emitter<ProductEntryState> emit,
  ) async {
    final result = await repository.update(event.productEntry);
    await result.fold(
      (failure) async => emit(ProductEntryError(failure.message)),
      (productEntry) async {
        // Update product quantity: subtract old quantity, add new quantity
        final productResult = await productRepository.getById(productEntry.productId);
        await productResult.fold(
          (failure) async => emit(ProductEntryError('Failed to update product quantity')),
          (product) async {
            final quantityDifference = event.productEntry.quantity - event.oldProductEntry.quantity;
            final updatedProduct = product.copyWith(
              quantity: product.quantity + quantityDifference,
            );
            await productRepository.update(updatedProduct);
            emit(const ProductEntryOperationSuccess('Product entry updated successfully'));
            // Let the UI handle reload with pagination
          },
        );
      },
    );
  }

  Future<void> _onDeleteProductEntry(
    DeleteProductEntry event,
    Emitter<ProductEntryState> emit,
  ) async {
    final result = await repository.delete(event.id);
    await result.fold(
      (failure) async => emit(ProductEntryError(failure.message)),
      (_) async {
        // Update product quantity: subtract the entry quantity
        final productResult = await productRepository.getById(event.productEntry.productId);
        await productResult.fold(
          (failure) async => emit(ProductEntryError('Failed to update product quantity')),
          (product) async {
            final updatedProduct = product.copyWith(
              quantity: product.quantity - event.productEntry.quantity,
            );
            await productRepository.update(updatedProduct);
            emit(const ProductEntryOperationSuccess('Product entry deleted successfully'));
            // Let the UI handle reload with pagination
          },
        );
      },
    );
  }
}
