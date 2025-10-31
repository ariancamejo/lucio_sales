import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/output_repository.dart';
import 'output_event.dart';
import 'output_state.dart';

class OutputBloc extends Bloc<OutputEvent, OutputState> {
  final OutputRepository repository;

  OutputBloc({required this.repository}) : super(OutputInitial()) {
    on<LoadOutputs>(_onLoadOutputs);
    on<LoadOutputsPaginated>(_onLoadOutputsPaginated);
    on<LoadOutputsByDateRange>(_onLoadOutputsByDateRange);
    on<LoadOutputsByType>(_onLoadOutputsByType);
    on<SearchAndFilterOutputs>(_onSearchAndFilterOutputs);
    on<CreateOutput>(_onCreateOutput);
    on<UpdateOutput>(_onUpdateOutput);
    on<DeleteOutput>(_onDeleteOutput);
    on<LoadSalesByDay>(_onLoadSalesByDay);
    on<LoadSalesByMonth>(_onLoadSalesByMonth);
    on<LoadSalesByYear>(_onLoadSalesByYear);
    on<LoadIPVReport>(_onLoadIPVReport);
  }

  Future<void> _onLoadOutputs(
    LoadOutputs event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getAll();
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (outputs) => emit(OutputLoaded(outputs)),
    );
  }

  Future<void> _onLoadOutputsPaginated(
    LoadOutputsPaginated event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getPaginated(
      page: event.page,
      pageSize: event.pageSize,
    );
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (paginatedResult) {
        // If current page is empty and not the first page, go to previous page
        if (paginatedResult.items.isEmpty && event.page > 1) {
          add(LoadOutputsPaginated(page: event.page - 1, pageSize: event.pageSize));
        } else {
          emit(OutputPaginatedLoaded(
            outputs: paginatedResult.items,
            currentPage: paginatedResult.page,
            totalPages: paginatedResult.totalPages,
            totalItems: paginatedResult.totalCount,
            pageSize: event.pageSize,
          ));
        }
      },
    );
  }

  Future<void> _onLoadOutputsByDateRange(
    LoadOutputsByDateRange event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getByDateRange(event.startDate, event.endDate);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (outputs) => emit(OutputLoaded(outputs)),
    );
  }

  Future<void> _onLoadOutputsByType(
    LoadOutputsByType event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getByType(event.outputTypeId);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (outputs) => emit(OutputLoaded(outputs)),
    );
  }

  Future<void> _onSearchAndFilterOutputs(
    SearchAndFilterOutputs event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getAll();
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (outputs) {
        var filteredOutputs = outputs;

        // Apply search query (by product name)
        if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
          final query = event.searchQuery!.toLowerCase();
          filteredOutputs = filteredOutputs.where((output) {
            final productName = output.product?.name.toLowerCase() ?? '';
            return productName.contains(query);
          }).toList();
        }

        // Apply date range filter
        if (event.startDate != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.date.isAfter(event.startDate!) ||
                                 output.date.isAtSameMomentAs(event.startDate!))
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
          filteredOutputs = filteredOutputs
              .where((output) => output.date.isBefore(endOfDay) ||
                                 output.date.isAtSameMomentAs(endOfDay))
              .toList();
        }

        // Apply output type filter
        if (event.outputTypeId != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.outputTypeId == event.outputTypeId)
              .toList();
        }

        // Apply quantity range filter
        if (event.minQuantity != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.quantity >= event.minQuantity!)
              .toList();
        }
        if (event.maxQuantity != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.quantity <= event.maxQuantity!)
              .toList();
        }

        // Apply amount range filter
        if (event.minAmount != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.totalAmount >= event.minAmount!)
              .toList();
        }
        if (event.maxAmount != null) {
          filteredOutputs = filteredOutputs
              .where((output) => output.totalAmount <= event.maxAmount!)
              .toList();
        }

        emit(OutputLoaded(filteredOutputs));
      },
    );
  }

  Future<void> _onCreateOutput(
    CreateOutput event,
    Emitter<OutputState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.create(event.output);
    result.fold(
      (failure) {
        emit(OutputError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is OutputPaginatedLoaded) {
          add(LoadOutputsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is OutputLoaded) {
          add(LoadOutputs());
        }
      },
      (_) {
        emit(const OutputOperationSuccess('Output created successfully'));
        // Reload based on previous state
        if (previousState is OutputPaginatedLoaded) {
          add(LoadOutputsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(LoadOutputs());
        }
      },
    );
  }

  Future<void> _onUpdateOutput(
    UpdateOutput event,
    Emitter<OutputState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.update(event.output);
    result.fold(
      (failure) {
        emit(OutputError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is OutputPaginatedLoaded) {
          add(LoadOutputsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is OutputLoaded) {
          add(LoadOutputs());
        }
      },
      (_) {
        emit(const OutputOperationSuccess('Output updated successfully'));
        // Reload based on previous state
        if (previousState is OutputPaginatedLoaded) {
          add(LoadOutputsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(LoadOutputs());
        }
      },
    );
  }

  Future<void> _onDeleteOutput(
    DeleteOutput event,
    Emitter<OutputState> emit,
  ) async {
    // Save current state before operation
    final previousState = state;

    final result = await repository.delete(event.id);
    result.fold(
      (failure) {
        emit(OutputError(failure.message));
        // Reload based on previous state to recover from error
        if (previousState is OutputPaginatedLoaded) {
          add(LoadOutputsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else if (previousState is OutputLoaded) {
          add(LoadOutputs());
        }
      },
      (_) {
        emit(const OutputOperationSuccess('Output deleted successfully'));
        // Reload based on previous state
        if (previousState is OutputPaginatedLoaded) {
          add(LoadOutputsPaginated(
            page: previousState.currentPage,
            pageSize: previousState.pageSize,
          ));
        } else {
          add(LoadOutputs());
        }
      },
    );
  }

  Future<void> _onLoadSalesByDay(
    LoadSalesByDay event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getSalesByDay(event.date);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (report) => emit(ReportLoaded(report)),
    );
  }

  Future<void> _onLoadSalesByMonth(
    LoadSalesByMonth event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getSalesByMonth(event.year, event.month);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (report) => emit(ReportLoaded(report)),
    );
  }

  Future<void> _onLoadSalesByYear(
    LoadSalesByYear event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getSalesByYear(event.year);
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (report) => emit(ReportLoaded(report)),
    );
  }

  Future<void> _onLoadIPVReport(
    LoadIPVReport event,
    Emitter<OutputState> emit,
  ) async {
    emit(OutputLoading());
    final result = await repository.getIPVReport();
    result.fold(
      (failure) => emit(OutputError(failure.message)),
      (report) => emit(IPVReportLoaded(report)),
    );
  }
}
